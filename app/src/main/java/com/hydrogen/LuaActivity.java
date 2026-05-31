package com.hydrogen;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.core.app.ActivityOptionsCompat;
import androidx.core.splashscreen.SplashScreen;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

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
    public String luaPath = null;
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

        if (savedInstanceState == null) {
            handleFirstCreate();
        } else {
            restoreState(savedInstanceState);
        }

        super.onCreate(savedInstanceState);
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
            // 更新期间关闭 Debug 模式，避免父类加载 Lua 失败时弹出 Toast
            // 因为 getLuaPath() 返回 "/" 会导致父类 doFile() 报错并弹 Toast
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
    }

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        setIntent(intent);
        safeRunFunc("onNewIntent", intent);
        super.onNewIntent(intent);
    }

    // 设置是否检查更新
    public void setCheckUpdate(boolean state) {
        checkUpdate = state;
    }

    // 获取 Lua 脚本路径，首次调用时初始化，final 禁止子类重写
    @Override
    public final String getLuaPath() {
        if (luaPath != null) {
            return luaPath;
        }
        if (updating) {
            luaPath = "/";
        } else {
            luaPath = getIntent().getStringExtra("luaPath");
            Log.d(TAG, "getLuaPath: luaPath from Intent = " + luaPath);
        }

        // 只有 luaPath 非空时才初始化目录
        if (luaPath != null) {
            initLuaDir(luaPath);
        } else {
            // luaPath 为空，调用子类可重写的 fallback 方法
            String fallbackPath = getFallbackLuaPath();
            Log.d(TAG, "getLuaPath: using fallbackPath = " + fallbackPath);
            if (fallbackPath != null) {
                luaPath = fallbackPath;
                initLuaDir(luaPath);
            } else {
                showMissingLuaPathDialog();
            }
        }

        return luaPath;
    }

    // 子类可重写此方法，提供备用路径
    protected String getFallbackLuaPath() {
        return null;  // 默认无备用路径
    }

    // 显示路径缺失错误弹窗
    private void showMissingLuaPathDialog() {
        new MaterialAlertDialogBuilder(this)
                .setTitle("错误")
                .setMessage("无法获取 Lua 脚本路径，请确保 Intent 中包含 luaPath 参数")
                .setCancelable(false)
                .setPositiveButton("退出", (dialog, which) -> finish())
                .show();
    }

    private boolean hasAttemptedInit = false;

    // 根据传入的 luaPath 初始化 luaDir
    // 从父目录开始向上查找同时包含 main.lua 和 init.lua 的目录，找不到就用父目录
    // 最后调用 setLuaDir()
    private void initLuaDir(String luaPath) {
        if (luaDir != null || hasAttemptedInit) {
            showDuplicateCallDialog();
            return;
        }

        hasAttemptedInit = true;

        if (luaPath == null || luaPath.isEmpty()) {
            showMissingLuaPathDialog();
            return;
        }

        String parentDir = new File(luaPath).getParent();
        if (parentDir == null) {
            showMissingLuaPathDialog();
            return;
        }

        String foundDir = parentDir;
        while (foundDir != null) {
            File dirFile = new File(foundDir);
            // 检查目录是否可访问
            if (dirFile.exists() && dirFile.canRead() && dirFile.isDirectory()) {
                if (new File(foundDir, "main.lua").exists() && new File(foundDir, "init.lua").exists()) {
                    break;
                }
            }
            foundDir = new File(foundDir).getParent();
        }
        if (foundDir == null) foundDir = parentDir;

        setLuaDir(foundDir);
        luaDir = foundDir;
    }

    // 显示重复调用错误弹窗
    private void showDuplicateCallDialog() {
        new MaterialAlertDialogBuilder(this)
                .setTitle("代码错误")
                .setMessage("initLuaDir 被重复调用")
                .setPositiveButton("确定", null)
                .show();
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putBoolean(KEY_CHECK_UPDATE, checkUpdate);
        outState.putBoolean(KEY_UPDATING, updating);
        Log.i(TAG, "save " + outState);
        safeRunFunc("onSaveInstanceState", outState);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        originalContextRef = null;
    }

    @Override
    public void onRestoreInstanceState(@NonNull Bundle savedInstanceState) {
        safeRunFunc("onRestoreInstanceState", savedInstanceState);
        super.onRestoreInstanceState(savedInstanceState);
    }

    // 安全执行 Lua 函数，自动捕获异常
    protected void safeRunFunc(String funcName, Object... args) {
        try {
            runFunc(funcName, args);
        } catch (Exception e) {
            Log.e(TAG, "safeRunFunc error in " + funcName + ": " + e.getMessage(), e);
            sendError(funcName, e);
        }
    }

    // 构建基础 Intent，自动设置 Flags
    private Intent buildIntent(boolean isReplace, String path, Object[] arg) {
        Class<?> targetClass = isReplace ? this.getClass() : LuaActivity.class;
        Intent intent = new Intent(this, targetClass);
        String resolvedPath = resolveLuaPath(path);
        intent.putExtra("luaPath", resolvedPath);
        intent.putExtra("name", resolvedPath);
        if (arg != null) {
            intent.putExtra("arg", arg);
        }

        if (isReplace) {
            // 替换当前：强制创建全新实例，清空任务栈
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK);
        } else {
            // 启动多实例：新文档任务
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_DOCUMENT);
            intent.addFlags(Intent.FLAG_ACTIVITY_MULTIPLE_TASK);
        }

        return intent;
    }

    // 解析 Lua 文件路径
    // 处理相对路径、目录自动补全 main.lua、后缀自动补全 .lua
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

    // 新 API（禁止重写）

    // 启动多实例页面（新文档任务），默认无动画
    @SuppressWarnings("unused")
    public final void startDocumentActivity(String path, Object[] arg) {
        Intent intent = buildIntent(false, path, arg);
        intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(intent);
    }

    // 启动多实例页面（新文档任务），带动画
    @SuppressWarnings("unused")
    public final void startDocumentActivityWithAnim(String path, Object[] arg) {
        Intent intent = buildIntent(false, path, arg);
        startActivity(intent);
    }

    // 启动多实例页面（新文档任务），带共享元素
    @SuppressWarnings("unused")
    public final void startDocumentActivityWithShared(String path, Object[] arg, android.view.View sharedElement, String transitionName) {
        Intent intent = buildIntent(false, path, arg);
        ActivityOptionsCompat options = ActivityOptionsCompat.makeSceneTransitionAnimation(this, sharedElement, transitionName);
        startActivity(intent, options.toBundle());
    }

    // 替换当前页面（单例模式），强制创建全新实例，默认无动画
    @SuppressWarnings("unused")
    public final void replaceActivity(String path, Object[] arg) {
        Intent intent = buildIntent(true, path, arg);
        intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(intent);
        finish();
    }

    // 替换当前页面（单例模式），强制创建全新实例，带动画
    @SuppressWarnings("unused")
    public final void replaceActivityWithAnim(String path, Object[] arg) {
        Intent intent = buildIntent(true, path, arg);
        startActivity(intent);
        finish();
    }

    // 替换当前页面（单例模式），强制创建全新实例，带共享元素
    @SuppressWarnings("unused")
    public final void replaceActivityWithShared(String path, Object[] arg, android.view.View sharedElement, String transitionName) {
        Intent intent = buildIntent(true, path, arg);
        ActivityOptionsCompat options = ActivityOptionsCompat.makeSceneTransitionAnimation(this, sharedElement, transitionName);
        startActivity(intent, options.toBundle());
        finish();
    }

    // 旧 API（已废弃）

    @Deprecated
    @Override
    public void newActivity(int req, String path, Object[] arg, boolean newDocument) {
        showDeprecatedMessage(newDocument);
    }

    @Deprecated
    @Override
    public void newActivity(int req, String path, int in, int out, Object[] arg, boolean newDocument) {
        showDeprecatedMessage(newDocument);
    }

    private void showDeprecatedMessage(boolean newDocument) {
        String method = newDocument ? "startDocumentActivity" : "replaceActivity";
        String msg = "newActivity 已废弃，请使用 " + method + "(path, arg)、" + method + "WithAnim(path, arg) 或 " + method + "WithShared(path, arg, view, transitionName)";
        Log.e(TAG, msg);
        new MaterialAlertDialogBuilder(this)
                .setTitle("API 已废弃")
                .setMessage(msg)
                .setPositiveButton("确定", null)
                .setCancelable(false)
                .show();
        throw new UnsupportedOperationException(msg);
    }
}