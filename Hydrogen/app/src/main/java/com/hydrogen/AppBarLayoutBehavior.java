package com.hydrogen;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.Log;
import com.google.android.material.appbar.AppBarLayout;
import androidx.coordinatorlayout.widget.CoordinatorLayout;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.widget.OverScroller;

import java.lang.reflect.Field;

// https://github.com/yuruiyin/AppbarLayoutBehavior/blob/master/appbarlayoutbehavior/src/main/java/com/yuruiyin/appbarlayoutbehavior/AppBarLayoutBehavior.java
/**
 *  解决appbarLayout若干问题：
 * （1）快速滑动appbarLayout会出现回弹
 * （2）快速滑动appbarLayout到折叠状态下，立马下滑，会出现抖动的问题
 * （3）滑动appbarLayout，无法通过手指按下让其停止滑动
 *
 * @author yuruiyin
 * @version 2018/1/3
 */
public class AppBarLayoutBehavior extends AppBarLayout.Behavior {

    private static final String TAG = "CustomAppbarLayoutBehavior";

    private static final int TYPE_FLING = 1;

    private boolean isFlinging;
    private boolean shouldBlockNestedScroll;

    public AppBarLayoutBehavior(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    @SuppressLint("LongLogTag")
    @Override
    public boolean onInterceptTouchEvent(CoordinatorLayout parent, AppBarLayout child, MotionEvent ev) {
        Log.d(TAG, "onInterceptTouchEvent:" + child.getTotalScrollRange());
        shouldBlockNestedScroll = false;
        if (isFlinging) {
            shouldBlockNestedScroll = true;
        }

        switch (ev.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                stopAppbarLayoutFling(child);  //手指触摸屏幕的时候停止fling事件
                break;
        }

        return super.onInterceptTouchEvent(parent, child, ev);
    }

    // 由于导入androidx，所以不用考虑变量修改问题

    /**
     * 反射获取私有的flingRunnable 属性
     * @return Field
     */
    @SuppressLint("LongLogTag")
    private Field getFlingRunnableField() throws NoSuchFieldException {
        try {
            Class<?> headerBehaviorType = this.getClass().getSuperclass().getSuperclass().getSuperclass();
            return headerBehaviorType.getDeclaredField("flingRunnable");
        } catch (NoSuchFieldException e) {
            Log.e(TAG, "The field does not exist.", e);
            return null;
        }
    }

    /**
     * 反射获取私有的scroller 属性
     * @return Field
     */
    @SuppressLint("LongLogTag")
    private Field getScrollerField() throws NoSuchFieldException {
        try {
            Class<?> headerBehaviorType = this.getClass().getSuperclass().getSuperclass().getSuperclass();
            return headerBehaviorType.getDeclaredField("scroller");
        } catch (NoSuchFieldException e) {
            Log.e(TAG, "The field does not exist.", e);
            return null;
        }
    }

    /**
     * 停止appbarLayout的fling事件
     * @param appBarLayout
     */
    @SuppressLint("LongLogTag")
    private void stopAppbarLayoutFling(AppBarLayout appBarLayout) {
        //通过反射拿到HeaderBehavior中的flingRunnable变量
        try {
            Field flingRunnableField = getFlingRunnableField();
            Field scrollerField = getScrollerField();
            flingRunnableField.setAccessible(true);
            scrollerField.setAccessible(true);

            Runnable flingRunnable = (Runnable) flingRunnableField.get(this);
            OverScroller overScroller = (OverScroller) scrollerField.get(this);
            if (flingRunnable != null) {
                Log.d(TAG, "存在flingRunnable");
                appBarLayout.removeCallbacks(flingRunnable);
                flingRunnableField.set(this, null);
            }
            if (overScroller != null && !overScroller.isFinished()) {
                overScroller.abortAnimation();
            }
        } catch (NoSuchFieldException e) {
            e.printStackTrace();
        } catch (IllegalAccessException e) {
            e.printStackTrace();
        }
    }

    @SuppressLint("LongLogTag")
    @Override
    public boolean onStartNestedScroll(CoordinatorLayout parent, AppBarLayout child, View directTargetChild, View target, int nestedScrollAxes, int type) {
        Log.d(TAG, "onStartNestedScroll");
        stopAppbarLayoutFling(child);
        return super.onStartNestedScroll(parent, child, directTargetChild, target, nestedScrollAxes, type);
    }

    @SuppressLint("LongLogTag")
    @Override
    public void onNestedPreScroll(CoordinatorLayout coordinatorLayout, AppBarLayout child, View target, int dx, int dy, int[] consumed, int type) {
        Log.d(TAG, "onNestedPreScroll:" + child.getTotalScrollRange() + " ,dx:" + dx + " ,dy:" + dy + " ,type:" + type);

        //type返回1时，表示当前target处于非touch的滑动，
        //该bug的引起是因为appbar在滑动时，CoordinatorLayout内的实现NestedScrollingChild2接口的滑动子类还未结束其自身的fling
        //所以这里监听子类的非touch时的滑动，然后block掉滑动事件传递给AppBarLayout
        if (type == TYPE_FLING) {
            isFlinging = true;
        }
        if (!shouldBlockNestedScroll) {
            super.onNestedPreScroll(coordinatorLayout, child, target, dx, dy, consumed, type);
        }
    }

    @SuppressLint("LongLogTag")
    @Override
    public void onNestedScroll(CoordinatorLayout coordinatorLayout, AppBarLayout child, View target, int dxConsumed, int dyConsumed, int
            dxUnconsumed, int dyUnconsumed, int type) {
        Log.d(TAG, "onNestedScroll: target:" + target.getClass() + " ," + child.getTotalScrollRange() + " ,dxConsumed:"
                + dxConsumed + " ,dyConsumed:" + dyConsumed + " " + ",type:" + type);
        if (!shouldBlockNestedScroll) {
            super.onNestedScroll(coordinatorLayout, child, target, dxConsumed, dyConsumed, dxUnconsumed, dyUnconsumed, type);
        }
    }

    @SuppressLint("LongLogTag")
    @Override
    public void onStopNestedScroll(CoordinatorLayout coordinatorLayout, AppBarLayout abl, View target, int type) {
        Log.d(TAG, "onStopNestedScroll");
        super.onStopNestedScroll(coordinatorLayout, abl, target, type);
        isFlinging = false;
        shouldBlockNestedScroll = false;
    }


}
