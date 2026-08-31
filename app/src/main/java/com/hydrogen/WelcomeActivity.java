package com.hydrogen;

import android.os.Bundle;
import android.view.View;

import androidx.activity.EdgeToEdge;
import androidx.core.splashscreen.SplashScreen;

import org.luajvm.android.host.Welcome;
import com.zhihu.hydrogen.x.R;

public class WelcomeActivity extends Welcome {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        SplashScreen.installSplashScreen(this);
        EdgeToEdge.enable(this);
        super.onCreate(savedInstanceState);
    }

    @Override
    protected View createContentView() {
        return getLayoutInflater().inflate(R.layout.layout_welcome, null, false);
    }

    @Override
    protected Class<?> getTargetActivity() {
        return MainActivity.class;
    }

    @Override
    protected long getMinDisplayTimeMillis() {
        return 800;
    }
}
