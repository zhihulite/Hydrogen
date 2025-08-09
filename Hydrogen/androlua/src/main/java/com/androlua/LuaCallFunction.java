package com.androlua;

import com.luajava.*;

public class LuaCallFunction extends JavaFunction {
    LuaState L;
    public LuaCallFunction(LuaState L) {
        super(L);
        L=L;
    }

    @Override
    public int execute() {
        LuaThread thread = (LuaThread) L.toJavaObject(2);
        int top = L.getTop();
        if (top > 3) {
            Object[] args = new Object[top - 3];
            for (int i = 4; i <= top; i++) {
                args[i - 4] = L.toJavaObject(i);
            }
            thread.call(L.toString(3), args);
        } else if (top == 3) {
            thread.call(L.toString(3));
        }
        return 0;
    }
}
