package com.jesse205.superlua;

import android.app.ActivityManager;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.TypedArray;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.window.BackEvent;
import android.window.OnBackAnimationCallback;
import android.window.OnBackInvokedDispatcher;
import androidx.annotation.NonNull;
import androidx.core.splashscreen.SplashScreen;


import com.luajava.LuaObject;
import com.luajava.LuaState;

import android.content.Context;
import android.content.res.Configuration;
import android.content.res.Resources;

import java.io.File;

import java.lang.ref.WeakReference;

public class LuaActivity extends com.androlua.LuaActivity {
  private long oldLastTime = 0;
  private long lastTime = 0;
  public boolean updating = false;
  private boolean checkUpdate = false;
  private String TAG = "LuaActivity";

  private String luaPath;
  public String luaDir;
  private LuaState L;
  private LuaObject mOnBackPressed;
  private OnBackAnimationCallback OnBackAnimationCallback;

  private WeakReference<Context> mOriginalContextRef;

  // 获取原始 Context
  public Context getOriginalContext() {
    return mOriginalContextRef != null ? mOriginalContextRef.get() : null;
  }

  @Override
  protected void attachBaseContext(Context base) {

    mOriginalContextRef = new WeakReference<>(base);
    // 获取字体大小设置
    Object fontSizeObj = this.getSharedData("font_size");

    String fontSizeStr;
    if (fontSizeObj instanceof String) {
      fontSizeStr = (String) fontSizeObj;
    } else {
      fontSizeStr = "20.0"; // 默认值
    }

    try {
      Configuration config = new Configuration(base.getResources().getConfiguration());
      float fontScale = Float.parseFloat(fontSizeStr) / 20;
      config.fontScale = fontScale;

      // 使用base创建新的Context
      Context updatedContext = base.createConfigurationContext(config);
      super.attachBaseContext(updatedContext);
    } catch (NumberFormatException e) {
      super.attachBaseContext(base); // 使用原始的base context以防出错
    }
  }

  @Override
  public void onCreate(Bundle savedInstanceState) {
      super.onCreate(savedInstanceState);
      
    if (savedInstanceState == null) {
      if (!checkUpdate) checkUpdate = getIntent().getBooleanExtra("checkUpdate", false);
      if (checkUpdate) {
        try {
          PackageInfo packageInfo = getPackageManager().getPackageInfo(this.getPackageName(), 0);
          lastTime = packageInfo.lastUpdateTime; // 更新时间
        } catch (PackageManager.NameNotFoundException e) {
          e.printStackTrace();
        }
        SharedPreferences info = getSharedPreferences("appInfo", 0);
        oldLastTime = info.getLong("lastUpdateTime", 0);
        updating = oldLastTime != lastTime;
        if (updating) setDebug(false);
      }
	
	// Handle the splash screen transition.
	SplashScreen.installSplashScreen(this);

      if (checkUpdate && (oldLastTime != lastTime)) {
        Intent intent = new Intent(this, Welcome.class);
        intent.putExtra("newIntent", getIntent());
        intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(intent);
        finish();
      }
      L = getLuaState();
      mOnBackPressed = L.getLuaObject("onBackPressed");
      if (mOnBackPressed.isNil()) mOnBackPressed = null;
    } else {
      onRestoreInstanceState(savedInstanceState);
    }
  }

  // Androlua本身这个仅在Main出现
  @Override
  protected void onNewIntent(Intent intent) {
    runFunc("onNewIntent", intent);
    super.onNewIntent(intent);
  }

  // 检查资源更新开关
  public void setCheckUpdate(boolean state) {
    checkUpdate = state;
  }

  // 新的lua路径获取方法
  @Override
  public String getLuaPath() {
    if (updating) {
      luaPath = "/"; // 阻止软件运行
    } else if (luaPath == null) {
      luaPath = getIntent().getStringExtra("luaPath");
    }
    applyLuaDir(luaPath);
    return luaPath;
  }

  // 应用一下LuaDir
  public void applyLuaDir(String luaPath) {
    String parent = new File(luaPath).getParent();
    luaDir = parent;
    while (parent != null) {
      if (new File(parent, "main.lua").exists() && new File(parent, "init.lua").exists()) {
        luaDir = parent;
        break;
      }
      parent = new File(parent).getParent();
    }
    setLuaDir(luaDir);
  }

  @Override
  public void onSaveInstanceState(Bundle outState) {
    // TODO: Implement this method
    super.onSaveInstanceState(outState);
    Log.i(TAG, "save" + outState.toString());
    runFunc("onSaveInstanceState", outState);
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    mOriginalContextRef = null; // 清理引用

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE
        && OnBackAnimationCallback != null) {
      getOnBackInvokedDispatcher().unregisterOnBackInvokedCallback(OnBackAnimationCallback);
    }
  }

  @Override
  public void onBackPressed() {
    if (mOnBackPressed != null) {
      Object ret = mOnBackPressed.call();
      if (ret != null && ret.getClass() == Boolean.class && (Boolean) ret) return;
    }
    super.onBackPressed();
  }

  @Override
  public void onRestoreInstanceState(@NonNull Bundle savedInstanceState) {
    // TODO: Implement this method
    try {
      super.onRestoreInstanceState(savedInstanceState);
      Log.i(TAG, "restore" + savedInstanceState.toString());
    } catch (Exception e) {
      sendError("onRestoreInstanceState", e);
    }
    runFunc("onRestoreInstanceState", savedInstanceState);
  }

  public Intent buildNewActivityIntent(
      int req, String path, Object[] arg, boolean newDocument, int documentId) {
    Intent intent = new Intent(this, LuaActivity.class);
    intent.putExtra("name", path);
    if (path.charAt(0) != '/') // 如果不是/开头，说明是相对路径
    path = this.getLuaDir() + "/" + path;
    File file = new File(path);
    if (file.isDirectory() && new File(path + "/main.lua").exists()) path += "/main.lua";
    else if (!file.isDirectory() && !path.endsWith(".lua")) path += ".lua";
    intent.putExtra("luaPath", path);
    intent.setData(Uri.parse("file://" + path + "?documentId=" + String.valueOf(documentId)));
    // intent.putExtra("documentId", documentId);
    if (arg != null) intent.putExtra("arg", arg);
    if (newDocument) intent.addFlags(Intent.FLAG_ACTIVITY_NEW_DOCUMENT);
    return intent;
  }

  // 重写newActivity，将目标Activity指向superlua的
  public void newActivity(String path, boolean newDocument, int documentId) {
    newActivity(1, path, null, newDocument, documentId);
  }

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
    } else startActivityForResult(intent, req);
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
        this.getTheme().obtainStyledAttributes(new int[] {android.R.attr.colorPrimary});
    taskDescription =
        new ActivityManager.TaskDescription(
            taskDescription.getLabel(),
            taskDescription.getIcon(),
            array.getColor(0, 0xFF0000) | 0xFF000000);
    array.recycle();
    super.setTaskDescription(taskDescription);
  }
}
