package com.hydrogen;

import androidx.recyclerview.widget.LinearLayoutManager;
import android.content.Context;
import android.util.AttributeSet;
import androidx.recyclerview.widget.RecyclerView;

public class MyLinearLayoutManager extends LinearLayoutManager {
    public MyLinearLayoutManager(Context context) {
        super( context );
    }

    public MyLinearLayoutManager(Context context, int orientation, boolean reverseLayout) {
        super( context, orientation, reverseLayout );
    }

    public MyLinearLayoutManager(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super( context, attrs, defStyleAttr, defStyleRes );
    }

    @Override
    public void onLayoutChildren(RecyclerView.Recycler recycler, RecyclerView.State state) {
        try {
            super.onLayoutChildren( recycler, state );
        } catch (IndexOutOfBoundsException e) {
            e.printStackTrace();
        }

    }
}