// 原代码取自 https://blog.csdn.net/qq_38431616/article/details/128014877
package com.hydrogen.view;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;
import android.view.MotionEvent;
import android.view.animation.Animation.AnimationListener;

import androidx.swiperefreshlayout.widget.CircularProgressDrawable;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import java.lang.reflect.Method;
import java.lang.reflect.Field;
import java.util.Objects;

@SuppressWarnings("unused")
public class CustomSwipeRefresh extends SwipeRefreshLayout {

    private static final String TAG = "CustomSwipeRefresh";

    private CircularProgressDrawable mProgress;
    private Method mScaleDownFunc;
    private AnimationListener mRefreshListener;

    public CustomSwipeRefresh(Context context) {
        super(context);
        init();
    }

    public CustomSwipeRefresh(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    private void init() {
        try {
            Class<?> superClazz = getClass().getSuperclass();

            Field progressField = Objects.requireNonNull(superClazz).getDeclaredField("mProgress");
            progressField.setAccessible(true);
            mProgress = (CircularProgressDrawable) progressField.get(this);

            mScaleDownFunc = superClazz.getDeclaredMethod("startScaleDownAnimation", AnimationListener.class);
            mScaleDownFunc.setAccessible(true);

            Field listenerField = superClazz.getDeclaredField("mRefreshListener");
            listenerField.setAccessible(true);
            mRefreshListener = (AnimationListener) listenerField.get(this);
        } catch (Exception e) {
            Log.e(TAG, "反射初始化失败", e);
        }
    }

    // -0.125f是进度条拖动到顶部的一个临界值 经过调试打印得到的。
    @Override
    public boolean dispatchTouchEvent(MotionEvent ev) {
        if (ev != null && ev.getAction() == MotionEvent.ACTION_UP && mProgress != null && mProgress.getProgressRotation() == -0.125f) {
            try {
                mScaleDownFunc.invoke(this, mRefreshListener);
            } catch (Exception e) {
                Log.e(TAG, "调用动画失败", e);
            }
        }
        return super.dispatchTouchEvent(ev);
    }
}