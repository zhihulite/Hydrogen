package com.hydrogen;
import androidx.lifecycle.ViewModel;
import java.util.HashMap;

public class MyFragmentViewmodel extends ViewModel {
    String mLuaFilePath;
    HashMap mGlobal;
    Object[] mArgs;
    
    public MyFragmentViewmodel() {
        
    }
}
