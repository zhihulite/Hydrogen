package com.hydrogen;

import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;

import androidx.activity.EdgeToEdge;
import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.splashscreen.SplashScreen;

import com.androlua.LuaApplication;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;
import com.zhihu.hydrogen.x.R;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class Welcome extends AppCompatActivity {

    private static final String TAG = "Welcome";
    private static final String PREF_NAME = "appInfo";
    private static final String KEY_LAST_UPDATE_TIME = "lastUpdateTime";
    private static final String KEY_VERSION_NAME = "versionName";

    private String luaMdDir;
    private String localDir;
    private long lastTime;
    private String versionName;
    private SharedPreferences info;
    private String oldVersionName;
    private boolean isActivityStarted = false;
    private OnBackPressedCallback backCallback;
    private ExecutorService executorService;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        EdgeToEdge.enable(this);
        SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);

        setupBackPressedCallback();
        initAppInfo();

        if (needUpdate()) {
            startUpdate();
        } else {
            jumpToMain();
        }
    }

    // 拦截返回键
    private void setupBackPressedCallback() {
        backCallback = new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                Log.d(TAG, "返回键被拦截");
            }
        };
        getOnBackPressedDispatcher().addCallback(this, backCallback);
    }

    // 初始化应用信息
    private void initAppInfo() {
        try {
            PackageInfo packageInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
            lastTime = packageInfo.lastUpdateTime;
            versionName = packageInfo.versionName;
            info = getSharedPreferences(PREF_NAME, MODE_PRIVATE);
            oldVersionName = info.getString(KEY_VERSION_NAME, "");
        } catch (PackageManager.NameNotFoundException e) {
            Log.e(TAG, "未找到包信息", e);
            showErrorAndExit("初始化失败", "无法获取应用信息");
        } catch (Exception e) {
            Log.e(TAG, "初始化失败", e);
            showErrorAndExit("初始化失败", e.getMessage());
        }
    }

    // 判断是否需要更新
    private boolean needUpdate() {
        long oldLastTime = info.getLong(KEY_LAST_UPDATE_TIME, 0);
        return oldLastTime != lastTime;
    }

    // 开始更新
    private void startUpdate() {
        LuaApplication app = (LuaApplication) getApplication();
        luaMdDir = app.getMdDir();
        localDir = app.getLocalDir();
        setContentView(R.layout.layout_welcome);

        executorService = Executors.newSingleThreadExecutor();
        executorService.execute(new UpdateRunnable());
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (backCallback != null) {
            backCallback.remove();
        }
        if (executorService != null && !executorService.isShutdown()) {
            executorService.shutdownNow();
        }
    }

    // 跳转到主页面
    private void jumpToMain() {
        if (isActivityStarted) return;
        isActivityStarted = true;

        Intent intent = buildIntent();
        intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(intent);
        finish();
    }

    // 构建 Intent
    private Intent buildIntent() {
        Intent mIntent = getIntent();
        if (mIntent != null) {
            Bundle mBundle = mIntent.getExtras();
            if (mBundle != null) {
                Intent intent = mBundle.getParcelable("newIntent");
                if (intent != null) {
                    intent.putExtra("isVersionChanged", true);
                    intent.putExtra("newVersionName", versionName);
                    intent.putExtra("oldVersionName", oldVersionName);
                    return intent;
                }
            }
        }
        Intent intent = new Intent(Welcome.this, MainActivity.class);
        intent.putExtra("isVersionChanged", true);
        intent.putExtra("newVersionName", versionName);
        intent.putExtra("oldVersionName", oldVersionName);
        return intent;
    }

    // 显示错误对话框并退出
    private void showErrorAndExit(String title, String message) {
        runOnUiThread(() -> new MaterialAlertDialogBuilder(this)
                .setTitle(title)
                .setMessage(message)
                .setPositiveButton("确定", (dialog, which) -> finish())
                .setCancelable(false)
                .show());
    }

    // 递归删除文件或目录（成功返回 true，失败返回 false）
    @SuppressWarnings("BooleanMethodIsAlwaysInverted")
    private boolean deleteRecursive(File file) {
        if (file == null) return true;
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    if (!deleteRecursive(child)) return false;
                }
            }
        }
        return file.delete();
    }

    // 从 APK 中解压指定目录
    private void unzipFromApk(String sourceDir, File destDir) {
        // 删除旧目录
        if (destDir.exists() && !deleteRecursive(destDir)) {
            showErrorAndExit("删除失败", "无法删除目录: " + destDir.getAbsolutePath());
            return;
        }

        // 创建新目录
        if (!destDir.mkdirs()) {
            showErrorAndExit("创建失败", "无法创建目录: " + destDir.getAbsolutePath());
            return;
        }

        // 解压文件
        try (ZipInputStream zis = new ZipInputStream(new FileInputStream(getApplicationInfo().publicSourceDir))) {
            byte[] buffer = new byte[8192];
            ZipEntry entry;

            while ((entry = zis.getNextEntry()) != null) {
                String entryName = entry.getName();
                if (entryName.startsWith(sourceDir) && !entry.isDirectory()) {
                    String relativePath = entryName.substring(sourceDir.length());
                    File targetFile = new File(destDir, relativePath);

                    File parentDir = targetFile.getParentFile();
                    if (parentDir != null && !parentDir.exists()) {
                        if (!parentDir.mkdirs()) {
                            showErrorAndExit("创建失败", "无法创建父目录: " + parentDir.getAbsolutePath());
                            return;
                        }
                    }

                    try (FileOutputStream fos = new FileOutputStream(targetFile)) {
                        int len;
                        while ((len = zis.read(buffer)) > 0) {
                            fos.write(buffer, 0, len);
                        }
                    }
                }
                zis.closeEntry();
            }
        } catch (IOException e) {
            Log.e(TAG, "解压失败", e);
            showErrorAndExit("解压失败", e.getMessage());
        }
    }

    // 解压 assets 目录
    private void unzipAssets() {
        unzipFromApk("assets/", new File(localDir));
    }

    // 设置 libs 只读
    private void setLibsReadOnly() {
        File libsDir = new File(localDir, "libs");
        if (!libsDir.isDirectory()) return;

        File[] files = libsDir.listFiles();
        if (files == null) return;

        for (File file : files) {
            if (file.isFile()) {
                file.setReadOnly();
            }
        }
    }

    // 解压 lua 目录
    private void unzipLua() {
        unzipFromApk("lua/", new File(luaMdDir));
    }

    // 保存版本信息
    private void saveAppInfo() {
        SharedPreferences.Editor edit = info.edit();
        if (!versionName.equals(oldVersionName)) {
            edit.putString(KEY_VERSION_NAME, versionName);
        }
        edit.putLong(KEY_LAST_UPDATE_TIME, lastTime);
        edit.apply();
    }

    // 更新任务
    private class UpdateRunnable implements Runnable {
        @Override
        public void run() {
            unzipAssets();
            setLibsReadOnly();
            unzipLua();

            runOnUiThread(() -> {
                saveAppInfo();
                jumpToMain();
            });
        }
    }
}