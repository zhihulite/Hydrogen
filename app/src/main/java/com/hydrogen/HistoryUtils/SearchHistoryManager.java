package com.hydrogen.HistoryUtils;

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
import java.util.UUID;
import java.util.regex.Pattern;

@SuppressWarnings("unused")
public class SearchHistoryManager {

    private static final int MAX_SIZE = 100;
    private static final long SAVE_DELAY = 500; // 延迟保存时间(ms)
    private static final String PREF_NAME = "search_history";
    private static final String KEY_ORDER = "history_order";
    private static final String ORDER_DELIMITER = "||"; // KEY_ORDER 的分隔符
    private final List<SearchHistoryItem> historyList = new ArrayList<>();
    private final Map<String, SearchHistoryItem> itemMap = new HashMap<>(); // ID->item 映射
    private final Handler handler = new Handler(Looper.getMainLooper());
    private SharedPreferences sharedPreferences;
    private final Runnable saveRunnable = this::saveToPreferences;

    private SearchHistoryManager() {
    }

    /** 惰性 holder：JVM 保证类初始化线程安全且恰好一次，不必每次调用都加锁。 */
    private static final class Holder {
        static final SearchHistoryManager INSTANCE = new SearchHistoryManager();
    }

    public static SearchHistoryManager getInstance() {
        return Holder.INSTANCE;
    }

    public void init(Context ctx) {
        Context applicationContext = ctx.getApplicationContext();
        sharedPreferences = applicationContext.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);

        if (historyList.isEmpty()) {
            loadFromPreferences();
        }
    }

    public void release() {
        handler.removeCallbacks(saveRunnable);
    }

    public void add(String value) {
        if (value == null || value.trim().isEmpty()) return;

        for (SearchHistoryItem item : historyList) {
            if (value.equals(item.value)) {
                historyList.remove(item);
                historyList.add(0, item);
                scheduleSave();
                return;
            }
        }

        String newId = UUID.randomUUID().toString();
        SearchHistoryItem newItem = new SearchHistoryItem(newId, value);
        historyList.add(0, newItem);
        itemMap.put(newId, newItem);

        if (historyList.size() > MAX_SIZE) {
            SearchHistoryItem removed = historyList.remove(historyList.size() - 1);
            itemMap.remove(removed.id);
        }

        scheduleSave();
    }

    /**
     * 按 ID 删除历史记录
     */
    public void remove(String id) {
        if (id == null) return;

        SearchHistoryItem item = itemMap.get(id);
        if (item != null) {
            historyList.remove(item);
            itemMap.remove(id);
            scheduleSave();
        }
    }

    /**
     * 按时间倒序返回历史记录（新->旧）
     */
    public List<SearchHistoryItem> getRecentFirst() {
        return new ArrayList<>(historyList);
    }

    /**
     * 按时间正序返回历史记录（旧->新）
     */
    public List<SearchHistoryItem> getOldestFirst() {
        List<SearchHistoryItem> reversed = new ArrayList<>(historyList);
        Collections.reverse(reversed);
        return reversed;
    }

    public void clearAll() {
        historyList.clear();
        itemMap.clear();
        scheduleSave();
    }

    private void loadFromPreferences() {
        String orderString = sharedPreferences.getString(KEY_ORDER, "");
        if (orderString.isEmpty()) return;

        String[] itemIds = orderString.split(Pattern.quote(ORDER_DELIMITER));

        for (String id : itemIds) {
            if (id.isEmpty()) continue;

            String value = sharedPreferences.getString(id, null);
            if (value == null) continue;

            SearchHistoryItem item = new SearchHistoryItem(id, value);
            historyList.add(item);
            itemMap.put(id, item);
        }
    }

    private void saveToPreferences() {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.clear();

        StringBuilder orderBuilder = new StringBuilder();
        for (SearchHistoryItem item : historyList) {
            if (orderBuilder.length() > 0) {
                orderBuilder.append(ORDER_DELIMITER);
            }
            orderBuilder.append(item.id);

            editor.putString(item.id, item.value);
        }
        editor.putString(KEY_ORDER, orderBuilder.toString());

        editor.apply();
    }

    private void scheduleSave() {
        handler.removeCallbacks(saveRunnable);
        handler.postDelayed(saveRunnable, SAVE_DELAY);
    }

    public record SearchHistoryItem(String id, String value) {

        @Override
        public @NonNull String toString() {
            return value;
        }
    }
}
