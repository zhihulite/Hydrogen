package com.hydrogen;

import android.graphics.Bitmap;
import android.net.http.SslError;
import android.os.Message;
import android.view.KeyEvent;
import android.webkit.HttpAuthHandler;
import android.webkit.SslErrorHandler;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class LuaWebViewClientCreator extends WebViewClient {

    private final Creator creator;

    public LuaWebViewClientCreator(Creator creator) {
        this.creator = creator;
    }

    @Override
    public void doUpdateVisitedHistory(WebView view, String url, boolean isReload) {
        if (creator != null) {
            creator.doUpdateVisitedHistory(view, url, isReload);
        } else {
            super.doUpdateVisitedHistory(view, url, isReload);
        }
    }

    @Override
    public void onFormResubmission(WebView view, Message dontResend, Message resend) {
        if (creator != null) {
            creator.onFormResubmission(view, dontResend, resend);
        } else {
            super.onFormResubmission(view, dontResend, resend);
        }
    }

    @Override
    public void onLoadResource(WebView view, String url) {
        if (creator != null) {
            creator.onLoadResource(view, url);
        } else {
            super.onLoadResource(view, url);
        }
    }

    @Override
    public void onPageFinished(WebView view, String url) {
        if (creator != null) {
            creator.onPageFinished(view, url);
        } else {
            super.onPageFinished(view, url);
        }
    }

    @Override
    public void onPageStarted(WebView view, String url, Bitmap favicon) {
        if (creator != null) {
            creator.onPageStarted(view, url, favicon);
        } else {
            super.onPageStarted(view, url, favicon);
        }
    }

    @Override
    public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
        if (creator != null) {
            creator.onReceivedError(view, errorCode, description, failingUrl);
        } else {
            super.onReceivedError(view, errorCode, description, failingUrl);
        }
    }

    @Override
    public void onReceivedHttpAuthRequest(WebView view, HttpAuthHandler handler, String host, String realm) {
        if (creator != null) {
            creator.onReceivedHttpAuthRequest(view, handler, host, realm);
        } else {
            super.onReceivedHttpAuthRequest(view, handler, host, realm);
        }
    }

    @Override
    public void onReceivedLoginRequest(WebView view, String realm, String account, String args) {
        if (creator != null) {
            creator.onReceivedLoginRequest(view, realm, account, args);
        } else {
            super.onReceivedLoginRequest(view, realm, account, args);
        }
    }

    @Override
    public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
        if (creator != null) {
            creator.onReceivedSslError(view, handler, error);
        } else {
            super.onReceivedSslError(view, handler, error);
        }
    }

    @Override
    public void onScaleChanged(WebView view, float oldScale, float newScale) {
        if (creator != null) {
            creator.onScaleChanged(view, oldScale, newScale);
        } else {
            super.onScaleChanged(view, oldScale, newScale);
        }
    }

    @Override
    public void onUnhandledKeyEvent(WebView view, KeyEvent event) {
        if (creator != null) {
            creator.onUnhandledKeyEvent(view, event);
        } else {
            super.onUnhandledKeyEvent(view, event);
        }
    }

    @Override
    public WebResourceResponse shouldInterceptRequest(WebView view, String url) {
        if (creator != null) {
            return creator.shouldInterceptRequest(view, url);
        }
        return super.shouldInterceptRequest(view, url);
    }

    @Override
    public boolean shouldOverrideKeyEvent(WebView view, KeyEvent event) {
        if (creator != null) {
            return creator.shouldOverrideKeyEvent(view, event);
        }
        return super.shouldOverrideKeyEvent(view, event);
    }

    @Override
    public boolean shouldOverrideUrlLoading(WebView view, String url) {
        if (creator != null) {
            return creator.shouldOverrideUrlLoading(view, url);
        }
        return super.shouldOverrideUrlLoading(view, url);
    }

    // Creator 接口
    public interface Creator {
        void doUpdateVisitedHistory(WebView view, String url, boolean isReload);
        void onFormResubmission(WebView view, Message dontResend, Message resend);
        void onLoadResource(WebView view, String url);
        void onPageFinished(WebView view, String url);
        void onPageStarted(WebView view, String url, Bitmap favicon);
        void onReceivedError(WebView view, int errorCode, String description, String failingUrl);
        void onReceivedHttpAuthRequest(WebView view, HttpAuthHandler handler, String host, String realm);
        void onReceivedLoginRequest(WebView view, String realm, String account, String args);
        void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error);
        void onScaleChanged(WebView view, float oldScale, float newScale);
        void onUnhandledKeyEvent(WebView view, KeyEvent event);
        WebResourceResponse shouldInterceptRequest(WebView view, String url);
        boolean shouldOverrideKeyEvent(WebView view, KeyEvent event);
        boolean shouldOverrideUrlLoading(WebView view, String url);
    }
}
