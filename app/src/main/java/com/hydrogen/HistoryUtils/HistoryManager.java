package com.hydrogen.HistoryUtils;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

public class HistoryManager {

    private static HistoryManager instance;
    private static final int MAX_SIZE = 100;
    private static final long SAVE_DELAY = 500;
    private static final String PREFS_NAME = "history_prefs";
    private static final String KEY_ORDER = "history_order";
    
    private static final String ORDER_DELIMITER = "||";  // 用于KEY_ORDER的分隔符
    private static final String DATA_DELIMITER = "¦¦";  // 用于条目数据的分隔符

    // 核心数据结构
    private final List<HistoryItem> historyList = new ArrayList<>();
    private final Map<String, HistoryItem> historyMap = new HashMap<>();

    // 上下文相关
    private Context context;
    private SharedPreferences sharedPreferences;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Runnable saveRunnable = this::saveToPreferences;

    // ========== 单例模式 ==========
    private HistoryManager() {}

    public static synchronized HistoryManager getInstance() {
        if (instance == null) {
            instance = new HistoryManager();
        }
        return instance;
    }

    public void init(Context ctx) {
        if (!historyList.isEmpty()) {
            return;
        }
        this.context = ctx.getApplicationContext();
        sharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        loadFromPreferences();
    }

    public void release() {
        handler.removeCallbacks(saveRunnable);
    }

    // ========== 核心操作 ==========
    public void add(String id, String title, String preview, String type) {
        String compositeKey = generateCompositeKey(type, id);
        HistoryItem existingItem = historyMap.get(compositeKey);

        if (existingItem != null) {
            // 更新现有项
            existingItem.title = title;
            existingItem.preview = preview;
            
            // 移动到列表顶部
            historyList.remove(existingItem);
            historyList.add(0, existingItem);
        } else {
            // 创建新项
            HistoryItem newItem = new HistoryItem(id, title, preview, type);
            
            // 添加到数据结构
            historyList.add(0, newItem);
            historyMap.put(compositeKey, newItem);
            
            // 修剪大小
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

    // ========== 获取有序列表 ==========
    /**
     * 获取按时间倒序排列的历史记录（新->旧）
     */
    public List<HistoryItem> getRecentFirst() {
        return new ArrayList<>(historyList);
    }

    /**
     * 获取按时间正序排列的历史记录（旧->新）
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

    // ========== 辅助方法 ==========
    private String generateCompositeKey(String type, String id) {
        return type + ":" + id;
    }

    private String generateStorageKey(String type, String id) {
        return type + DATA_DELIMITER + id;
    }

    // ========== 持久化处理（保证有序） ==========
    private void loadFromPreferences() {
        // 1. 读取顺序记录
        String orderValue = sharedPreferences.getString(KEY_ORDER, "");
        if (orderValue.isEmpty()) return;
        
        // 使用新的ORDER_DELIMITER分割
        String[] keys = orderValue.split(Pattern.quote(ORDER_DELIMITER));
        
        // 2. 按顺序加载条目
        for (String key : keys) {
            if (key.isEmpty()) continue;
            
            String value = sharedPreferences.getString(key, null);
            if (value == null) continue;
            
            // 使用DATA_DELIMITER分割条目数据
            String[] valueParts = value.split(Pattern.quote(DATA_DELIMITER), 3);
            if (valueParts.length < 2) continue;
            
            // 解析键
            String[] keyParts = key.split(Pattern.quote(DATA_DELIMITER), 2);
            if (keyParts.length < 2) continue;
            
            String type = keyParts[0];
            String id = keyParts[1];
            
            // 创建历史项
            String title = valueParts[0];
            String preview = valueParts.length > 2 ? 
                valueParts[1] + DATA_DELIMITER + valueParts[2] : // 处理包含分隔符的情况
                valueParts[1];
                
            HistoryItem item = new HistoryItem(id, title, preview, type);
            
            // 添加到数据结构
            historyList.add(item);
            historyMap.put(generateCompositeKey(type, id), item);
        }
    }

    private void saveToPreferences() {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.clear();
        
        // 保存顺序记录和键值对
        StringBuilder orderBuilder = new StringBuilder();
        
        for (HistoryItem item : historyList) {
            String storageKey = generateStorageKey(item.type, item.id);
            
            // 添加到顺序列表
            if (orderBuilder.length() > 0) {
                orderBuilder.append(ORDER_DELIMITER); // 使用新的分隔符
            }
            orderBuilder.append(storageKey);
            
            // 保存条目数据
            String value = item.title + DATA_DELIMITER + item.preview;
            editor.putString(storageKey, value);
        }
        
        // 保存顺序记录
        editor.putString(KEY_ORDER, orderBuilder.toString());
        editor.apply();
    }

    private void scheduleSave() {
        handler.removeCallbacks(saveRunnable);
        handler.postDelayed(saveRunnable, SAVE_DELAY);
    }

    // ========== 历史项类 ==========
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
        public String toString() {
            return type + ": " + title + " [" + preview + "] (" + id + ")";
        }
    }
}