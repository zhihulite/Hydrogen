package com.hydrogen.HistoryUtils;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Pattern;

public class SearchHistoryManager {

    private static SearchHistoryManager instance;
    private static final int MAX_SIZE = 100;
    private static final long SAVE_DELAY = 500; // 延迟保存时间(ms)
    private static final String PREF_NAME = "search_history";
    private static final String KEY_ORDER = "history_order";
    private static final String ORDER_DELIMITER = "||"; // 用于KEY_ORDER的分隔符

    // 核心数据结构
    private final List<SearchHistoryItem> historyList = new ArrayList<>();
    private final Map<String, SearchHistoryItem> itemMap = new HashMap<>(); // ID->item 映射

    // 上下文相关
    private Context context;
    private SharedPreferences sharedPreferences;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable saveRunnable = this::saveToPreferences;

    // ========== 单例模式 ==========
    private SearchHistoryManager() {}

    public static synchronized SearchHistoryManager getInstance() {
        if (instance == null) {
            instance = new SearchHistoryManager();
        }
        return instance;
    }

    public void init(Context ctx) {
        if (context != null) return;
        
        this.context = ctx.getApplicationContext();
        sharedPreferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        
        if (historyList.isEmpty()) {
            loadFromPreferences();
        }
    }

    public void release() {
        handler.removeCallbacks(saveRunnable);
    }

    // ========== 核心操作 ==========
    public void add(String value) {
        if (value == null || value.trim().isEmpty()) return;

        // 检查是否已存在相同搜索值
        for (SearchHistoryItem item : historyList) {
            if (value.equals(item.value)) {
                // 移到最前
                historyList.remove(item);
                historyList.add(0, item);
                scheduleSave();
                return;
            }
        }

        // 创建新条目
        String newId = UUID.randomUUID().toString();
        SearchHistoryItem newItem = new SearchHistoryItem(newId, value);
        
        // 添加到数据结构
        historyList.add(0, newItem);
        itemMap.put(newId, newItem);
        
        // 修剪大小
        if (historyList.size() > MAX_SIZE) {
            SearchHistoryItem removed = historyList.remove(historyList.size() - 1);
            itemMap.remove(removed.id);
        }
        
        scheduleSave();
    }

    /**
     * 根据ID删除历史记录
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
     * 获取按时间倒序排列的历史记录（新->旧）
     */
    public List<SearchHistoryItem> getRecentFirst() {
        return new ArrayList<>(historyList);
    }

    /**
     * 获取按时间正序排列的历史记录（旧->新）
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

    // ========== 持久化处理 ==========
    private void loadFromPreferences() {
        // 1. 加载顺序列表
        String orderString = sharedPreferences.getString(KEY_ORDER, "");
        if (orderString.isEmpty()) return;
        
        // 使用 ORDER_DELIMITER 分割
        String[] itemIds = orderString.split(Pattern.quote(ORDER_DELIMITER));
        
        // 2. 按顺序加载条目
        for (String id : itemIds) {
            if (id.isEmpty()) continue;
            
            // 获取条目数据
            String value = sharedPreferences.getString(id, null);
            if (value == null) continue;
            
            // 创建历史项
            SearchHistoryItem item = new SearchHistoryItem(id, value);
            
            // 添加到数据结构
            historyList.add(item);
            itemMap.put(id, item);
        }
    }

    private void saveToPreferences() {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.clear(); // 清除旧数据
        
        // 1. 保存顺序列表
        StringBuilder orderBuilder = new StringBuilder();
        for (SearchHistoryItem item : historyList) {
            if (orderBuilder.length() > 0) {
                // 使用 ORDER_DELIMITER 连接
                orderBuilder.append(ORDER_DELIMITER);
            }
            orderBuilder.append(item.id);
            
            // 2. 保存条目数据
            editor.putString(item.id, item.value);
        }
        editor.putString(KEY_ORDER, orderBuilder.toString());
        
        editor.apply();
    }

    private void scheduleSave() {
        handler.removeCallbacks(saveRunnable);
        handler.postDelayed(saveRunnable, SAVE_DELAY);
    }

    // ========== 历史项类 ==========
    public static class SearchHistoryItem {
        public final String id;
        public final String value;

        public SearchHistoryItem(String id, String value) {
            this.id = id;
            this.value = value;
        }
        
        @Override
        public String toString() {
            return value;
        }
    }
}