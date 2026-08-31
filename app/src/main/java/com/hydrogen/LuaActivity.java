package com.hydrogen;

import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.os.Bundle;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityOptionsCompat;
import androidx.core.splashscreen.SplashScreen;

import org.luajvm.android.LuaApplication;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import java.io.File;
import java.lang.ref.WeakReference;

public class LuaActivity extends org.luajvm.android.host.LuaActivity {

    private static final String TAG = "LuaActivity";
    private static final float DEFAULT_FONT_SIZE = 20.0f;

    public String luaPath = null;
    public String luaDir = null;
    private WeakReference<Context> originalContextRef = null;
    private boolean hasAttemptedInit = false;

    @SuppressWarnings("unused")
    public Context getOriginalContext() {
        return originalContextRef != null ? originalContextRef.get() : null;
    }

    @Override
    protected void attachBaseContext(Context base) {
        originalContextRef = new WeakReference<>(base);
        super.attachBaseContext(applyFontScale(base));
    }

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
    }

    // 取 Lua 脚本路径，首次调用时初始化；final 禁止子类重写
    @Override
    public final String getLuaPath() {
        if (luaPath != null) {
            return luaPath;
        }

        luaPath = getIntent().getStringExtra("luaPath");
        Log.d(TAG, "getLuaPath: luaPath from Intent = " + luaPath);

        if (luaPath != null) {
            initLuaDir(luaPath);
        } else {
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

    protected String getFallbackLuaPath() {
        LuaApplication app = (LuaApplication) getApplication();
        return app.getLocalDir() + "/main.lua";
    }

    private void showMissingLuaPathDialog() {
        new MaterialAlertDialogBuilder(this)
                .setTitle("错误")
                .setMessage("无法获取 Lua 脚本路径，请确保 Intent 中包含 luaPath 参数")
                .setCancelable(false)
                .setPositiveButton("退出", (dialog, which) -> finish())
                .show();
    }

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
            if (dirFile.exists() && dirFile.canRead() && dirFile.isDirectory()) {
                // 只打字节码的包里这两个入口是 .luac，判据须两种都认
                if (entryExists(foundDir, "main.lua") && entryExists(foundDir, "init.lua")) {
                    break;
                }
            }
            foundDir = new File(foundDir).getParent();
        }
        if (foundDir == null) foundDir = parentDir;

        luaDir = foundDir;
    }

    /** 入口脚本是否就位：`.lua` 或同名 `.luac` 任一存在即算（只打字节码的包没有 .lua）。 */
    private static boolean entryExists(String dir, String name) {
        if (new File(dir, name).isFile()) return true;
        return name.endsWith(".lua")
                && new File(dir, name.substring(0, name.length() - 4) + ".luac").isFile();
    }

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
        runFunc("onRestoreInstanceState", savedInstanceState);
        super.onRestoreInstanceState(savedInstanceState);
    }

    @Override
    public Object runFunc(String name, Object... args) {
        try {
            return super.runFunc(name, args);
        } catch (Exception e) {
            Log.e(TAG, "runFunc error in " + name + ": " + e.getMessage(), e);
            sendError(name, e);
        }
        return null;
    }

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
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK);
        } else {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_DOCUMENT);
            intent.addFlags(Intent.FLAG_ACTIVITY_MULTIPLE_TASK);
        }

        return intent;
    }

    private String resolveLuaPath(String path) {
        if (path == null || path.isEmpty()) {
            return "/";
        }

        if (path.charAt(0) != '/') {
            path = getLuaDir() + "/" + path;
        }

        File file = new File(path);
        if (file.isDirectory() && new File(path + "/main.lua").exists()) {
            path += "/main.lua";
        } else if (file.isDirectory() && new File(path + "/main.luac").exists()) {
            // 仅发字节码的包（APK 里剥掉 .lua 省体积）：目录入口回落 main.luac
            path += "/main.luac";
        } else if (!file.isDirectory() && !path.endsWith(".lua") && !path.endsWith(".luac")) {
            // 补全扩展名时优先 .lua  -  源码存在时 loadFile 的兄弟文件探测会自动改读
            //   同名 .luac（既拿字节码速度，chunkname 又保持 @xxx.lua 使 traceback
            //   与走源码逐字一致）；仅当源码确实不存在才落到 .luac。
            if (!new File(path + ".lua").exists() && new File(path + ".luac").exists()) {
                path += ".luac";
            } else {
                path += ".lua";
            }
        }

        return path;
    }

    @SuppressWarnings("unused")
    public final void startDocumentActivity(String path, Object[] arg) {
        Intent intent = buildIntent(false, path, arg);
        intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(intent);
    }

    @SuppressWarnings("unused")
    public final void startDocumentActivityWithAnim(String path, Object[] arg) {
        Intent intent = buildIntent(false, path, arg);
        startActivity(intent);
    }

    @SuppressWarnings("unused")
    public final void startDocumentActivityWithShared(String path, Object[] arg, View sharedElement, String transitionName) {
        Intent intent = buildIntent(false, path, arg);
        ActivityOptionsCompat options = ActivityOptionsCompat.makeSceneTransitionAnimation(this, sharedElement, transitionName);
        startActivity(intent, options.toBundle());
    }

    @SuppressWarnings("unused")
    public final void replaceActivity(String path, Object[] arg) {
        Intent intent = buildIntent(true, path, arg);
        intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(intent);
        finish();
    }

    @SuppressWarnings("unused")
    public final void replaceActivityWithAnim(String path, Object[] arg) {
        Intent intent = buildIntent(true, path, arg);
        startActivity(intent);
        finish();
    }

    @SuppressWarnings("unused")
    public final void replaceActivityWithShared(String path, Object[] arg, View sharedElement, String transitionName) {
        Intent intent = buildIntent(true, path, arg);
        ActivityOptionsCompat options = ActivityOptionsCompat.makeSceneTransitionAnimation(this, sharedElement, transitionName);
        startActivity(intent, options.toBundle());
        finish();
    }

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
