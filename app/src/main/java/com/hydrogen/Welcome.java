package com.hydrogen;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;

import androidx.activity.EdgeToEdge;
import androidx.activity.OnBackPressedCallback;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.splashscreen.SplashScreen;

import com.androlua.LuaApplication;
import com.androlua.LuaUtil;
import com.zhihu.hydrogen.x.R;

import java.io.File;
import java.lang.ref.WeakReference;

import net.lingala.zip4j.ZipFile;
import net.lingala.zip4j.exception.ZipException;

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
    private UpdateTask updateTask;
    private boolean isActivityStarted = false;
    private OnBackPressedCallback backCallback;

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
                Log.d(TAG, "Back button intercepted");
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
            Log.e(TAG, "Package not found", e);
            finish();
        } catch (Exception e) {
            Log.e(TAG, "Init failed", e);
            finish();
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

        updateTask = new UpdateTask(this);
        updateTask.execute("");
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (backCallback != null) {
            backCallback.remove();
        }
        if (updateTask != null && !updateTask.isCancelled()) {
            updateTask.cancel(false);
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
                Intent intent = (Intent) mBundle.get("newIntent");
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

    // 异步更新任务
    @SuppressLint("StaticFieldLeak")
    private static class UpdateTask extends AsyncTask<String, String, String> {
        private final WeakReference<Welcome> activityRef;

        UpdateTask(Welcome activity) {
            activityRef = new WeakReference<>(activity);
        }

        @Override
        protected String doInBackground(String... params) {
            Welcome activity = activityRef.get();
            if (activity == null || activity.isFinishing() || isCancelled()) {
                return null;
            }

            try {
                unzipAssets(activity);
                setLibsReadOnly(activity);
                unzipLua(activity);
                saveAppInfo(activity);
            } catch (ZipException e) {
                Log.e(TAG, "Unzip failed", e);
            } catch (Exception e) {
                Log.e(TAG, "Update failed", e);
            }
            return null;
        }

        @Override
        protected void onPostExecute(String result) {
            Welcome activity = activityRef.get();
            if (activity != null && !activity.isFinishing() && !isCancelled()) {
                activity.jumpToMain();
            }
        }
    }

    // 解压 assets 目录
    private static void unzipAssets(Welcome activity) throws ZipException {
        File destDir = new File(activity.localDir);
        String tempDir = activity.getCacheDir().getPath();
        LuaUtil.rmDir(destDir);
        ZipFile zipFile = new ZipFile(activity.getApplicationInfo().publicSourceDir);
        zipFile.extractFile("assets/", tempDir);
        new File(tempDir + "/assets/").renameTo(destDir);
    }

    // 设置 libs 只读
    private static void setLibsReadOnly(Welcome activity) {
        File libsDir = new File(activity.localDir, "libs");
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
    private static void unzipLua(Welcome activity) throws ZipException {
        File luaDest = new File(activity.luaMdDir);
        String tempDir = activity.getCacheDir().getPath();
        LuaUtil.rmDir(luaDest);
        ZipFile zipFile = new ZipFile(activity.getApplicationInfo().publicSourceDir);
        zipFile.extractFile("lua/", tempDir);
        new File(tempDir + "/lua/").renameTo(luaDest);
    }

    // 保存版本信息
    private static void saveAppInfo(Welcome activity) {
        SharedPreferences.Editor edit = activity.info.edit();
        if (!activity.versionName.equals(activity.oldVersionName)) {
            edit.putString(KEY_VERSION_NAME, activity.versionName);
        }
        edit.putLong(KEY_LAST_UPDATE_TIME, activity.lastTime);
        edit.apply();
    }
}