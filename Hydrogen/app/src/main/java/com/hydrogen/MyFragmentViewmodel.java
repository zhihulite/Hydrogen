package com.hydrogen;
import android.view.View;
import androidx.lifecycle.ViewModel;
import java.util.HashMap;

public class MyFragmentViewmodel extends ViewModel {
    String mLuaFilePath;
    HashMap mGlobal;
    Object[] mArgs;
    View cachedContentView;
    boolean luaFileLoaded;
    
    public MyFragmentViewmodel() {
        
    }
}
