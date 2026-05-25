package com.hydrogen;

import android.content.Context;
import com.bumptech.glide.GlideBuilder;
import com.bumptech.glide.annotation.GlideModule;
import com.bumptech.glide.load.engine.cache.InternalCacheDiskCacheFactory;
import com.bumptech.glide.module.AppGlideModule;
import org.jspecify.annotations.NonNull;

@GlideModule
public class MyAppGlideModule extends AppGlideModule {
    @Override
    public void applyOptions(@NonNull Context context, GlideBuilder builder) {
        // 磁盘缓存：50MB
        int diskCacheSize = 50 * 1024 * 1024;
        builder.setDiskCache(new InternalCacheDiskCacheFactory(context, diskCacheSize));
    }

    @Override
    public boolean isManifestParsingEnabled() {
        return false;
    }
}