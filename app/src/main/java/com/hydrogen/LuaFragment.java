package com.hydrogen;

import android.content.Context;
import android.os.Bundle;
import android.util.Log;
import android.view.ContextMenu;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import com.google.android.material.textview.MaterialTextView;

public class LuaFragment extends Fragment {

    private static final String TAG = "LuaFragment";

    private Creator creator;
    public Bundle savedState;

    public LuaFragment() {
        this(null);
    }

    public LuaFragment(Creator creator) {
        this.creator = creator;
        this.savedState = null;
    }

    public static LuaFragment newInstance(Creator creator) {
        LuaFragment fragment = new LuaFragment();
        fragment.creator = creator;
        return fragment;
    }

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        if (creator != null) {
            creator.onAttach(context);
        }
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (creator != null) {
            creator.onCreate(savedInstanceState);
        }
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        try {
            if (creator != null) {
                View view = creator.onCreateView(inflater, container, savedInstanceState);
                if (view != null) {
                    return view;
                }
            }
        } catch (Throwable e) {
            Log.e(TAG, "onCreateView error", e);

            // 创建错误提示视图
            MaterialTextView errorView = new MaterialTextView(requireContext());
            errorView.setText("onCreateView error: " + e.getMessage());
            errorView.setTextColor(0xFFFF0000);
            errorView.setPadding(16, 16, 16, 16);
            return errorView;
        }

        // 默认视图
        MaterialTextView defaultView = new MaterialTextView(requireContext());
        defaultView.setText("creator is null or view is null");
        return defaultView;
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        if (creator != null) {
            creator.onViewCreated(view, savedInstanceState);
        }
    }

    @Deprecated
    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        if (creator != null) {
            creator.onActivityCreated(savedInstanceState);
        }
    }

    @Override
    public void onStart() {
        super.onStart();
        if (creator != null) {
            creator.onStart();
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        if (creator != null) {
            creator.onResume();
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        if (creator != null) {
            creator.onPause();
        }
    }

    @Override
    public void onStop() {
        super.onStop();
        if (creator != null) {
            creator.onStop();
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        if (creator != null) {
            creator.onDestroyView();
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (creator != null) {
            creator.onDestroy();
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        if (creator != null) {
            creator.onDetach();
        }
    }

    @Override
    public void onCreateContextMenu(@NonNull ContextMenu menu, @NonNull View v, @Nullable ContextMenu.ContextMenuInfo menuInfo) {
        super.onCreateContextMenu(menu, v, menuInfo);
        if (creator != null) {
            creator.onCreateContextMenu(menu, v, menuInfo);
        }
    }

    @Override
    public boolean onContextItemSelected(@NonNull MenuItem item) {
        super.onContextItemSelected(item);
        if (creator != null) {
            return creator.onContextItemSelected(item);
        }
        return false;
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        if (creator != null) {
            creator.onSaveInstanceState(outState);
        }
    }

    @Override
    public void onViewStateRestored(@Nullable Bundle savedInstanceState) {
        super.onViewStateRestored(savedInstanceState);
        if (creator != null) {
            creator.onViewStateRestored(savedInstanceState);
        }
    }

    // Getter 和 Setter
    public Creator getCreator() {
        return creator;
    }

    public void setCreator(Creator creator) {
        this.creator = creator;
    }

    public Bundle getSavedState() {
        return savedState;
    }

    public void setSavedState(Bundle savedState) {
        this.savedState = savedState;
    }

    // Creator 接口
    public interface Creator {
        void onAttach(Context context);
        void onCreate(@Nullable Bundle savedInstanceState);
        @Nullable
        View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState);
        void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState);
        void onActivityCreated(@Nullable Bundle savedInstanceState);
        void onStart();
        void onResume();
        void onPause();
        void onStop();
        void onDestroyView();
        void onDestroy();
        void onDetach();
        void onSaveInstanceState(@NonNull Bundle outState);
        void onViewStateRestored(@Nullable Bundle savedInstanceState);
        boolean onContextItemSelected(@NonNull MenuItem item);
        void onCreateContextMenu(@NonNull ContextMenu menu, @NonNull View v, @Nullable ContextMenu.ContextMenuInfo menuInfo);
    }
}