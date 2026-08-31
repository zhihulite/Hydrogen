package com.hydrogen.HistoryUtils;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;

import org.jspecify.annotations.NonNull;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.regex.Pattern;

@SuppressWarnings("unused")
public class HistoryManager {

    private static final int MAX_SIZE = 100;
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
        String compositeKey = generateCompositeKey(type, id);
        HistoryItem existingItem = historyMap.get(compositeKey);

        if (existingItem != null) {
            existingItem.title = title;
            existingItem.preview = preview;
            historyList.remove(existingItem);
            historyList.add(0, existingItem);
        } else {
            HistoryItem newItem = new HistoryItem(id, title, preview, type);
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
        String compositeKey = generateCompositeKey(type, id);
        HistoryItem item = historyMap.get(compositeKey);

        if (item != null) {
            historyList.remove(item);
            historyMap.remove(compositeKey);
            scheduleSave();
        }
    }

    /**
     * 按时间倒序返回历史记录（新->旧）
     */
    public List<HistoryItem> getRecentFirst() {
        return new ArrayList<>(historyList);
    }

    /**
     * 按时间正序返回历史记录（旧->新）
     */
    public List<HistoryItem> getOldestFirst() {
        List<HistoryItem> reversed = new ArrayList<>(historyList);
        Collections.reverse(reversed);
        return reversed;
    }

    public void clearAll() {
        historyList.clear();
        historyMap.clear();
        scheduleSave();
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

            String value = item.title + DATA_DELIMITER + item.preview;
            editor.putString(storageKey, value);
        }

        editor.putString(KEY_ORDER, orderBuilder.toString());
        editor.apply();
    }

    private void scheduleSave() {
        handler.removeCallbacks(saveRunnable);
        handler.postDelayed(saveRunnable, SAVE_DELAY);
    }

    public static class HistoryItem {
        public String id;
        public String title;
        public String preview;
        public String type;

        public HistoryItem(String id, String title, String preview, String type) {
            this.id = id;
            this.title = title;
            this.preview = preview;
            this.type = type;
        }

        @Override
        public @NonNull String toString() {
            return type + ": " + title + " [" + preview + "] (" + id + ")";
        }
    }
}
