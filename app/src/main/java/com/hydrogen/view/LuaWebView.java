package com.hydrogen.view;

import android.content.Context;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import com.androlua.LuaGcable;

public class LuaWebView extends WebView implements LuaGcable {

    private boolean isGced = false;

    public interface Bridge {
        String execute(String action, String data);
    }

    public LuaWebView(Context context) {
        super(context);
        getSettings().setJavaScriptEnabled(true);
    }

    public void setBridge(Bridge bridge) {
        addJavascriptInterface(new JsObject(bridge), "HydrogenBridge");
    }

    private static class JsObject {
        private final Bridge mBridge;

        public JsObject(Bridge bridge) {
            mBridge = bridge;
        }

        @JavascriptInterface
        public String execute(String action, String data) {
            if (mBridge != null) {
                return mBridge.execute(action, data);
            }
            return "";
        }
    }

    @Override
    public void gc() {
        if (!isGced) {
            isGced = true;
            removeJavascriptInterface("HydrogenBridge");
            destroy();
        }
    }

    @Override
    public boolean isGc() {
        return isGced;
    }
}