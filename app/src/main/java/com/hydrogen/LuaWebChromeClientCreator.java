package com.hydrogen;

import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Message;
import android.view.View;
import android.webkit.ConsoleMessage;
import android.webkit.GeolocationPermissions;
import android.webkit.JsPromptResult;
import android.webkit.JsResult;
import android.webkit.PermissionRequest;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebView;

@SuppressWarnings("unused")
public class LuaWebChromeClientCreator extends WebChromeClient {

    private final Creator creator;

    public LuaWebChromeClientCreator(Creator creator) {
        this.creator = creator;
    }

    @Override
    public void onProgressChanged(WebView view, int newProgress) {
        if (creator != null) {
            creator.onProgressChanged(view, newProgress);
        } else {
            super.onProgressChanged(view, newProgress);
        }
    }

    @Override
    public void onReceivedTitle(WebView view, String title) {
        if (creator != null) {
            creator.onReceivedTitle(view, title);
        } else {
            super.onReceivedTitle(view, title);
        }
    }

    @Override
    public void onReceivedIcon(WebView view, Bitmap icon) {
        if (creator != null) {
            creator.onReceivedIcon(view, icon);
        } else {
            super.onReceivedIcon(view, icon);
        }
    }

    @Override
    public void onReceivedTouchIconUrl(WebView view, String url, boolean precomposed) {
        if (creator != null) {
            creator.onReceivedTouchIconUrl(view, url, precomposed);
        } else {
            super.onReceivedTouchIconUrl(view, url, precomposed);
        }
    }

    @Override
    public void onShowCustomView(View view, CustomViewCallback callback) {
        if (creator != null) {
            creator.onShowCustomView(view, callback);
        } else {
            super.onShowCustomView(view, callback);
        }
    }

    @Override
    public void onHideCustomView() {
        if (creator != null) {
            creator.onHideCustomView();
        } else {
            super.onHideCustomView();
        }
    }

    @Override
    public boolean onCreateWindow(WebView view, boolean isDialog, boolean isUserGesture, Message resultMsg) {
        if (creator != null) {
            return creator.onCreateWindow(view, isDialog, isUserGesture, resultMsg);
        }
        return super.onCreateWindow(view, isDialog, isUserGesture, resultMsg);
    }

    @Override
    public void onRequestFocus(WebView view) {
        if (creator != null) {
            creator.onRequestFocus(view);
        } else {
            super.onRequestFocus(view);
        }
    }

    @Override
    public void onCloseWindow(WebView window) {
        if (creator != null) {
            creator.onCloseWindow(window);
        } else {
            super.onCloseWindow(window);
        }
    }

    @Override
    public boolean onJsAlert(WebView view, String url, String message, JsResult result) {
        if (creator != null) {
            return creator.onJsAlert(view, url, message, result);
        }
        return super.onJsAlert(view, url, message, result);
    }

    @Override
    public boolean onJsConfirm(WebView view, String url, String message, JsResult result) {
        if (creator != null) {
            return creator.onJsConfirm(view, url, message, result);
        }
        return super.onJsConfirm(view, url, message, result);
    }

    @Override
    public boolean onJsPrompt(WebView view, String url, String message, String defaultValue, JsPromptResult result) {
        if (creator != null) {
            return creator.onJsPrompt(view, url, message, defaultValue, result);
        }
        return super.onJsPrompt(view, url, message, defaultValue, result);
    }

    @Override
    public boolean onJsBeforeUnload(WebView view, String url, String message, JsResult result) {
        if (creator != null) {
            return creator.onJsBeforeUnload(view, url, message, result);
        }
        return super.onJsBeforeUnload(view, url, message, result);
    }

    @Override
    public void onGeolocationPermissionsShowPrompt(String origin, GeolocationPermissions.Callback callback) {
        if (creator != null) {
            creator.onGeolocationPermissionsShowPrompt(origin, callback);
        } else {
            super.onGeolocationPermissionsShowPrompt(origin, callback);
        }
    }

    @Override
    public void onGeolocationPermissionsHidePrompt() {
        if (creator != null) {
            creator.onGeolocationPermissionsHidePrompt();
        } else {
            super.onGeolocationPermissionsHidePrompt();
        }
    }

    @Override
    public void onPermissionRequest(PermissionRequest request) {
        if (creator != null) {
            creator.onPermissionRequest(request);
        } else {
            super.onPermissionRequest(request);
        }
    }

    @Override
    public void onPermissionRequestCanceled(PermissionRequest request) {
        if (creator != null) {
            creator.onPermissionRequestCanceled(request);
        } else {
            super.onPermissionRequestCanceled(request);
        }
    }

    @Override
    public boolean onConsoleMessage(ConsoleMessage consoleMessage) {
        if (creator != null) {
            return creator.onConsoleMessage(consoleMessage);
        }
        return super.onConsoleMessage(consoleMessage);
    }

    @Override
    public Bitmap getDefaultVideoPoster() {
        if (creator != null) {
            return creator.getDefaultVideoPoster();
        }
        return super.getDefaultVideoPoster();
    }

    @Override
    public View getVideoLoadingProgressView() {
        if (creator != null) {
            return creator.getVideoLoadingProgressView();
        }
        return super.getVideoLoadingProgressView();
    }

    @Override
    public void getVisitedHistory(ValueCallback<String[]> callback) {
        if (creator != null) {
            creator.getVisitedHistory(callback);
        } else {
            super.getVisitedHistory(callback);
        }
    }

    @Override
    public boolean onShowFileChooser(WebView webView, ValueCallback<Uri[]> filePathCallback, FileChooserParams fileChooserParams) {
        if (creator != null) {
            return creator.onShowFileChooser(webView, filePathCallback, fileChooserParams);
        }
        return super.onShowFileChooser(webView, filePathCallback, fileChooserParams);
    }

    // Creator 接口
    public interface Creator {
        void onProgressChanged(WebView view, int newProgress);
        void onReceivedTitle(WebView view, String title);
        void onReceivedIcon(WebView view, Bitmap icon);
        void onReceivedTouchIconUrl(WebView view, String url, boolean precomposed);
        void onShowCustomView(View view, CustomViewCallback callback);
        void onShowCustomView(View view, int requestedOrientation, CustomViewCallback callback);
        void onHideCustomView();
        boolean onCreateWindow(WebView view, boolean isDialog, boolean isUserGesture, Message resultMsg);
        void onRequestFocus(WebView view);
        void onCloseWindow(WebView window);
        boolean onJsAlert(WebView view, String url, String message, JsResult result);
        boolean onJsConfirm(WebView view, String url, String message, JsResult result);
        boolean onJsPrompt(WebView view, String url, String message, String defaultValue, JsPromptResult result);
        boolean onJsBeforeUnload(WebView view, String url, String message, JsResult result);
        void onGeolocationPermissionsShowPrompt(String origin, GeolocationPermissions.Callback callback);
        void onGeolocationPermissionsHidePrompt();
        void onPermissionRequest(PermissionRequest request);
        void onPermissionRequestCanceled(PermissionRequest request);
        boolean onConsoleMessage(ConsoleMessage consoleMessage);
        Bitmap getDefaultVideoPoster();
        View getVideoLoadingProgressView();
        void getVisitedHistory(ValueCallback<String[]> callback);
        boolean onShowFileChooser(WebView webView, ValueCallback<Uri[]> filePathCallback, FileChooserParams fileChooserParams);
    }
}