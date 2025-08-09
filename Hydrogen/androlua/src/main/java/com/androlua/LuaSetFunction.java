package com.androlua;

import com.luajava.*;

public class LuaSetFunction extends JavaFunction {
    LuaState L;
    public LuaSetFunction(LuaState L) {
        super(L);
        L=L;
    }

    @Override
    public int execute() {
        LuaThread thread = (LuaThread) L.toJavaObject(2);
        thread.set(L.toString(3), L.toJavaObject(4));
        return 0;
    }
}