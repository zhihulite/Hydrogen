package com.hydrogen.adapter;

import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.androlua.LuaActivity;
import com.google.android.material.textview.MaterialTextView;
import com.luajava.LuaTable;

import java.util.Objects;

@SuppressWarnings("unused")
public class LuaCustRecyclerAdapter extends RecyclerView.Adapter<LuaCustRecyclerAdapter.LuaCustRecyclerHolder> {

    private LuaActivity mContext;
    private Creator adapterCreator;

    public LuaCustRecyclerAdapter(LuaActivity mContext, Creator adapterCreator) {
        this.mContext = mContext;
        this.adapterCreator = adapterCreator;
    }

    public LuaCustRecyclerAdapter(Creator adapterCreator) {
        this(null, adapterCreator);
    }

    @Override
    public int getItemCount() {
        try {
            return adapterCreator.getItemCount();
        } catch (Exception e) {
            if (mContext != null) {
                mContext.sendError("RecyclerAdapter: getItemCount", e);
            }
            return 0;
        }
    }

    @Override
    public int getItemViewType(int position) {
        try {
            return (int) adapterCreator.getItemViewType(position);
        } catch (Exception e) {
            if (mContext != null) {
                mContext.sendError("RecyclerAdapter: getItemViewType", e);
            }
            return -1;
        }
    }

    @Override
    public void onBindViewHolder(@NonNull LuaCustRecyclerHolder holder, int position) {
        try {
            adapterCreator.onBindViewHolder(holder, position);
        } catch (Exception e) {
            if (mContext != null) {
                mContext.sendError("RecyclerAdapter: onBindViewHolder", e);
            }
        }
    }

    @NonNull
    @Override
    public LuaCustRecyclerHolder onCreateViewHolder(@NonNull ViewGroup viewGroup, int viewType) {
        try {
            LuaCustRecyclerHolder holder = adapterCreator.onCreateViewHolder(viewGroup, viewType);
            return Objects.requireNonNull(holder, "onCreateViewHolder returned null");
        } catch (Exception e) {
            if (mContext != null) {
                mContext.sendError("RecyclerAdapter: onCreateViewHolder", e);
            }
            MaterialTextView errorView = new MaterialTextView(mContext != null ? mContext : viewGroup.getContext());
            errorView.setText("Adapter Error: " + e.getMessage());
            errorView.setPadding(16, 16, 16, 16);
            errorView.setTextColor(0xFFFF0000);
            return new LuaCustRecyclerHolder(errorView);
        }
    }

    @Override
    public void onViewRecycled(@NonNull LuaCustRecyclerHolder holder) {
        try {
            adapterCreator.onViewRecycled(holder);
        } catch (Exception e) {
            if (mContext != null) {
                mContext.sendError("RecyclerAdapter: onViewRecycled", e);
            }
        }
    }

    // Getter 方法
    public LuaActivity getContext() {
        return mContext;
    }

    public void setContext(LuaActivity mContext) {
        this.mContext = mContext;
    }

    public Creator getAdapterCreator() {
        return adapterCreator;
    }

    public void setAdapterCreator(Creator adapterCreator) {
        this.adapterCreator = adapterCreator;
    }

    // Creator 接口
    public interface Creator {
        int getItemCount();
        long getItemViewType(int position);
        void onBindViewHolder(LuaCustRecyclerHolder viewHolder, int position);
        LuaCustRecyclerHolder onCreateViewHolder(ViewGroup viewGroup, int viewType);
        void onViewRecycled(LuaCustRecyclerHolder viewHolder);
    }

    public static class LuaCustRecyclerHolder extends RecyclerView.ViewHolder {
        public LuaCustRecyclerHolder(@NonNull View itemView) {
            super(itemView);
        }

        public LuaTable Tag = null;

        public void setViews(LuaTable tag) {
            Tag = tag;
        }

        public LuaTable getViews() {
            return Tag;
        }
    }
}


