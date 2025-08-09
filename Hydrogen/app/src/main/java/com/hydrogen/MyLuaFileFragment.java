package com.hydrogen;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentTransaction;
import androidx.lifecycle.ViewModel;
import androidx.lifecycle.ViewModelProvider;
import com.androlua.*;
import com.luajava.*;

import java.io.File;
import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.Map;


public class MyLuaFileFragment extends Fragment implements LuaGcable {

    public LuaState L;
    public FrameLayout mContainer;
    public LuaTable mlayoutTable;
    private int mContainerId;
    private LuaActivity mLuaActivity;
    private String mLuaFilePath;
    private boolean mGc;
    private LuaApplication app;
    private final Object[] mArgs;
    private ViewModel mVM;
    private HashMap<String, Object> mGlobal;

    public MyLuaFileFragment(String luaFilePath) {
        this(luaFilePath, new Object[0], new HashMap<String, Object>());
    }

    public MyLuaFileFragment(String luaFilePath, Object[] args, HashMap global) {
        mLuaFilePath = luaFilePath;
        mGlobal = global;
        mArgs = (args != null) ? args : new Object[0];
        mContainerId = R.id.fragment_container_view_tag;
        
    }

    public FrameLayout getContainer() {
        return mContainer;
    }

    public int getContainerId() {
        return mContainerId;
    }

    public void setContainerView(View v) {
        mContainer.addView(v);
    }

    @Override
    public void gc() {
        if (L != null) {
            LuaState activtyL = mLuaActivity.getLuaState();
            System.out.println("MyLuaFileFragment activityL" + activtyL);
            System.out.println("MyLuaFileFragment FragmentL" + L);
            L = null;
            try {
                activtyL.getLuaObject("luajava").getField("clear").getFunction().call(this);
                Field field = LuaState.class.getDeclaredField("javaObjectMap");
                field.setAccessible(true);
                HashMap<?, ?> mapObj = (HashMap<?, ?>) field.get(activtyL);
                mapObj.values().remove(this);
            } catch (Exception e) {
            }
        }
        System.gc();
        mGc = true;
    }

    @Override
    public boolean isGc() {
        return mGc;
    }

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        // 初始化一些变量
        mLuaActivity = (LuaActivity) getActivity();
        app = (LuaApplication) mLuaActivity.getApplication();
        if (mLuaFilePath.charAt(0) != '/') mLuaFilePath = mLuaActivity.getLuaDir() + "/" + mLuaFilePath;
        runFunc("onAttach", context);
        mContainer = new FrameLayout(mLuaActivity);
        mContainer.setLayoutParams(
                new ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        mContainer.setId(mContainerId);
        mVM = new ViewModelProvider(this).get(MyFragmentViewmodel.class);
        
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        try {
            initLua();
        } catch (Exception e) {
            mLuaActivity.sendError(this.toString(), e);
            return;
        }
        runFunc("onCreate", savedInstanceState);
    }

    @Override
    public View onCreateView(
            @NonNull LayoutInflater inflater,
            @Nullable ViewGroup container,
            @Nullable Bundle savedInstanceState) {
        super.onCreateView(inflater, container, savedInstanceState);
        Object result = runFunc("onCreateView", inflater, container, savedInstanceState);

        return mContainer;
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        // 当 Fragment 的视图已经创建时调用
        runFunc("onViewCreated", view, savedInstanceState);
        try {
            doFile(mLuaFilePath, mArgs);
        } catch (LuaException e) {
            mLuaActivity.sendError(this.toString(), e);
            return;
        }
    }

    @Override
    public void onStart() {
        super.onStart();
        // 当 Fragment 可见时调用
        runFunc("onStart");
    }

    @Override
    public void onResume() {
        super.onResume();
        // 当 Fragment 对用户可交互时调用
        runFunc("onResume");
    }

    @Override
    public void onPause() {
        super.onPause();
        // 当 Fragment 不再与用户交互时调用
        runFunc("onPause");
    }

    @Override
    public void onStop() {
        super.onStop();
        // 当 Fragment 不再可见时调用
        runFunc("onStop");
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        // 当与 Fragment 相关的视图被移除时调用
        runFunc("onDestroyView");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        // 当 Fragment 被销毁时调用
        runFunc("onDestroy");
        gc();
    }

    @Override
    public void onDetach() {
        super.onDetach();
        // 当 Fragment 从 Activity 中分离时调用
        runFunc("onDetach");
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        //requireActivity().getSupportFragmentManager().saveFragmentInstanceState(this);
        super.onSaveInstanceState(outState);
        // 保存 Fragment 的状态，以便在配置更改（如屏幕旋转）时恢复状态。
        runFunc("onSaveInstanceState", outState);
    }

    @Override
    public void onViewStateRestored(@Nullable Bundle savedInstanceState) {
        super.onViewStateRestored(savedInstanceState);
        // 在 Fragment 的视图状态被恢复后调用。
        runFunc("onViewStateRestored", savedInstanceState);
    }

    private void initLua() throws LuaException {
        String luaExtDir = app.getLuaExtDir();
        // String luaDir = app.getLocalDir();
        String luaDir = new File(mLuaFilePath).getParent();
        String luaLpath = app.getLuaLpath();
        String luaCpath = app.getLuaCpath();

        luaLpath = (luaDir + "/?.lua;" + luaDir + "/lua/?.lua;" + luaDir + "/?/init.lua;") + luaLpath;

        L = LuaStateFactory.newLuaState();
        L.openLibs();
        L.pushJavaObject(this);
        L.setGlobal("thisFragment");
        L.pushJavaObject(mLuaActivity);
        L.setGlobal("activity");
        L.getGlobal("activity");
        L.setGlobal("this");
        L.pushContext(mLuaActivity);
        L.getGlobal("luajava");
        L.pushString(luaExtDir);
        L.setField(-2, "luaextdir");
        L.pushString(luaDir);
        L.setField(-2, "luadir");
        L.pushString(mLuaFilePath);
        L.setField(-2, "luapath");
        L.pop(1);

        JavaFunction print = new LuaPrint(mLuaActivity, L);
        print.register("print");

        L.getGlobal("package");
        L.pushString(luaLpath);
        L.setField(-2, "path");
        L.pushString(luaCpath);
        L.setField(-2, "cpath");
        L.pop(1);

        for (Map.Entry<String, Object> entry : mGlobal.entrySet()) {
            String key = entry.getKey(); // 获取键
            Object value = entry.getValue(); // 获取值
            L.pushObjectValue(value);
            L.setGlobal(key);
        }

        new LuaSetFunction(L).register("set");
        new LuaCallFunction(L).register("call");

    }

    private void doFile(String filePath, Object... args) throws LuaException {
        L.setTop(0);
        int ok = L.LloadFile(filePath);

        if (ok == 0) {
            L.getGlobal("debug");
            L.getField(-1, "traceback");
            L.remove(-2);
            L.insert(-2);
            int l = args.length;
            for (Object arg : args) {
                L.pushObjectValue(arg);
            }
            ok = L.pcall(l, 1, -2 - l);
            if (ok == 0) {
                return;
            }
        }
        Intent res = new Intent();
        res.putExtra("data", L.toString(-1));
        getActivity().setResult(ok, res);
        throw new LuaException("Error: " + L.toString(-1));
    }

    // 用于从 Lua 脚本中调用以替换 Fragment 的方法，支持动画
    public void replaceFragment(int fragmentid, Object[] args) {
        try {
            FragmentManager fragmentManager = getParentFragmentManager();
            FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();

            // args[0] 到 args[3] 是动画资源 ID
            int enterAnim = (int) args[0];
            int exitAnim = (int) args[1];
            int popEnterAnim = (int) args[2];
            int popExitAnim = (int) args[3];

            fragmentTransaction.setCustomAnimations(enterAnim, exitAnim, popEnterAnim, popExitAnim);
            fragmentTransaction.replace(fragmentid, this);
            fragmentTransaction.commit();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // 用于在 Lua 环境中调用指定的函数
    // 运行 Lua 函数
    public Object runFunc(String funcName, Object... args) {
        if (L != null) {
            synchronized (L) {
                try {
                    L.setTop(0); // 重置堆栈
                    L.pushGlobalTable(); // 推全局表到堆栈
                    L.pushString(funcName); // 推函数名到堆栈
                    L.rawGet(-2); // 从全局表中获取函数

                    System.out.println("luatest" + L.isNil(-1));

                    if (L.isFunction(-1)) { // 检查是否为函数
                        L.getGlobal("debug");
                        L.getField(-1, "traceback"); // 获取调试信息
                        L.remove(-2);
                        L.insert(-2);

                        int l = args.length;
                        for (Object arg : args) {
                            L.pushObjectValue(arg); // 推参数到堆栈
                        }

                        int ok = L.pcall(l, 1, -2 - l); // 调用 Lua 函数
                        if (ok == 0) {
                            return L.toJavaObject(-1); // 返回结果
                        }
                        throw new LuaException(errorReason(ok) + ": " + L.toString(-1)); // 抛出异常
                    } else {
                        System.out.println(L.type(-1));
                    }
                } catch (LuaException e) {
                    sendError(funcName, e); // 发送错误信息
                }
            }
        }
        return null;
    }

    // 处理 Lua 错误原因
    private String errorReason(int error) {
        switch (error) {
            case 4:
                return "Out of memory";
            case 3:
                return "Syntax error";
            case 2:
                return "Runtime error";
            case 1:
                return "Yield error";
            default:
                return "Unknown error";
        }
    }

    // 发送错误信息
    private void sendError(String funcName, LuaException e) {
        System.err.println("Error in function '" + funcName + "': " + e.getMessage());
    }
}