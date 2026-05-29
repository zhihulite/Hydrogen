package com.hydrogen;

import android.annotation.SuppressLint;
import android.os.Bundle;


public class MainActivity extends LuaActivity {

    @SuppressLint("SuspiciousIndentation")
    @Override
    public void onCreate(Bundle savedInstanceState) {
        setCheckUpdate(true);
        if (getIntent().getBooleanExtra("isVersionChanged", false) && (savedInstanceState == null)) {
            onVersionChanged(getIntent().getStringExtra("newVersionName"), getIntent().getStringExtra("oldVersionName"));
        }
        super.onCreate(savedInstanceState);
    }

    private void onVersionChanged(String newVersionName, String oldVersionName) {
        // TODO: Implement this method
        runFunc("onVersionChanged", newVersionName, oldVersionName);
    }

    @Override
    public String getFallbackLuaPath() {
        return getLocalDir() + "/main.lua";
    }
}