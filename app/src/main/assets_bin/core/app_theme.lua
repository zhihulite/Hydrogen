-- core/app_theme.lua
-- 主题管理

local M = {}

import "android.os.Build"
import "android.view.View"
import "android.view.WindowManager"
import "androidx.appcompat.app.AppCompatDelegate"
import "android.content.res.Configuration"

local initialized = false
-- OLED 纯黑模式覆盖颜色
local oledColorsInt = {
  background = 0xFF000000,
  surface = 0xFF000000,
  surfaceVariant = 0xFF1A1A1A,
}


-- 颜色属性映射
-- 根据配色文档转换 详见 https://github.com/material-components/material-components-android/blob/master/docs/theming/Color.md
-- 只有 background 使用 andorid属性，其他都是 app 属性。
local attrMapping = {
  primary = { type = "app", attr = "colorPrimary" },
  onPrimary = { type = "app", attr = "colorOnPrimary" },
  primaryContainer = { type = "app", attr = "colorPrimaryContainer" },
  onPrimaryContainer = { type = "app", attr = "colorOnPrimaryContainer" },
  primaryInverse = { type = "app", attr = "colorPrimaryInverse" },
  primaryFixed = { type = "app", attr = "colorPrimaryFixed" },
  primaryFixedDim = { type = "app", attr = "colorPrimaryFixedDim" },
  onPrimaryFixed = { type = "app", attr = "colorOnPrimaryFixed" },
  onPrimaryFixedVariant = { type = "app", attr = "colorOnPrimaryFixedVariant" },
  secondary = { type = "app", attr = "colorSecondary" },
  onSecondary = { type = "app", attr = "colorOnSecondary" },
  secondaryContainer = { type = "app", attr = "colorSecondaryContainer" },
  onSecondaryContainer = { type = "app", attr = "colorOnSecondaryContainer" },
  secondaryFixed = { type = "app", attr = "colorSecondaryFixed" },
  secondaryFixedDim = { type = "app", attr = "colorSecondaryFixedDim" },
  onSecondaryFixed = { type = "app", attr = "colorOnSecondaryFixed" },
  onSecondaryFixedVariant = { type = "app", attr = "colorOnSecondaryFixedVariant" },
  tertiary = { type = "app", attr = "colorTertiary" },
  onTertiary = { type = "app", attr = "colorOnTertiary" },
  tertiaryContainer = { type = "app", attr = "colorTertiaryContainer" },
  onTertiaryContainer = { type = "app", attr = "colorOnTertiaryContainer" },
  tertiaryFixed = { type = "app", attr = "colorTertiaryFixed" },
  tertiaryFixedDim = { type = "app", attr = "colorTertiaryFixedDim" },
  onTertiaryFixed = { type = "app", attr = "colorOnTertiaryFixed" },
  onTertiaryFixedVariant = { type = "app", attr = "colorOnTertiaryFixedVariant" },
  error = { type = "app", attr = "colorError" },
  onError = { type = "app", attr = "colorOnError" },
  errorContainer = { type = "app", attr = "colorErrorContainer" },
  onErrorContainer = { type = "app", attr = "colorOnErrorContainer" },
  outline = { type = "app", attr = "colorOutline" },
  outlineVariant = { type = "app", attr = "colorOutlineVariant" },
  background = { type = "android", attr = "colorBackground" },
  onBackground = { type = "app", attr = "colorOnBackground" },
  surface = { type = "app", attr = "colorSurface" },
  onSurface = { type = "app", attr = "colorOnSurface" },
  surfaceVariant = { type = "app", attr = "colorSurfaceVariant" },
  onSurfaceVariant = { type = "app", attr = "colorOnSurfaceVariant" },
  surfaceInverse = { type = "app", attr = "colorSurfaceInverse" },
  onSurfaceInverse = { type = "app", attr = "colorOnSurfaceInverse" },
  surfaceBright = { type = "app", attr = "colorSurfaceBright" },
  surfaceDim = { type = "app", attr = "colorSurfaceDim" },
  surfaceContainer = { type = "app", attr = "colorSurfaceContainer" },
  surfaceContainerLow = { type = "app", attr = "colorSurfaceContainerLow" },
  surfaceContainerLowest = { type = "app", attr = "colorSurfaceContainerLowest" },
  surfaceContainerHigh = { type = "app", attr = "colorSurfaceContainerHigh" },
  surfaceContainerHighest = { type = "app", attr = "colorSurfaceContainerHighest" },
}

local function getColorValue(key)
  local mapping = attrMapping[key]
  if not mapping then return 0 end
  return Helpers.Resources[mapping.type].attr[mapping.attr]
end

M.colors = setmetatable({}, {
  __index = function()
    error("AppTheme 未初始化，请先调用 AppTheme.init()")
  end
})

-- 初始化主题
function M.init()
  M.applyNightMode()
  M.applyTheme()
  initialized = true

  -- 构建颜色缓存
  local colorsCache = setmetatable({}, {
    __index = function(t, k)
      local v = getColorValue(k)
      rawset(t, k, v)
      return v
    end
  })

  -- OLED 模式判断
  local isOled = Extensions.Config.getBool(Constants.SharedDataKeys.OLED_MODE) and M.isEffectiveNight()
  -- OLED 模式覆盖：仅在夜间模式下生效
  if isOled then
    M.colors = setmetatable({}, {
      __index = function(t, k)
        if k == "background" or k == "surface" or k == "surfaceVariant" then
          return oledColorsInt[k]
        end
        return colorsCache[k]
      end
    })
   else
    M.colors = colorsCache
  end

end

-- 判断是否夜间模式
function M.isEffectiveNight()
  local resources = activity.resources
  local config = resources.configuration
  local isNight = (config.uiMode & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
  return isNight
end

function M.getColor(name)
  return M.colors[name] or 0
end

-- 应用夜间模式
function M.applyNightMode()
  local isManualNight = Extensions.Config.getBool(Constants.SharedDataKeys.NIGHT_MODE)
  local isAutoNight = Extensions.Config.getBool(Constants.SharedDataKeys.AUTO_NIGHT_MODE)

  -- 获取当前模式
  local currentMode = AppCompatDelegate.getDefaultNightMode()
  -- 确定目标模式
  local targetMode
  if isManualNight then
    targetMode = AppCompatDelegate.MODE_NIGHT_YES
   elseif isAutoNight then
    targetMode = AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
   else
    targetMode = AppCompatDelegate.MODE_NIGHT_NO
  end
  -- 只有不一致时才设置并重建
  if currentMode ~= targetMode then
    AppCompatDelegate.setDefaultNightMode(targetMode)
    -- 重建 Activity 使主题生效
    activity.recreate()
  end
end

-- ============ 主题管理 ============

-- 设置主题
function M.setThemeConfig(themeName)
  Extensions.Config.set(Constants.SharedDataKeys.THEME_SETTING, themeName)
end

-- 获取主题
function M.getThemeConfig()
  return Extensions.Config.getString(Constants.SharedDataKeys.THEME_SETTING, "Default")
end

-- 应用主题
function M.applyTheme()
  local themeName = M.getThemeConfig()
  local R = luajava.bindClass(activity.packageName .. ".R")
  local ok, themeResId = pcall(function() return R.style["Theme_" .. themeName] end)
  if ok and themeResId then
    activity.theme = themeResId
  end
end

return M