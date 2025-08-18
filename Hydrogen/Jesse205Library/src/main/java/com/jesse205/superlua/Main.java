package com.jesse205.superlua;

import android.annotation.SuppressLint;
import android.os.Bundle;
import androidx.core.splashscreen.SplashScreen;


public class Main extends LuaActivity {

	@SuppressLint("SuspiciousIndentation")
	@Override
	public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
	    setCheckUpdate(true);
		if (getIntent().getBooleanExtra("isVersionChanged", false) && (savedInstanceState == null)) {
			onVersionChanged(getIntent().getStringExtra("newVersionName"), getIntent().getStringExtra("oldVersionName"));
		}
	}

	private void onVersionChanged(String newVersionName, String oldVersionName) {
		// TODO: Implement this method
		runFunc("onVersionChanged", newVersionName, oldVersionName);
	}

	@Override
	public String getLuaPath() {
		String path;
		if (updating) {
			path = "/";
		} else {
			path = getLocalDir() + "/main.lua";
		}
		applyLuaDir(path);
		return path;
	}
}
