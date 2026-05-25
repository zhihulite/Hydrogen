// source https://blog.csdn.net/weixin_36222137/article/details/53411029
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
                // 按下时禁止父容器拦截，确保事件先给ViewPager
                getParent().requestDisallowInterceptTouchEvent(true);
                startX = ev.getX();
                startY = ev.getY();
                break;

            case MotionEvent.ACTION_MOVE:
                float endX = ev.getX();
                float endY = ev.getY();
                float distanceX = endX - startX;
                float distanceY = endY - startY;

                // 判断滑动方向：水平滑动 vs 垂直滑动
                if (Math.abs(distanceX) > Math.abs(distanceY)) {
                    // 水平方向滑动
                    boolean allowParentIntercept = isAllowParentIntercept(distanceX);
                    // false = 禁止父拦截, true = 允许父拦截
                    getParent().requestDisallowInterceptTouchEvent(!allowParentIntercept);
                } else {
                    // 垂直方向滑动 → 禁止父容器拦截（让内部子View滚动）
                    getParent().requestDisallowInterceptTouchEvent(true);
                }
                break;

            case MotionEvent.ACTION_UP:
            case MotionEvent.ACTION_CANCEL:
                // 手指抬起或事件取消时，恢复父容器拦截权限（可选）
                break;
        }
        return super.dispatchTouchEvent(ev);
    }

    private boolean isAllowParentIntercept(float distanceX) {
        int currentItem = getCurrentItem();
        int lastItem = getAdapter() != null ? getAdapter().getCount() - 1 : 0;

        // 判断是否允许父容器拦截
        boolean allowParentIntercept;

        if (currentItem == 0 && distanceX > 0) {
            // 第一页 + 向右滑 → 允许父容器拦截（DrawerLayout拉出抽屉）
            allowParentIntercept = true;
        } else if (currentItem == lastItem && distanceX < 0) {
            // 最后一页 + 向左滑 → 禁止父容器拦截（ViewPager自己处理边缘效果）
            allowParentIntercept = false;
        } else {
            // 中间页面 → 禁止父容器拦截（ViewPager正常切换）
            allowParentIntercept = false;
        }
        return allowParentIntercept;
    }
}