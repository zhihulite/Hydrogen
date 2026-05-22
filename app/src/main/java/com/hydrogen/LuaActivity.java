package com.hydrogen;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.core.splashscreen.SplashScreen;

import java.io.File;
import java.lang.ref.WeakReference;

public class LuaActivity extends com.androlua.LuaActivity {

    private static final String TAG = "LuaActivity";
    private static final String PREF_NAME = "appInfo";
    private static final String KEY_LAST_UPDATE_TIME = "lastUpdateTime";
    private static final String KEY_CHECK_UPDATE = "checkUpdate";
    private static final String KEY_UPDATING = "updating";
    private static final float DEFAULT_FONT_SIZE = 20.0f;

    public boolean updating = false;
    private boolean checkUpdate = false;
    private String luaPath = null;
    public String luaDir = null;
    private WeakReference<Context> originalContextRef = null;

    // 获取原始 Context
    @SuppressWarnings("unused")
    public Context getOriginalContext() {
        return originalContextRef != null ? originalContextRef.get() : null;
    }

    @Override
    protected void attachBaseContext(Context base) {
        originalContextRef = new WeakReference<>(base);
        super.attachBaseContext(applyFontScale(base));
    }

    // 应用字体缩放比例
    private Context applyFontScale(Context base) {
        Object fontSizeObj = getSharedData("font_size");
        String fontSizeStr = (fontSizeObj instanceof String) ? (String) fontSizeObj : String.valueOf(DEFAULT_FONT_SIZE);

        try {
            float fontScale = Float.parseFloat(fontSizeStr) / DEFAULT_FONT_SIZE;
            Configuration config = new Configuration(base.getResources().getConfiguration());
            config.fontScale = fontScale;
            return base.createConfigurationContext(config);
        } catch (NumberFormatException e) {
            Log.w(TAG, "Invalid font size format: " + fontSizeStr, e);
            return base;
        }
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);

        if (savedInstanceState == null) {
            handleFirstCreate();
        } else {
            restoreState(savedInstanceState);
        }
    }

    // 处理首次创建，检查是否需要更新
    private void handleFirstCreate() {
        if (!checkUpdate) {
            checkUpdate = getIntent().getBooleanExtra(KEY_CHECK_UPDATE, false);
        }

        if (checkUpdate) {
            performUpdateCheck();
        }
    }

    // 执行更新检查，比较应用版本判断是否需要更新
    private void performUpdateCheck() {
        long lastTime = getAppLastUpdateTime();
        if (lastTime == -1) {
            Log.e(TAG, "Failed to get package info, skipping update check");
            return;
        }

        SharedPreferences info = getSharedPreferences(PREF_NAME, MODE_PRIVATE);
        long oldLastTime = info.getLong(KEY_LAST_UPDATE_TIME, 0);
        updating = (oldLastTime != lastTime);

        if (updating) {
            setDebug(false);
            navigateToWelcome();
        }
    }

    // 获取应用的最后更新时间
    private long getAppLastUpdateTime() {
        try {
            PackageInfo packageInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
            return packageInfo.lastUpdateTime;
        } catch (PackageManager.NameNotFoundException e) {
            Log.e(TAG, "Package name not found", e);
            return -1;
        }
    }

    // 跳转到欢迎页面进行更新
    private void navigateToWelcome() {
        Intent intent = new Intent(this, Welcome.class);
        intent.putExtra("newIntent", getIntent());
        intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(intent);
        finish();
    }

    // 恢复保存的状态
    private void restoreState(Bundle savedInstanceState) {
        checkUpdate = savedInstanceState.getBoolean(KEY_CHECK_UPDATE, false);
        updating = savedInstanceState.getBoolean(KEY_UPDATING, false);
        onRestoreInstanceState(savedInstanceState);
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        runFunc("onNewIntent", intent);
        super.onNewIntent(intent);
    }

    // 设置是否检查更新
    public void setCheckUpdate(boolean state) {
        checkUpdate = state;
    }

    // 获取 Lua 脚本路径，首次调用时初始化
    // 优先取 Intent 传入的 luaPath，没有则用默认路径 getLocalDir() + "/main.lua"
    // 然后从父目录开始向上查找同时包含 main.lua 和 init.lua 的目录作为 luaDir，找不到就用父目录
    // 返回路径不受 setLuaDir 影响
    @Override
    public String getLuaPath() {
        if (updating) return "/";

        if (luaPath == null) {
            // 优先取 Intent 传入的路径，没有则用默认路径
            String intentPath = getIntent().getStringExtra("luaPath");
            luaPath = intentPath != null ? intentPath : getLocalDir() + "/main.lua";

            // 记录原始父目录
            String parentDir = new File(luaPath).getParent();
            luaDir = parentDir;

            // 向上找包含 main.lua 和 init.lua 的目录
            while (luaDir != null) {
                if (new File(luaDir, "main.lua").exists() && new File(luaDir, "init.lua").exists()) {
                    break;
                }
                luaDir = new File(luaDir).getParent();
            }
            // 找不到就用原始父目录
            if (luaDir == null) luaDir = parentDir;

            setLuaDir(luaDir);
        }

        return luaPath;
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putBoolean(KEY_CHECK_UPDATE, checkUpdate);
        outState.putBoolean(KEY_UPDATING, updating);
        Log.i(TAG, "save " + outState);
        runFunc("onSaveInstanceState", outState);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        originalContextRef = null;
    }

    @Override
    public void onRestoreInstanceState(@NonNull Bundle savedInstanceState) {
        try {
            super.onRestoreInstanceState(savedInstanceState);
            Log.i(TAG, "restore " + savedInstanceState);
        } catch (Exception e) {
            sendError("onRestoreInstanceState", e);
        }
        runFunc("onRestoreInstanceState", savedInstanceState);
    }

    // 构建跳转 Intent
    public Intent buildNewActivityIntent(int req, String path, Object[] arg, boolean newDocument, int documentId) {
        Intent intent = new Intent(this, LuaActivity.class);

        String resolvedPath = resolveLuaPath(path);
        intent.putExtra("luaPath", resolvedPath);
        intent.setData(Uri.parse("file://" + resolvedPath + "?documentId=" + documentId));
        intent.putExtra("name", resolvedPath);

        if (arg != null) {
            intent.putExtra("arg", arg);
        }
        if (newDocument) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_DOCUMENT);
        }
        return intent;
    }

    // 解析 Lua 文件路径，处理相对路径、目录自动补全 main.lua、后缀自动补全 .lua
    private String resolveLuaPath(String path) {
        if (path == null || path.isEmpty()) {
            return "/";
        }

        // 相对路径转绝对路径
        if (path.charAt(0) != '/') {
            path = getLuaDir() + "/" + path;
        }

        File file = new File(path);
        // 如果是目录且包含 main.lua，自动补全
        if (file.isDirectory() && new File(path + "/main.lua").exists()) {
            path += "/main.lua";
        }
        // 如果不是目录且没有 .lua 后缀，自动补全
        else if (!file.isDirectory() && !path.endsWith(".lua")) {
            path += ".lua";
        }

        return path;
    }

    @SuppressWarnings("unused")
    public void newActivity(String path, boolean newDocument, int documentId) {
        newActivity(1, path, null, newDocument, documentId);
    }

    @SuppressWarnings("unused")
    public void newActivity(String path, Object[] arg, boolean newDocument, int documentId) {
        newActivity(1, path, arg, newDocument, documentId);
    }

    @Override
    public void newActivity(int req, String path, Object[] arg, boolean newDocument) {
        newActivity(req, path, arg, newDocument, 0);
    }

    // 启动新 Activity
    public void newActivity(int req, String path, Object[] arg, boolean newDocument, int documentId) {
        Intent intent = buildNewActivityIntent(req, path, arg, newDocument, documentId);
        if (newDocument) {
            startActivity(intent);
        } else {
            startActivityForResult(intent, req);
        }
    }

    @Override
    public void newActivity(int req, String path, int in, int out, Object[] arg, boolean newDocument) {
        newActivity(req, path, in, out, arg, newDocument, 0);
    }

    // 启动新 Activity 并指定转场动画
    public void newActivity(int req, String path, int in, int out, Object[] arg, boolean newDocument, int documentId) {
        newActivity(req, path, arg, newDocument, documentId);
        overridePendingTransition(in, out);
    }
}