package com.hydrogen;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;
import android.view.ViewGroup;

import com.google.android.material.chip.ChipGroup;

/**
 * 修复 FlowLayout 的组高度问题：单行内组高度取行内最后一个子项的高度而非最高者。
 * 行内靠前的 Chip 更高时（CJK 文本行高可超过 chipMinHeight），组高度不足，
 * 超出部分连同底描边被裁剪。onMeasure 在父类结果之上按逐行最大子项高度修正。
 */
@SuppressWarnings("unused")
public class FixedChipGroup extends ChipGroup {

    public FixedChipGroup(Context context) {
        super(context);
    }

    public FixedChipGroup(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public FixedChipGroup(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
        int heightMode = MeasureSpec.getMode(heightMeasureSpec);
        // EXACTLY 下组高度由外部决定，无从修正
        if (heightMode == MeasureSpec.EXACTLY) {
            return;
        }
        int contentHeight = computeFlowContentHeight(widthMeasureSpec);
        if (contentHeight > getMeasuredHeight()) {
            int height = heightMode == MeasureSpec.AT_MOST
                    ? Math.min(contentHeight, MeasureSpec.getSize(heightMeasureSpec))
                    : contentHeight;
            setMeasuredDimension(getMeasuredWidth(), height);
        }
    }

    /**
     * 与 FlowLayout.onMeasure 同构的换行模拟，行高取该行子项的最大值。
     * 子项的测量结果来自父类 onMeasure，进入本方法时均已就绪。
     */
    private int computeFlowContentHeight(int widthMeasureSpec) {
        int widthMode = MeasureSpec.getMode(widthMeasureSpec);
        int width = MeasureSpec.getSize(widthMeasureSpec);
        int maxWidth = widthMode == MeasureSpec.AT_MOST || widthMode == MeasureSpec.EXACTLY
                ? width : Integer.MAX_VALUE;
        int maxRight = maxWidth - getPaddingRight();

        int childLeft = getPaddingLeft();
        int childTop = getPaddingTop();
        int childBottom = childTop;
        for (int i = 0; i < getChildCount(); i++) {
            View child = getChildAt(i);
            if (child.getVisibility() == View.GONE) {
                continue;
            }
            int leftMargin = 0;
            int rightMargin = 0;
            ViewGroup.LayoutParams lp = child.getLayoutParams();
            if (lp instanceof ViewGroup.MarginLayoutParams) {
                ViewGroup.MarginLayoutParams marginLp = (ViewGroup.MarginLayoutParams) lp;
                leftMargin = marginLp.leftMargin;
                rightMargin = marginLp.rightMargin;
            }
            int childRight = childLeft + leftMargin + child.getMeasuredWidth();
            if (childRight > maxRight && !isSingleLine()) {
                childLeft = getPaddingLeft();
                childTop = childBottom + getLineSpacing();
            }
            childRight = childLeft + leftMargin + child.getMeasuredWidth();
            // FlowLayout 此处取当前子项高度，行末是矮子项时行高被低估
            childBottom = Math.max(childBottom, childTop + child.getMeasuredHeight());
            childLeft += leftMargin + rightMargin + child.getMeasuredWidth() + getItemSpacing();
        }
        return childBottom + getPaddingBottom();
    }
}
