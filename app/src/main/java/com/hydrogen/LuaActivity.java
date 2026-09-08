package com.hydrogen;

import android.content.Context;
import android.content.res.Configuration;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.util.Log;

import androidx.activity.EdgeToEdge;
import androidx.core.splashscreen.SplashScreen;

import com.google.android.material.color.MaterialColors;

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

    // 全局字体缩放：font_size / 20 换算 Configuration.fontScale
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

    // 脚本页承载类固定为本类（standard 启动模式），MainActivity 为 singleTask，
    // 承载脚本页时 NEW_DOCUMENT 会退化为给现有实例投 onNewIntent，页面不跳转
    @Override
    protected Class<?> getScriptHostClass() {
        return LuaActivity.class;
    }

    // 错误日志页兜底：Lua 启动失败时不会走到页面的 setupEdgeToEdge，
    // 状态栏区域由本方法补齐——窗口背景按主题 colorBackground 不透明化，
    // EdgeToEdge.enable 让状态栏明暗跟随背景并给内容让位
    @Override
    public void applyDefaultView() {
        super.applyDefaultView();
        getWindow().setBackgroundDrawable(new ColorDrawable(
                MaterialColors.getColor(this, android.R.attr.colorBackground, 0xFF14151A)));
        EdgeToEdge.enable(this);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        originalContext = null;
    }
}
