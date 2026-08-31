package com.hydrogen;

import android.os.Bundle;

public class MainActivity extends LuaActivity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    protected void onVersionChanged(String newVersionName, String oldVersionName) {
        runFunc("onVersionChanged", newVersionName, oldVersionName);
    }

}
