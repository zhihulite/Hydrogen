package com.hydrogen;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
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
    private String luaMdDir;
    private String localDir;
    private long lastTime;
    private String versionName;
    private SharedPreferences info;
    private String oldVersionName;
    private UpdateTask updateTask;
    private boolean isActivityStarted = false; // 防止重复启动

    @Override
    public void onCreate(Bundle savedInstanceState) {
        // 安装闪屏，兼容 Android 12+
        SplashScreen.installSplashScreen(this);
        super.onCreate(savedInstanceState);

        try {
            PackageInfo packageInfo = getPackageManager().getPackageInfo(this.getPackageName(), 0);
            lastTime = packageInfo.lastUpdateTime;
            versionName = packageInfo.versionName;
            info = getSharedPreferences("appInfo", MODE_PRIVATE);
            long oldLastTime = info.getLong("lastUpdateTime", 0);
            oldVersionName = info.getString("versionName", "");

            if (oldLastTime != lastTime) {
                LuaApplication app = (LuaApplication) getApplication();
                luaMdDir = app.getMdDir();
                localDir = app.getLocalDir();

                // 仅在需要更新时才设置布局
                setContentView(R.layout.layout_welcome);
                updateTask = new UpdateTask(this);
                updateTask.execute();
            } else {
                // 无需更新，直接启动目标Activity
                startActivity(false);
            }
        } catch (PackageManager.NameNotFoundException e) {
            Log.e(TAG, "Package name not found", e);
            finish();
        } catch (Exception e) {
            Log.e(TAG, "Error in onCreate", e);
            finish();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        // 取消正在进行的异步任务，避免内存泄漏
        if (updateTask != null && !updateTask.isCancelled()) {
            updateTask.cancel(false);
        }
    }

    // 同步的启动方法，防止重复调用
    private synchronized void startActivity(Boolean isUpdate) {
        if (isActivityStarted) {
            Log.w(TAG, "Activity already started, ignoring duplicate call");
            return;
        }
        isActivityStarted = true;

        Intent intent = null;
        if (isUpdate) {
            // 仅在更新时从原Intent中恢复目标
            Intent mIntent = getIntent();
            if (mIntent != null) {
                Bundle mBundle = mIntent.getExtras();
                if (mBundle != null) {
                    intent = (Intent) mBundle.get("newIntent");
                }
            }
            if (intent == null) {
                intent = new Intent(Welcome.this, MainActivity.class);
            }
            intent.putExtra("isVersionChanged", true);
            intent.putExtra("newVersionName", versionName);
            intent.putExtra("oldVersionName", oldVersionName);
        } else {
            intent = new Intent(Welcome.this, MainActivity.class);
        }

        intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(intent);
        finish();
    }

    // 拦截所有按键，防止在更新期间误操作退出
    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        return true;
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
    }

    @Override
    protected void onResume() {
        super.onResume();
    }

    // 静态内部类 + 弱引用避免内存泄漏
    @SuppressLint("StaticFieldLeak")
    private static class UpdateTask extends AsyncTask<String, String, String> {
        private final WeakReference<Welcome> activityRef;

        UpdateTask(Welcome activity) {
            this.activityRef = new WeakReference<>(activity);
        }

        @Override
        protected String doInBackground(String... params) {
            Welcome activity = activityRef.get();
            if (activity == null || activity.isFinishing() || isCancelled()) {
                return null;
            }

            try {
                activity.unApk("assets/", activity.localDir);
                activity.setLibsReadOnly();
                activity.unApk("lua/", activity.luaMdDir);
                activity.saveAppInfo();
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
                activity.startActivity(true);
            }
        }
    }

    // 设置 libs 目录下文件为只读
    private void setLibsReadOnly() {
        File libsDirectory = new File(localDir, "libs");
        if (!libsDirectory.exists() || !libsDirectory.isDirectory()) {
            return;
        }
        File[] files = libsDirectory.listFiles();
        if (files == null) {
            return;
        }
        for (File file : files) {
            if (file.isFile() && !file.setReadOnly()) {
                Log.w(TAG, "Failed to set read-only: " + file.getAbsolutePath());
            }
        }
    }

    // 保存版本信息和更新时间
    private void saveAppInfo() {
        SharedPreferences.Editor edit = info.edit();
        if (!versionName.equals(oldVersionName)) {
            edit.putString("versionName", versionName);
        }
        edit.putLong("lastUpdateTime", lastTime);
        edit.apply();
    }

    // 解压 APK 内指定目录到外部目录
    private void unApk(String dir, String extDir) throws ZipException {
        File destDir = new File(extDir);
        String tempDir = getCacheDir().getPath();

        // 清空目标目录
        LuaUtil.rmDir(destDir);

        // 解压到临时目录
        //noinspection resource
        ZipFile zipFile = new ZipFile(getApplicationInfo().publicSourceDir);
        zipFile.extractFile(dir, tempDir);

        // 移动到目标目录
        //noinspection ResultOfMethodCallIgnored
        new File(tempDir + "/" + dir).renameTo(destDir);
    }
}