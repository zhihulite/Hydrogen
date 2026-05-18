package com.hydrogen;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.provider.Settings;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import androidx.core.app.ActivityCompat;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import java.io.File;

public class RunActivity extends Activity {

    private static final int REQUEST_CODE_MANAGE_STORAGE = 1001;
    private static final int REQUEST_CODE_READ_STORAGE = 1002;

    private String luaPath;
    private String arg;
    private String name;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Intent intent = getIntent();
        luaPath = intent.getData() != null ? intent.getData().getPath() : null;
        arg = intent.getStringExtra("arg");
        name = intent.getStringExtra("name");

        String fileName = luaPath != null ? new File(luaPath).getName() : "未知";
        Toast.makeText(this, "即将执行「" + fileName + "」", Toast.LENGTH_LONG).show();

        runLua();
    }

    private void runLua() {
        try {
            if (luaPath == null || luaPath.isEmpty()) {
                showErrorAndExit("文件路径为空");
                return;
            }

            File file = new File(luaPath);
            if (!file.exists()) {
                showErrorAndExit("文件不存在: " + luaPath);
                return;
            }

            if (!file.canRead()) {
                requestStoragePermission();
                return;
            }

            startLuaActivity();

        } catch (Exception e) {
            showErrorAndExit("错误: " + e.getMessage());
        }
    }

    private void requestStoragePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ 需要管理全部文件权限
            if (!Environment.isExternalStorageManager()) {
                showManageStorageDialog();
            } else {
                showErrorAndExit("文件无法读取，请检查文件是否损坏");
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6-10 需要运行时权限
            if (checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE)
                    != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this,
                        new String[]{android.Manifest.permission.READ_EXTERNAL_STORAGE},
                        REQUEST_CODE_READ_STORAGE);
            } else {
                showErrorAndExit("文件无法读取，请检查文件是否损坏");
            }
        } else {
            // Android 5及以下
            showErrorAndExit("文件无法读取，请检查文件是否损坏");
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.R)
    private void showManageStorageDialog() {
        new MaterialAlertDialogBuilder(this)
                .setTitle("需要存储权限")
                .setMessage("调试Lua需要「管理全部文件」权限，请点击「去授权」并手动开启权限")
                .setPositiveButton("去授权", (d, w) -> {
                    Intent intent = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
                    intent.setData(Uri.parse("package:" + getPackageName()));
                    startActivityForResult(intent, REQUEST_CODE_MANAGE_STORAGE);
                })
                .setNegativeButton("取消", (d, w) -> showErrorAndExit("未获得存储权限，无法调试Lua"))
                .setCancelable(false)
                .show();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_CODE_READ_STORAGE) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                runLua();
            } else {
                showErrorAndExit("未获得存储权限，无法调试Lua");
            }
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_CODE_MANAGE_STORAGE) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                if (Environment.isExternalStorageManager()) {
                    runLua();
                } else {
                    showErrorAndExit("未获得「管理全部文件」权限，无法调试Lua");
                }
            }
        }
    }

    private void startLuaActivity() {
        Intent newIntent = new Intent(this, LuaActivity.class);
        newIntent.putExtra("arg", arg);
        newIntent.putExtra("name", name);
        newIntent.putExtra("luaPath", luaPath);
        newIntent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(newIntent);
        finish();
    }

    private void showErrorAndExit(String msg) {
        Toast.makeText(this, msg, Toast.LENGTH_LONG).show();
        new MaterialAlertDialogBuilder(this)
                .setTitle("无法调试Lua")
                .setMessage(msg)
                .setPositiveButton("确认", (d, w) -> finish())
                .setCancelable(false)
                .show();
    }
}