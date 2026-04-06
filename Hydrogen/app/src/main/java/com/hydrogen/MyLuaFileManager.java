package com.hydrogen;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;
import android.view.View;

import androidx.annotation.Nullable;

import com.google.android.material.card.MaterialCardView;
import com.google.android.material.shape.ShapeAppearanceModel;

import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

public final class MyLuaFileManager {

    private static final String SP_NAME = "my_lua_fragment_registry";
    private static final String KEY_TYPE_PREFIX = "type_";
    private static final String KEY_CONTAINER_ID_PREFIX = "container_id_";
    private static final String KEY_LUA_PATH_PREFIX = "lua_path_";
    private static final ConcurrentHashMap<String, FragmentRecord> RECORDS = new ConcurrentHashMap<>();

    private static volatile SharedPreferences sharedPreferences;

    private MyLuaFileManager() {
    }

    public static void init(Context context) {
        if (sharedPreferences == null && context != null) {
            synchronized (MyLuaFileManager.class) {
                if (sharedPreferences == null) {
                    sharedPreferences = context.getApplicationContext()
                            .getSharedPreferences(SP_NAME, Context.MODE_PRIVATE);
                }
            }
        }
    }

    public static String createFragmentId() {
        return UUID.randomUUID().toString();
    }

    public static void registerFragment(
            String fragmentId,
            @Nullable MyLuaFileFragment fragment,
            @Nullable MaterialCardView container,
            @Nullable String type,
            int containerId,
            @Nullable String luaPath
    ) {
        if (TextUtils.isEmpty(fragmentId)) {
            return;
        }
        RECORDS.put(fragmentId, new FragmentRecord(fragment, container, type, containerId, luaPath));
        SharedPreferences sp = sharedPreferences;
        if (sp != null) {
            SharedPreferences.Editor editor = sp.edit();
            editor.putString(KEY_TYPE_PREFIX + fragmentId, type);
            editor.putInt(KEY_CONTAINER_ID_PREFIX + fragmentId, containerId);
            editor.putString(KEY_LUA_PATH_PREFIX + fragmentId, luaPath);
            editor.apply();
        }
    }

    public static void unregisterFragment(String fragmentId) {
        if (TextUtils.isEmpty(fragmentId)) {
            return;
        }
        RECORDS.remove(fragmentId);
        SharedPreferences sp = sharedPreferences;
        if (sp != null) {
            SharedPreferences.Editor editor = sp.edit();
            editor.remove(KEY_TYPE_PREFIX + fragmentId);
            editor.remove(KEY_CONTAINER_ID_PREFIX + fragmentId);
            editor.remove(KEY_LUA_PATH_PREFIX + fragmentId);
            editor.apply();
        }
    }

    @Nullable
    public static MyLuaFileFragment getFragment(String fragmentId) {
        FragmentRecord record = RECORDS.get(fragmentId);
        return record != null ? record.fragment : null;
    }

    @Nullable
    public static MaterialCardView getContainer(String fragmentId) {
        FragmentRecord record = RECORDS.get(fragmentId);
        return record != null ? record.container : null;
    }

    public static int getContainerId(String fragmentId) {
        FragmentRecord record = RECORDS.get(fragmentId);
        if (record != null) {
            return record.containerId;
        }
        SharedPreferences sp = sharedPreferences;
        if (sp != null) {
            return sp.getInt(KEY_CONTAINER_ID_PREFIX + fragmentId, View.NO_ID);
        }
        return View.NO_ID;
    }

    @Nullable
    public static String getType(String fragmentId) {
        FragmentRecord record = RECORDS.get(fragmentId);
        if (record != null) {
            return record.type;
        }
        SharedPreferences sp = sharedPreferences;
        if (sp != null) {
            return sp.getString(KEY_TYPE_PREFIX + fragmentId, null);
        }
        return null;
    }

    @Nullable
    public static String getLuaPath(String fragmentId) {
        FragmentRecord record = RECORDS.get(fragmentId);
        if (record != null) {
            return record.luaPath;
        }
        SharedPreferences sp = sharedPreferences;
        if (sp != null) {
            return sp.getString(KEY_LUA_PATH_PREFIX + fragmentId, null);
        }
        return null;
    }

    public static void updateContainerCornerRadii(
            String fragmentId,
            float topLeft,
            float topRight,
            float bottomRight,
            float bottomLeft
    ) {
        MaterialCardView container = getContainer(fragmentId);
        if (container == null) {
            return;
        }
        ShapeAppearanceModel currentModel = container.getShapeAppearanceModel();
        ShapeAppearanceModel newModel = currentModel.toBuilder()
                .setTopLeftCornerSize(topLeft)
                .setTopRightCornerSize(topRight)
                .setBottomRightCornerSize(bottomRight)
                .setBottomLeftCornerSize(bottomLeft)
                .build();
        container.setShapeAppearanceModel(newModel);
    }

    public static final class FragmentRecord {
        @Nullable
        public final MyLuaFileFragment fragment;
        @Nullable
        public final MaterialCardView container;
        @Nullable
        public final String type;
        public final int containerId;
        @Nullable
        public final String luaPath;

        FragmentRecord(
                @Nullable MyLuaFileFragment fragment,
                @Nullable MaterialCardView container,
                @Nullable String type,
                int containerId,
                @Nullable String luaPath
        ) {
            this.fragment = fragment;
            this.container = container;
            this.type = type;
            this.containerId = containerId;
            this.luaPath = luaPath;
        }
    }
}
