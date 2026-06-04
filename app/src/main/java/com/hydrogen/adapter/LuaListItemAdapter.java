package com.hydrogen.adapter;

import android.content.Context;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.androlua.LuaActivity;
import com.google.android.material.listitem.ListItemLayout;
import com.google.android.material.listitem.ListItemViewHolder;
import com.google.android.material.textview.MaterialTextView;
import com.luajava.LuaTable;

import java.util.Objects;

@SuppressWarnings("unused")
public class LuaListItemAdapter extends RecyclerView.Adapter<LuaListItemAdapter.LuaListItemHolder> {

    private final LuaActivity mContext;
    private final Creator adapterCreator;

    public LuaListItemAdapter(LuaActivity mContext, Creator adapterCreator) {
        this.mContext = mContext;
        this.adapterCreator = adapterCreator;
    }

    public LuaListItemAdapter(Creator adapterCreator) {
        this(null, adapterCreator);
    }

    @Override
    public int getItemCount() {
        try {
            return adapterCreator.getItemCount();
        } catch (Exception e) {
            if (mContext != null) mContext.sendError("getItemCount", e);
            return 0;
        }
    }

    @Override
    public int getItemViewType(int position) {
        try {
            return (int) adapterCreator.getItemViewType(position);
        } catch (Exception e) {
            if (mContext != null) mContext.sendError("getItemViewType", e);
            return -1;
        }
    }

    @Override
    public void onBindViewHolder(@NonNull LuaListItemHolder holder, int position) {
        try {
            adapterCreator.onBindViewHolder(holder, position);
        } catch (Exception e) {
            if (mContext != null) mContext.sendError("onBindViewHolder", e);
        }
    }

    @NonNull
    @Override
    public LuaListItemHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        try {
            LuaListItemHolder holder = adapterCreator.onCreateViewHolder(parent, viewType);
            return Objects.requireNonNull(holder);
        } catch (Exception e) {
            if (mContext != null) mContext.sendError("onCreateViewHolder", e);
            Context context = mContext != null ? mContext : parent.getContext();
            // 创建一个 ListItemLayout 作为根布局
            ListItemLayout errorLayout = new ListItemLayout(context);
            // 创建一个显示错误的 TextView
            MaterialTextView errorView = new MaterialTextView(context);
            errorView.setText("Adapter Error: " + e.getMessage());
            errorView.setPadding(16, 16, 16, 16);
            errorView.setTextColor(0xFFFF0000);
            errorView.setDuplicateParentStateEnabled(true);

            // 添加到 ListItemLayout
            errorLayout.addView(errorView, new ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT));

            return new LuaListItemHolder(errorLayout);
        }
    }

    @Override
    public void onViewRecycled(@NonNull LuaListItemHolder holder) {
        try {
            adapterCreator.onViewRecycled(holder);
        } catch (Exception e) {
            if (mContext != null) mContext.sendError("onViewRecycled", e);
        }
    }

    public interface Creator {
        int getItemCount();
        long getItemViewType(int position);
        void onBindViewHolder(LuaListItemHolder holder, int position);
        LuaListItemHolder onCreateViewHolder(ViewGroup parent, int viewType);
        void onViewRecycled(LuaListItemHolder holder);
    }

    public static class LuaListItemHolder extends ListItemViewHolder {

        public LuaTable views = null;

        public LuaListItemHolder(@NonNull View itemView) {
            super(itemView);
        }

        public void setViews(LuaTable views) {
            this.views = views;
        }

        public LuaTable getViews() {
            return views;
        }
    }
}