package com.hydrogen.adapter;

import android.util.SparseArray;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.viewpager.widget.PagerAdapter;
import java.util.ArrayList;
import java.util.List;

public final class LuaPagerAdapter extends PagerAdapter {
    private final List<View> pagerViews = new ArrayList<>();
    private final List<String> titles = new ArrayList<>();
    private final SparseArray<View> positionCache = new SparseArray<>();
    private static final String DEFAULT_TITLE = "No Title";

    @Override
    public int getCount() {
        return pagerViews.size();
    }

    @Override
    public boolean isViewFromObject(@NonNull View view, @NonNull Object object) {
        return view == object;
    }

    @NonNull
    @Override
    public Object instantiateItem(@NonNull ViewGroup container, int position) {
        View view = pagerViews.get(position);
        if (view.getParent() != null) {
            ((ViewGroup) view.getParent()).removeView(view);
        }
        container.addView(view);
        positionCache.put(position, view);
        return view;
    }

    @Override
    public void destroyItem(@NonNull ViewGroup container, int position, @NonNull Object object) {
        container.removeView((View) object);
        positionCache.remove(position);
    }

    @Override
    public CharSequence getPageTitle(int position) {
        if (position >= 0 && position < titles.size()) {
            String title = titles.get(position);
            return title != null ? title : DEFAULT_TITLE;
        }
        return DEFAULT_TITLE;
    }

    @Override
    public int getItemPosition(@NonNull Object object) {
        int index = positionCache.indexOfValue((View) object);
        return index == -1 ? POSITION_NONE : POSITION_UNCHANGED;
    }

    public void add(View view) {
        pagerViews.add(view);
        titles.add(DEFAULT_TITLE);
        notifyDataSetChanged();
    }

    public void add(View view, String title) {
        pagerViews.add(view);
        titles.add(title != null ? title : DEFAULT_TITLE);
        notifyDataSetChanged();
    }

    public void add(int position, View view) {
        if (position >= 0 && position <= pagerViews.size()) {
            pagerViews.add(position, view);
            titles.add(position, DEFAULT_TITLE);
            rebuildCache();
            notifyDataSetChanged();
        }
    }

    public void add(int position, View view, String title) {
        if (position >= 0 && position <= pagerViews.size()) {
            pagerViews.add(position, view);
            titles.add(position, title != null ? title : DEFAULT_TITLE);
            rebuildCache();
            notifyDataSetChanged();
        }
    }

    public void set(int index, View view) {
        if (index >= 0 && index < pagerViews.size()) {
            pagerViews.set(index, view);
            rebuildCache();
            notifyDataSetChanged();
        }
    }

    public void set(int index, View view, String title) {
        if (index >= 0 && index < pagerViews.size()) {
            pagerViews.set(index, view);
            titles.set(index, title != null ? title : DEFAULT_TITLE);
            rebuildCache();
            notifyDataSetChanged();
        }
    }

    public void remove(int index) {
        if (index >= 0 && index < pagerViews.size()) {
            pagerViews.remove(index);
            if (index < titles.size()) {
                titles.remove(index);
            }
            rebuildCache();
            notifyDataSetChanged();
        }
    }

    public void remove(View view) {
        int index = pagerViews.indexOf(view);
        if (index != -1) {
            remove(index);
        }
    }

    public void clear() {
        pagerViews.clear();
        titles.clear();
        positionCache.clear();
        notifyDataSetChanged();
    }

    private void rebuildCache() {
        positionCache.clear();
        for (int i = 0; i < pagerViews.size(); i++) {
            positionCache.put(i, pagerViews.get(i));
        }
    }
}