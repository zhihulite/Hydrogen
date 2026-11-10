package com.hydrogen;

import android.content.pm.ApplicationInfo;
import android.os.Build;

import org.luajvm.android.LuaApplication;
import org.lsposed.hiddenapibypass.HiddenApiBypass;

/**
 * 宿主 Application：luajvm 引擎 Application 基类之上做进程级初始化。
 */
public class HydrogenApplication extends LuaApplication {

    // Constants.SharedDataKeys.PREDICTIVE_BACK 的存储键（键名由 Lua 侧 SETTINGS 派生，Java 侧取不到）
    private static final String KEY_PREDICTIVE_BACK = "predictive_back";

    @Override
    public void onCreate() {
        super.onCreate();
        applyPredictiveBackSetting();
    }

    /**
     * 设置「预见性返回」关闭时关闭预测性返回，开启时不改动系统默认行为。targetSdk 35+
     * 默认开启，页面经 OnBackPressedDispatcher 接管返回键时系统仍按「即将退出」播放预览
     * 动画。隐藏 setter 在 SDK 34+ 提供，经 HiddenApiBypass 解除反射限制后调用；改动
     * 作用于进程内共享的 ApplicationInfo，其后 attach 的 Activity 均按新值注册返回回调。
     */
    private void applyPredictiveBackSetting() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return;
        // 配置值经 Lua tostring 落库为字符串，缺省视为关闭
        if ("true".equals(String.valueOf(getSharedData(KEY_PREDICTIVE_BACK)))) return;
        HiddenApiBypass.addHiddenApiExemptions(
                "Landroid/content/pm/ApplicationInfo;->setEnableOnBackInvokedCallback");
        try {
            ApplicationInfo.class
                    .getDeclaredMethod("setEnableOnBackInvokedCallback", boolean.class)
                    .invoke(getApplicationInfo(), false);
        } catch (Exception ignored) {
        }
    }
}
