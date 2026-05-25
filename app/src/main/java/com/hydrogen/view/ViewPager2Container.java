// source https://blog.csdn.net/plokmju88/article/details/119769766
package com.hydrogen.view;

import android.content.Context;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;
import android.widget.RelativeLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.viewpager2.widget.ViewPager2;

@SuppressWarnings("unused")
public class ViewPager2Container extends RelativeLayout {

    private ViewPager2 mViewPager2;
    private boolean disallowParentInterceptDownEvent = true;
    private float startX = 0;
    private float startY = 0;

    public ViewPager2Container(@NonNull Context context) {
        this(context, null);
    }

    public ViewPager2Container(@NonNull Context context, @Nullable AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public ViewPager2Container(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    private void ensureViewPager2() {
        if (mViewPager2 != null) return;

        for (int i = 0; i < getChildCount(); i++) {
            View child = getChildAt(i);
            if (child instanceof ViewPager2) {
                mViewPager2 = (ViewPager2) child;
                break;
            }
        }
    }

    @Override
    public boolean onInterceptTouchEvent(MotionEvent ev) {
        ensureViewPager2();

        if (mViewPager2 == null) {
            return super.onInterceptTouchEvent(ev);
        }

        boolean doNotNeedIntercept = !mViewPager2.isUserInputEnabled()
                || (mViewPager2.getAdapter() != null
                && mViewPager2.getAdapter().getItemCount() <= 1);

        if (doNotNeedIntercept) {
            return super.onInterceptTouchEvent(ev);
        }

        switch (ev.getAction()) {
            case MotionEvent.ACTION_DOWN:
                startX = ev.getX();
                startY = ev.getY();
                getParent().requestDisallowInterceptTouchEvent(!disallowParentInterceptDownEvent);
                break;

            case MotionEvent.ACTION_MOVE:
                float endX = ev.getX();
                float endY = ev.getY();
                float disX = Math.abs(endX - startX);
                float disY = Math.abs(endY - startY);

                if (mViewPager2.getOrientation() == ViewPager2.ORIENTATION_VERTICAL) {
                    onVerticalActionMove(endY, disX, disY);
                } else {
                    onHorizontalActionMove(endX, disX, disY);
                }
                break;

            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                getParent().requestDisallowInterceptTouchEvent(false);
                break;
        }

        return super.onInterceptTouchEvent(ev);
    }

    private void onHorizontalActionMove(float endX, float disX, float disY) {
        if (mViewPager2.getAdapter() == null) return;

        if (disX > disY) {
            int currentItem = mViewPager2.getCurrentItem();
            int itemCount = mViewPager2.getAdapter().getItemCount();

            if (currentItem == 0 && endX - startX > 0) {
                getParent().requestDisallowInterceptTouchEvent(false);
            } else {
                getParent().requestDisallowInterceptTouchEvent(
                        currentItem != itemCount - 1 || endX - startX >= 0
                );
            }
        } else if (disY > disX) {
            getParent().requestDisallowInterceptTouchEvent(false);
        }
    }

    private void onVerticalActionMove(float endY, float disX, float disY) {
        if (mViewPager2.getAdapter() == null) return;

        if (disY > disX) {
            int currentItem = mViewPager2.getCurrentItem();
            int itemCount = mViewPager2.getAdapter().getItemCount();

            if (currentItem == 0 && endY - startY > 0) {
                getParent().requestDisallowInterceptTouchEvent(false);
            } else {
                getParent().requestDisallowInterceptTouchEvent(
                        currentItem != itemCount - 1 || endY - startY >= 0
                );
            }
        } else if (disX > disY) {
            getParent().requestDisallowInterceptTouchEvent(false);
        }
    }

    public void disallowParentInterceptDownEvent(boolean disallowParentInterceptDownEvent) {
        this.disallowParentInterceptDownEvent = disallowParentInterceptDownEvent;
    }
}