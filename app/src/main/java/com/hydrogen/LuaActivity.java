package com.hydrogen;

import android.content.Context;
import android.content.res.Configuration;
import android.os.Bundle;
import android.util.Log;

import androidx.core.splashscreen.SplashScreen;

public class LuaActivity extends org.luajvm.android.host.LuaActivity {

    private static final String TAG = "LuaActivity";
    private static final float DEFAULT_FONT_SIZE = 20.0f;

    private Context originalContext = null;

    @SuppressWarnings("unused")
    public Context getOriginalContext() {
        return originalContext;
    }

    @Override
    protected void attachBaseContext(Context base) {
        originalContext = base;
        super.attachBaseContext(applyFontScale(base));
    }

    // 全局字体缩放：读 SharedData 的 font_size（默认 20），换算 Configuration.fontScale
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

    // 脚本页承载类固定为本类（standard 启动模式）。MainActivity 是 singleTask，
    // 用它承载会让 NEW_DOCUMENT 退化成给现有实例投 onNewIntent：页面不跳转，
    // 且 setIntent 写入的脚本入口会在下次 recreate 时被当作本页入口重放
    @Override
    protected Class<?> getScriptHostClass() {
        return LuaActivity.class;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        originalContext = null;
    }
}
