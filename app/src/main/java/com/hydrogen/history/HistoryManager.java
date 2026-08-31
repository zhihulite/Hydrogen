package com.hydrogen.history;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;

import org.jspecify.annotations.NonNull;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.regex.Pattern;

@SuppressWarnings("unused")
public class HistoryManager {

    private static final int MAX_SIZE = 100;
    private static final int PREVIEW_MAX = 100;
    private static final long SAVE_DELAY = 500;
    private static final String PREFS_NAME = "history_prefs";
    private static final String KEY_ORDER = "history_order";
    private static final String ORDER_DELIMITER = "||";  // KEY_ORDER 的分隔符
    private static final String DATA_DELIMITER = "¦¦";  // 条目数据的分隔符
    // Lua 加载 services.cache.history 时 init 与其他模块同步 add 会触发
    // ConcurrentModificationException（init 内遍历同时 add 修改）。
    // CopyOnWrite 迭代快照、put 安全，免反复加锁（main-thread 密集使用）。
    private final List<HistoryItem> historyList = new CopyOnWriteArrayList<>();
    private final Map<String, HistoryItem> historyMap = new ConcurrentHashMap<>();
    private final Handler handler = new Handler(Looper.getMainLooper());
    private SharedPreferences sharedPreferences;
    private final Runnable saveRunnable = this::saveToPreferences;

    /** 规范类型（Lua/业务层）与本地存储中文的互转表 */
    private static final String[][] TYPE_CONFIG = {
            {"answer", "回答"},
            {"pin", "想法"},
            {"article", "文章"},
            {"question", "问题"},
            {"people", "用户"},
            {"zvideo", "视频"},
            {"roundtable", "圆桌"},
            {"special", "专题"},
            {"collection", "收藏"},
            {"column", "专栏"},
            {"podcast_channel", "播客频道"},
            {"podcast_episode", "播客单集"},
    };
    private static final Map<String, String> TYPE_TO_STORAGE = new HashMap<>();
    private static final Map<String, String> STORAGE_TO_TYPE = new HashMap<>();

    static {
        for (String[] pair : TYPE_CONFIG) {
            TYPE_TO_STORAGE.put(pair[0], pair[1]);
            STORAGE_TO_TYPE.put(pair[1], pair[0]);
        }
    }

    private HistoryManager() {
    }

    /** 惰性 holder：JVM 保证类初始化线程安全且恰好一次，不必每次调用都加锁。 */
    private static final class Holder {
        static final HistoryManager INSTANCE = new HistoryManager();
    }

    public static HistoryManager getInstance() {
        return Holder.INSTANCE;
    }

    public void init(Context ctx) {
        if (!historyList.isEmpty()) {
            return;
        }
        Context applicationContext = ctx.getApplicationContext();
        sharedPreferences = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        loadFromPreferences();
    }

    public void release() {
        handler.removeCallbacks(saveRunnable);
    }

    public void add(String id, String title, String preview, String type) {
        String storageType = toStorageType(type);
        if (storageType == null) {
            return;
        }
        String compositeKey = generateCompositeKey(storageType, id);
        HistoryItem existingItem = historyMap.get(compositeKey);

        if (existingItem != null) {
            existingItem.title = title;
            existingItem.preview = preview;
            historyList.remove(existingItem);
            historyList.add(0, existingItem);
        } else {
            HistoryItem newItem = new HistoryItem(id, title, preview, storageType);
            historyList.add(0, newItem);
            historyMap.put(compositeKey, newItem);

            if (historyList.size() > MAX_SIZE) {
                HistoryItem removed = historyList.remove(historyList.size() - 1);
                historyMap.remove(generateCompositeKey(removed.type, removed.id));
            }
        }
        scheduleSave();
    }

    public void remove(String id, String type) {
        String storageType = toStorageType(type);
        if (storageType == null) {
            return;
        }
        String compositeKey = generateCompositeKey(storageType, id);
        HistoryItem item = historyMap.get(compositeKey);

        if (item != null) {
            historyList.remove(item);
            historyMap.remove(compositeKey);
            scheduleSave();
        }
    }

    /**
     * 按时间倒序返回历史记录（新->旧），存储中文类型转为规范类型。
     * 不认识的类型（历史遗留数据）被过滤，预览截取 {@value PREVIEW_MAX} 字符。
     * 返回的是条目副本，存储列表中的原件（type 保持中文）不被改动。
     */
    public List<HistoryItem> getRecentFirst() {
        List<HistoryItem> result = new ArrayList<>(historyList.size());
        for (HistoryItem item : historyList) {
            String standardType = toStandardType(item.type);
            if (standardType == null) {
                continue;
            }
            result.add(new HistoryItem(item.id, item.title,
                    truncatePreview(item.preview), standardType));
        }
        return result;
    }

    /**
     * 按时间正序返回历史记录（旧->新），转换与过滤同 {@link #getRecentFirst()}。
     */
    public List<HistoryItem> getOldestFirst() {
        List<HistoryItem> result = getRecentFirst();
        Collections.reverse(result);
        return result;
    }

    public void clearAll() {
        historyList.clear();
        historyMap.clear();
        scheduleSave();
    }

    public int size() {
        return getRecentFirst().size();
    }

    /**
     * 标题或预览含关键词的记录（按时间倒序）。关键词为 null/空时返回全部。
     */
    public List<HistoryItem> search(String keyword) {
        if (keyword == null || keyword.isEmpty()) {
            return getRecentFirst();
        }
        List<HistoryItem> all = getRecentFirst();
        List<HistoryItem> result = new ArrayList<>();
        for (HistoryItem item : all) {
            String content = (item.title == null ? "" : item.title) + " "
                    + (item.preview == null ? "" : item.preview);
            if (content.contains(keyword)) {
                result.add(item);
            }
        }
        return result;
    }

    /**
     * 指定规范类型的记录（按时间倒序），未知类型返回空列表。
     */
    public List<HistoryItem> filterByType(String type) {
        List<HistoryItem> all = getRecentFirst();
        List<HistoryItem> result = new ArrayList<>();
        for (HistoryItem item : all) {
            if (type.equals(item.type)) {
                result.add(item);
            }
        }
        return result;
    }

    /**
     * 预览文本截取前 {@value PREVIEW_MAX} 字符（截断时补 "..."），null 返回空串。
     */
    public static String truncatePreview(String preview) {
        if (preview == null || preview.length() <= PREVIEW_MAX) {
            return preview == null ? "" : preview;
        }
        return preview.substring(0, PREVIEW_MAX) + "...";
    }

    /** 规范类型 -> 存储类型；未知类型返回 null。 */
    public static String toStorageType(String type) {
        return TYPE_TO_STORAGE.get(type);
    }

    /** 存储类型（中文）-> 规范类型；未知返回 null。 */
    public static String toStandardType(String storageType) {
        return STORAGE_TO_TYPE.get(storageType);
    }

    /** 类型是否在受支持的规范类型列表内。 */
    public static boolean isKnownType(String type) {
        return TYPE_TO_STORAGE.containsKey(type);
    }

    /** 服务器提交用的类型串（people 对应服务器的 profile）；未知类型返回 null。 */
    public static String toServerType(String type) {
        if (!TYPE_TO_STORAGE.containsKey(type)) {
            return null;
        }
        return "people".equals(type) ? "profile" : type;
    }

    private String generateCompositeKey(String type, String id) {
        return type + ":" + id;
    }

    private String generateStorageKey(String type, String id) {
        return type + DATA_DELIMITER + id;
    }

    private void loadFromPreferences() {
        String orderValue = sharedPreferences.getString(KEY_ORDER, "");
        if (orderValue.isEmpty()) return;

        String[] keys = orderValue.split(Pattern.quote(ORDER_DELIMITER));

        for (String key : keys) {
            if (key.isEmpty()) continue;

            String value = sharedPreferences.getString(key, null);
            if (value == null) continue;

            String[] valueParts = value.split(Pattern.quote(DATA_DELIMITER), 3);
            if (valueParts.length < 2) continue;

            String[] keyParts = key.split(Pattern.quote(DATA_DELIMITER), 2);
            if (keyParts.length < 2) continue;

            String type = keyParts[0];
            String id = keyParts[1];

            String title = valueParts[0];
            String preview = valueParts.length > 2 ?
                    valueParts[1] + DATA_DELIMITER + valueParts[2] : // 内容本身含分隔符时拼回
                    valueParts[1];

            HistoryItem item = new HistoryItem(id, title, preview, type);
            historyList.add(item);
            historyMap.put(generateCompositeKey(type, id), item);
        }
    }

    private void saveToPreferences() {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.clear();

        StringBuilder orderBuilder = new StringBuilder();

        for (HistoryItem item : historyList) {
            String storageKey = generateStorageKey(item.type, item.id);

            if (orderBuilder.length() > 0) {
                orderBuilder.append(ORDER_DELIMITER);
            }
            orderBuilder.append(storageKey);

            // title/preview 可为 null（Lua nil 过桥成 null），拼接前兜底为空串，
            // 避免字符串拼接把 null 写成字面 "null" 持久化。
            String title = item.title == null ? "" : item.title;
            String preview = item.preview == null ? "" : item.preview;
            String value = title + DATA_DELIMITER + preview;
            editor.putString(storageKey, value);
        }

        editor.putString(KEY_ORDER, orderBuilder.toString());
        editor.apply();
    }

    private void scheduleSave() {
        handler.removeCallbacks(saveRunnable);
        handler.postDelayed(saveRunnable, SAVE_DELAY);
    }

    @SuppressWarnings("unused")
    public static class HistoryItem {
        public String id;
        public String title;
        public String preview;
        public String type;

        public HistoryItem(String id, String title, String preview, String type) {
            this.id = id;
            // Lua nil 过桥成 null；title 统一归一化为空串，条目 id/type 仍有效，
            // getRecentFirst 等出口不再向 Lua 透传 null
            this.title = title == null ? "" : title;
            this.preview = preview;
            this.type = type;
        }

        @Override
        public @NonNull String toString() {
            return type + ": " + title + " [" + preview + "] (" + id + ")";
        }
    }
}
