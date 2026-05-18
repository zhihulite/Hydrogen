package com.hydrogen.adapter;

import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

public class LuaPager2Adapter extends RecyclerView.Adapter<LuaPager2Adapter.ViewHolder> {
    private final List<View> views = new CopyOnWriteArrayList<>();
    private final List<String> titles = new CopyOnWriteArrayList<>();
    private static final String DEFAULT_TITLE = "No Title";

    public void add(View view, String title) {
        views.add(view);
        titles.add(title != null ? title : DEFAULT_TITLE);
        notifyItemInserted(views.size() - 1);
    }

    public void add(int position, View view, String title) {
        views.add(position, view);
        titles.add(position, title != null ? title : DEFAULT_TITLE);
        notifyItemInserted(position);
    }

    public void add(View view) {
        views.add(view);
        titles.add(DEFAULT_TITLE);
        notifyItemInserted(views.size() - 1);
    }

    public void add(int position, View view) {
        views.add(position, view);
        titles.add(position, DEFAULT_TITLE);
        notifyItemInserted(position);
    }

    public void remove(int position) {
        views.remove(position);
        titles.remove(position);
        notifyItemRemoved(position);
    }

    public boolean remove(View view) {
        int index = views.indexOf(view);
        if (index != -1) {
            views.remove(index);
            titles.remove(index);
            notifyItemRemoved(index);
            return true;
        }
        return false;
    }

    public View getItem(int position) {
        if (position >= 0 && position < views.size()) {
            return views.get(position);
        }
        return null;
    }

    public String getTitle(int position) {
        if (position >= 0 && position < titles.size()) {
            return titles.get(position);
        }
        return DEFAULT_TITLE;
    }

    public List<View> getData() {
        return views;
    }

    public List<String> getTitles() {
        return titles;
    }

    public void clear() {
        int size = views.size();
        views.clear();
        titles.clear();
        notifyItemRangeRemoved(0, size);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        FrameLayout container = new FrameLayout(parent.getContext());
        ViewGroup.LayoutParams params = new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
        );
        container.setLayoutParams(params);
        return new ViewHolder(container);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        try {
            View view = views.get(position);
            FrameLayout container = (FrameLayout) holder.container;

            // 避免重复添加同一个 View
            if (container.getChildCount() == 1 && container.getChildAt(0) == view) {
                return;
            }

            container.removeAllViews();
            if (view.getParent() != null) {
                ((ViewGroup) view.getParent()).removeView(view);
            }
            container.addView(view);
        } catch (Exception e) {
            FrameLayout container = (FrameLayout) holder.container;
            container.removeAllViews();
            TextView errorView = new TextView(container.getContext());
            errorView.setText("Error: " + e.getMessage());
            errorView.setTextColor(0xFFFF0000);
            container.addView(errorView);
        }
    }

    @Override
    public int getItemCount() {
        return views.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        public final View container;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            this.container = itemView;
        }
    }
}