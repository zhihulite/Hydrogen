package com.hydrogen;

import android.content.Context;
import android.util.AttributeSet;
import android.util.Log;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

@SuppressWarnings("unused")
public class SafeLinearLayoutManager extends LinearLayoutManager {

    private static final String TAG = "SafeLinearLayoutManager";

    public SafeLinearLayoutManager(Context context) {
        super(context);
    }

    public SafeLinearLayoutManager(Context context, int orientation, boolean reverseLayout) {
        super(context, orientation, reverseLayout);
    }

    public SafeLinearLayoutManager(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    @Override
    public void onLayoutChildren(RecyclerView.Recycler recycler, RecyclerView.State state) {
        try {
            super.onLayoutChildren(recycler, state);
        } catch (IndexOutOfBoundsException e) {
            Log.e(TAG, "onLayoutChildren failed", e);
        }
    }
}
