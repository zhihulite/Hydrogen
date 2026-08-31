// 实现参考：https://blog.csdn.net/weixin_36222137/article/details/53411029
package com.hydrogen.view;

import android.content.Context;
import android.util.AttributeSet;
import android.view.MotionEvent;

import androidx.viewpager.widget.ViewPager;

@SuppressWarnings("unused")
public class CustomViewPager extends ViewPager {

    private float startX;
    private float startY;

    public CustomViewPager(Context context) {
        super(context);
    }

    public CustomViewPager(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    @Override
    public boolean dispatchTouchEvent(MotionEvent ev) {
        switch (ev.getAction()) {
            case MotionEvent.ACTION_DOWN:
                // 按下时禁止父容器拦截，让事件先给 ViewPager
                getParent().requestDisallowInterceptTouchEvent(true);
                startX = ev.getX();
                startY = ev.getY();
                break;

            case MotionEvent.ACTION_MOVE:
                float endX = ev.getX();
                float endY = ev.getY();
                float distanceX = endX - startX;
                float distanceY = endY - startY;

                // 滑动方向：水平 vs 垂直
                if (Math.abs(distanceX) > Math.abs(distanceY)) {
                    boolean allowParentIntercept = isAllowParentIntercept(distanceX);
                    getParent().requestDisallowInterceptTouchEvent(!allowParentIntercept);
                } else {
                    // 垂直滑动 -> 禁止父容器拦截（内部子 View 自行滚动）
                    getParent().requestDisallowInterceptTouchEvent(true);
                }
                break;
        }
        return super.dispatchTouchEvent(ev);
    }

    private boolean isAllowParentIntercept(float distanceX) {
        int currentItem = getCurrentItem();
        int lastItem = getAdapter() != null ? getAdapter().getCount() - 1 : 0;

        boolean allowParentIntercept;

        if (currentItem == 0 && distanceX > 0) {
            // 第一页 + 向右滑 -> 允许父容器拦截（DrawerLayout 拉出抽屉）
            allowParentIntercept = true;
        } else if (currentItem == lastItem && distanceX < 0) {
            // 最后一页 + 向左滑 -> 禁止父容器拦截（ViewPager 自行处理边缘效果）
            allowParentIntercept = false;
        } else {
            // 中间页面 -> 禁止父容器拦截（ViewPager 正常切换）
            allowParentIntercept = false;
        }
        return allowParentIntercept;
    }
}