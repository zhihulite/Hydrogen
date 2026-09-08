package com.hydrogen.theme;

import android.app.Activity;
import android.content.Context;

import com.google.android.material.color.ColorResourcesOverride;
import com.google.android.material.color.DynamicColors;
import com.google.android.material.color.DynamicColorsOptions;
import com.google.android.material.color.utilities.DynamicColor;
import com.google.android.material.color.utilities.DynamicScheme;
import com.google.android.material.color.utilities.Hct;
import com.google.android.material.color.utilities.MaterialDynamicColors;
import com.google.android.material.color.utilities.SchemeContent;
import com.google.android.material.color.utilities.SchemeExpressive;
import com.google.android.material.color.utilities.SchemeFidelity;
import com.google.android.material.color.utilities.SchemeFruitSalad;
import com.google.android.material.color.utilities.SchemeMonochrome;
import com.google.android.material.color.utilities.SchemeNeutral;
import com.google.android.material.color.utilities.SchemeRainbow;
import com.google.android.material.color.utilities.SchemeTonalSpot;
import com.google.android.material.color.utilities.SchemeVibrant;

import java.util.HashMap;
import java.util.Map;

/**
 * 主题取色入口。种子色生成方案与 Builder 链放 Java 侧：
 * DynamicColorsOptions 与 Scheme 类的构造经 Lua 分派有重载歧义，
 * Lua 只调本类的无歧义静态方法。
 */
public final class ThemeColors {

    /** 个性化覆盖层的 style 资源名（AAR 资源合并进 app 包） */
    private static final String OVERLAY_NAME = "ThemeOverlay.Material3.PersonalizedColors";

    /** 角色名（MaterialDynamicColors 方法名）与个性化资源名后缀，按覆盖层实际清单 */
    private static final String[][] COLOR_ROLES = {
            {"primary", "primary"},
            {"onPrimary", "on_primary"},
            {"primaryInverse", "primary_inverse"},
            {"primaryContainer", "primary_container"},
            {"onPrimaryContainer", "on_primary_container"},
            {"secondary", "secondary"},
            {"onSecondary", "on_secondary"},
            {"secondaryContainer", "secondary_container"},
            {"onSecondaryContainer", "on_secondary_container"},
            {"tertiary", "tertiary"},
            {"onTertiary", "on_tertiary"},
            {"tertiaryContainer", "tertiary_container"},
            {"onTertiaryContainer", "on_tertiary_container"},
            {"onBackground", "on_background"},
            {"surface", "surface"},
            {"onSurface", "on_surface"},
            {"surfaceVariant", "surface_variant"},
            {"onSurfaceVariant", "on_surface_variant"},
            {"inverseSurface", "surface_inverse"},
            {"inverseOnSurface", "on_surface_inverse"},
            {"surfaceBright", "surface_bright"},
            {"surfaceDim", "surface_dim"},
            {"surfaceContainer", "surface_container"},
            {"surfaceContainerLow", "surface_container_low"},
            {"surfaceContainerHigh", "surface_container_high"},
            {"surfaceContainerLowest", "surface_container_lowest"},
            {"surfaceContainerHighest", "surface_container_highest"},
            {"outline", "outline"},
            {"outlineVariant", "outline_variant"},
            {"error", "error"},
            {"onError", "on_error"},
            {"errorContainer", "error_container"},
            {"onErrorContainer", "on_error_container"},
    };

    private ThemeColors() {
    }

    /** 种子色生成方案名，与 Lua 侧主题页的选项一一对应 */
    public static String[] variantNames() {
        return new String[]{"Content", "Vibrant", "Expressive", "Fidelity", "FruitSalad", "Neutral", "Monochrome", "Rainbow", "TonalSpot"};
    }

    /**
     * 以种子色生成整套 MD3 配色并叠加到 Activity：Scheme 计算 33 角色色值，
     * 经 ColorResourcesOverride 注入个性化资源，再叠 PersonalizedColors 覆盖层
     * （把颜色 attr 重映射到这些资源）。不依赖系统动态取色门。
     *
     * @param variant      生成方案（variantNames 之一）
     * @param contrastLevel 对比度等级，-1 降 / 0 标准 / 1 高
     * @param isDark       按当前昼夜模式取对应配色
     * @return 是否实际生效（注入失败时为 false）
     */
    public static boolean applyCustomColors(Activity activity, int seedColor,
            String variant, double contrastLevel, boolean isDark) {
        if (activity == null) return false;
        try {
            DynamicScheme scheme = createScheme(Hct.fromInt(seedColor), variant, isDark, contrastLevel);
            if (scheme == null) return false;

            Context app = activity.getApplicationContext();
            MaterialDynamicColors roles = new MaterialDynamicColors();
            Map<Integer, Integer> overrides = new HashMap<>();
            for (String[] role : COLOR_ROLES) {
                int resId = app.getResources().getIdentifier(
                        "material_personalized_color_" + role[1], "color", app.getPackageName());
                if (resId != 0) {
                    overrides.put(resId, scheme.getArgb(roleOf(roles, role[0])));
                }
            }
            if (overrides.isEmpty()) return false;

            if (!ColorResourcesOverride.getInstance().applyIfPossible(activity, overrides)) return false;

            int overlayId = app.getResources().getIdentifier(OVERLAY_NAME, "style", app.getPackageName());
            if (overlayId != 0) {
                activity.getTheme().applyStyle(overlayId, true);
            }
            return true;
        } catch (Throwable ignored) {
            return false;
        }
    }

    /** 经 DynamicColorsOptions 的内容取色路径（动态取色门可用的设备） */
    public static boolean applySeedColor(Activity activity, int seedColor) {
        if (activity == null || !DynamicColors.isDynamicColorAvailable()) return false;
        try {
            DynamicColorsOptions options = new DynamicColorsOptions.Builder()
                    .setContentBasedSource(seedColor)
                    .build();
            DynamicColors.applyToActivityIfAvailable(activity, options);
            return true;
        } catch (Throwable ignored) {
            return false;
        }
    }

    /** 动态取色是否可用（SDK 与厂商白名单门），Lua 侧统一经此查询。 */
    public static boolean isDynamicAvailable() {
        try {
            return DynamicColors.isDynamicColorAvailable();
        } catch (Throwable ignored) {
            return false;
        }
    }

    /**
     * 从图片像素提取种子色（QuantizerCelebi + Score，Material You 取色同款算法），
     * 无系统动态色门。像素数组可由 Bitmap.getPixels 取得。
     *
     * @return 种子色 ARGB；提取失败返回 0
     */
    public static int seedColorFromPixels(int[] pixels) {
        if (pixels == null || pixels.length == 0) return 0;
        try {
            Map<Integer, Integer> counts = com.google.android.material.color.utilities.QuantizerCelebi.quantize(pixels, 64);
            java.util.List<Integer> ranked = com.google.android.material.color.utilities.Score.score(counts);
            return ranked.isEmpty() ? 0 : ranked.get(0);
        } catch (Throwable ignored) {
            return 0;
        }
    }

    /**
     * 种子色经方案计算后的预览色，供选择界面即时展示派生效果，不注入任何资源。
     *
     * @return int[6] { primary, onPrimary, secondary, tertiary, surface, onSurface }；
     *         计算失败返回 null
     */
    public static int[] previewColors(int seedColor, String variant, double contrastLevel, boolean isDark) {
        try {
            DynamicScheme scheme = createScheme(Hct.fromInt(seedColor), variant, isDark, contrastLevel);
            if (scheme == null) return null;
            MaterialDynamicColors roles = new MaterialDynamicColors();
            return new int[]{
                    scheme.getArgb(roles.primary()),
                    scheme.getArgb(roles.onPrimary()),
                    scheme.getArgb(roles.secondary()),
                    scheme.getArgb(roles.tertiary()),
                    scheme.getArgb(roles.surface()),
                    scheme.getArgb(roles.onSurface()),
                    scheme.getArgb(roles.onSurfaceVariant()),
            };
        } catch (Throwable ignored) {
            return null;
        }
    }

    private static DynamicScheme createScheme(Hct seed, String variant, boolean isDark, double contrastLevel) {
        switch (variant == null ? "Content" : variant) {
            case "Vibrant": return new SchemeVibrant(seed, isDark, contrastLevel);
            case "Expressive": return new SchemeExpressive(seed, isDark, contrastLevel);
            case "Fidelity": return new SchemeFidelity(seed, isDark, contrastLevel);
            case "FruitSalad": return new SchemeFruitSalad(seed, isDark, contrastLevel);
            case "Neutral": return new SchemeNeutral(seed, isDark, contrastLevel);
            case "Monochrome": return new SchemeMonochrome(seed, isDark, contrastLevel);
            case "Rainbow": return new SchemeRainbow(seed, isDark, contrastLevel);
            case "TonalSpot": return new SchemeTonalSpot(seed, isDark, contrastLevel);
            default: return new SchemeContent(seed, isDark, contrastLevel);
        }
    }

    private static DynamicColor roleOf(MaterialDynamicColors roles, String name) {
        switch (name) {
            case "onPrimary": return roles.onPrimary();
            case "primaryInverse": return roles.inversePrimary();
            case "primaryContainer": return roles.primaryContainer();
            case "onPrimaryContainer": return roles.onPrimaryContainer();
            case "secondary": return roles.secondary();
            case "onSecondary": return roles.onSecondary();
            case "secondaryContainer": return roles.secondaryContainer();
            case "onSecondaryContainer": return roles.onSecondaryContainer();
            case "tertiary": return roles.tertiary();
            case "onTertiary": return roles.onTertiary();
            case "tertiaryContainer": return roles.tertiaryContainer();
            case "onTertiaryContainer": return roles.onTertiaryContainer();
            case "onBackground": return roles.onBackground();
            case "onSurface": return roles.onSurface();
            case "surfaceVariant": return roles.surfaceVariant();
            case "onSurfaceVariant": return roles.onSurfaceVariant();
            case "inverseSurface": return roles.inverseSurface();
            case "inverseOnSurface": return roles.inverseOnSurface();
            case "surfaceBright": return roles.surfaceBright();
            case "surfaceDim": return roles.surfaceDim();
            case "surfaceContainer": return roles.surfaceContainer();
            case "surfaceContainerLow": return roles.surfaceContainerLow();
            case "surfaceContainerHigh": return roles.surfaceContainerHigh();
            case "surfaceContainerLowest": return roles.surfaceContainerLowest();
            case "surfaceContainerHighest": return roles.surfaceContainerHighest();
            case "outline": return roles.outline();
            case "outlineVariant": return roles.outlineVariant();
            case "error": return roles.error();
            case "onError": return roles.onError();
            case "errorContainer": return roles.errorContainer();
            case "onErrorContainer": return roles.onErrorContainer();
            case "surface": return roles.surface();
            default: return roles.primary();
        }
    }
}
