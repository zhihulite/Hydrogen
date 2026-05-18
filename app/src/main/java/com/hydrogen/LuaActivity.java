package com.hydrogen;

import android.app.ActivityManager;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.TypedArray;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.core.splashscreen.SplashScreen;

import android.content.Context;
import android.content.res.Configuration;

import java.io.File;
import java.lang.ref.WeakReference;

public class LuaActivity extends com.androlua.LuaActivity {
    public boolean updating = false;
  private boolean checkUpdate = false;
  private final String TAG = "LuaActivity";

  private String luaPath = null;
  public String luaDir = null;
  private WeakReference<Context> mOriginalContextRef = null;

  @SuppressWarnings("unused")
  public Context getOriginalContext() {
    return mOriginalContextRef != null ? mOriginalContextRef.get() : null;
  }

  @Override
  protected void attachBaseContext(Context base) {
    // 保存原始 base 的弱引用，便于需要时使用
    mOriginalContextRef = new WeakReference<>(base);

    // 读取自定义字体缩放比例，默认 20.0 对应 1.0f 缩放
    Object fontSizeObj = this.getSharedData("font_size");
    String fontSizeStr = (fontSizeObj instanceof String) ? (String) fontSizeObj : "20.0";

    try {
      float fontScale = Float.parseFloat(fontSizeStr) / 20.0f;
      Configuration config = new Configuration(base.getResources().getConfiguration());
      config.fontScale = fontScale;
      Context updatedContext = base.createConfigurationContext(config);
      super.attachBaseContext(updatedContext);
    } catch (NumberFormatException e) {
      super.attachBaseContext(base);
    }
  }

  @Override
  public void onCreate(Bundle savedInstanceState) {
    SplashScreen.installSplashScreen(this);
    super.onCreate(savedInstanceState);

    if (savedInstanceState == null) {
      // 首次创建，读取更新检查开关
      if (!checkUpdate) {
        checkUpdate = getIntent().getBooleanExtra("checkUpdate", false);
      }
      if (checkUpdate) {
          long lastTime;
          try {
          PackageInfo packageInfo = getPackageManager().getPackageInfo(this.getPackageName(), 0);
          lastTime = packageInfo.lastUpdateTime;
        } catch (PackageManager.NameNotFoundException e) {
          Log.e(TAG, "Package name not found", e);
          lastTime = -1;
        }
        SharedPreferences info = getSharedPreferences("appInfo", MODE_PRIVATE);
          long oldLastTime = info.getLong("lastUpdateTime", 0);
        updating = oldLastTime != lastTime;
        if (updating) {
          setDebug(false);
        }

        if (updating) {
          Intent intent = new Intent(this, Welcome.class);
          intent.putExtra("newIntent", getIntent());
          intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
          startActivity(intent);
          finish();
        }
      }

    } else {
      checkUpdate = savedInstanceState.getBoolean("checkUpdate", false);
      updating = savedInstanceState.getBoolean("updating", false);
      onRestoreInstanceState(savedInstanceState);
    }
  }

  @Override
  protected void onNewIntent(@org.jspecify.annotations.NonNull Intent intent) {
    runFunc("onNewIntent", intent);
    super.onNewIntent(intent);
  }

  public void setCheckUpdate(boolean state) {
    checkUpdate = state;
  }

  @Override
  public String getLuaPath() {
    if (updating) {
      return "/"; // 更新期间阻止加载
    }
    if (luaPath == null) {
      luaPath = getIntent().getStringExtra("luaPath");
    }
    applyLuaDir(luaPath);
    return luaPath;
  }

  // 查找 main.lua 与 init.lua 共存的目录作为 luaDir
  public void applyLuaDir(String luaPath) {
    luaDir = new File(luaPath).getParent();
    String parent = luaDir;
    while (parent != null) {
      File parentDir = new File(parent);
      if (new File(parentDir, "main.lua").exists() && new File(parentDir, "init.lua").exists()) {
        luaDir = parent;
        break;
      }
      parent = parentDir.getParent();
    }
    // 防止未找到时 luaDir 为 null，提供一个安全的默认值
    if (luaDir == null) {
      luaDir = "/";
    }
    setLuaDir(luaDir);
  }

  @Override
  public void onSaveInstanceState(@NonNull Bundle outState) {
    super.onSaveInstanceState(outState);
    // 保存关键状态以便重建时恢复
    outState.putBoolean("checkUpdate", checkUpdate);
    outState.putBoolean("updating", updating);
    Log.i(TAG, "save " + outState);
    runFunc("onSaveInstanceState", outState);
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    mOriginalContextRef = null;
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

  // 构造跳转 Intent，处理相对路径、目录自动补全 main.lua 等逻辑
  public Intent buildNewActivityIntent(
          int req, String path, Object[] arg, boolean newDocument, int documentId) {
    Intent intent = new Intent(this, LuaActivity.class);
    if (path.charAt(0) != '/') {
      path = getLuaDir() + "/" + path;
    }
    File file = new File(path);
    if (file.isDirectory() && new File(path + "/main.lua").exists()) {
      path += "/main.lua";
    } else if (!file.isDirectory() && !path.endsWith(".lua")) {
      path += ".lua";
    }
    intent.putExtra("luaPath", path);
    intent.setData(Uri.parse("file://" + path + "?documentId=" + documentId));
    intent.putExtra("name", path);
    if (arg != null) {
      intent.putExtra("arg", arg);
    }
    if (newDocument) {
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_DOCUMENT);
    }
    return intent;
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

  public void newActivity(int req, String path, Object[] arg, boolean newDocument, int documentId) {
    Intent intent = buildNewActivityIntent(req, path, arg, newDocument, documentId);
    if (newDocument) {
      startActivity(intent);
    } else {
      startActivityForResult(intent, req);
    }
  }

  @Override
  public void newActivity(
          int req, String path, int in, int out, Object[] arg, boolean newDocument) {
    newActivity(req, path, in, out, arg, newDocument, 0);
  }

  public void newActivity(
          int req, String path, int in, int out, Object[] arg, boolean newDocument, int documentId) {
    newActivity(req, path, arg, newDocument, documentId);
    overridePendingTransition(in, out);
  }

  @Override
  public void setTaskDescription(ActivityManager.TaskDescription taskDescription) {
    TypedArray array =
            getTheme().obtainStyledAttributes(new int[]{android.R.attr.colorPrimary});
    int color = array.getColor(0, 0xFF000000); // 默认黑色不透明
    // 确保颜色不透明度为 FF，与原有逻辑保持一致
    taskDescription = new ActivityManager.TaskDescription(
            taskDescription.getLabel(),
            taskDescription.getIcon(),
            color | 0xFF000000);
    array.recycle();
    super.setTaskDescription(taskDescription);
  }
}