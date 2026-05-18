package com.hydrogen.adapter;

import androidx.fragment.app.Fragment;
import androidx.viewpager2.adapter.FragmentStateAdapter;
import com.androlua.LuaActivity;
import org.jspecify.annotations.NonNull;

public class LuaFragmentAdapter extends FragmentStateAdapter {

    private Creator creator;
    private final LuaActivity mContext;

    public LuaFragmentAdapter(LuaActivity context, Creator inter) {
        super(context.getSupportFragmentManager(), context.getLifecycle());
        this.mContext = context;
        this.creator = inter;
    }

    @Override
    public @NonNull Fragment createFragment(int position) {
        try {
            return creator.createFragment(position);
        } catch (Exception e) {
            mContext.sendError("FragmentAdapter", e);
            return new Fragment();
        }
    }

    @Override
    public int getItemCount() {
        try {
            return creator.getItemCount();
        } catch (Exception e) {
            mContext.sendError("FragmentAdapter", e);
            return 0;
        }
    }

    // Getter 和 Setter 方法
    public Creator getCreator() {
        return creator;
    }

    public void setCreator(Creator creator) {
        this.creator = creator;
    }

    public LuaActivity getContext() {
        return mContext;
    }

    // Creator 接口
    public interface Creator {
        Fragment createFragment(int position);
        int getItemCount();
    }
}