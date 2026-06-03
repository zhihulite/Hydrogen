-- core/app_theme.lua
-- 主题管理

local M = {}

import "android.os.Build"
import "android.view.View"
import "android.view.WindowManager"
import "androidx.appcompat.app.AppCompatDelegate"
import "android.content.res.Configuration"

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

import "android.app.UiModeManager"
import "android.content.Context"
-- 判断系统全局的深色模式状态
local function isSystemNightMode()
    local uiModeManager = activity.getSystemService(Context.UI_MODE_SERVICE)
    -- MODE_NIGHT_YES 通常值为 2
    return uiModeManager.getNightMode() == UiModeManager.MODE_NIGHT_YES
end

local initialized = false
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
  local isOled = Extensions.Config.getBool(Constants.SharedDataKeys.OLED_MODE) and M.getAppIsNight()
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

-- 获取App当前夜间模式
function M.getAppIsNight()
  local resources = activity.resources
  local config = resources.configuration
  local AppIsNight = (config.uiMode & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
  return AppIsNight
end

function M.getColor(name)
  return M.colors[name] or 0
end

-- 应用夜间模式
function M.applyNightMode()
  local isManualNight = Extensions.Config.getBool(Constants.SharedDataKeys.NIGHT_MODE)
  local isAutoNight = Extensions.Config.getBool(Constants.SharedDataKeys.AUTO_NIGHT_MODE)

  -- 获取当前模式
  local currentMode = AppCompatDelegate.defaultNightMode
  -- 确定目标模式
  local targetMode
  if isManualNight then
    targetMode = AppCompatDelegate.MODE_NIGHT_YES
  elseif isAutoNight then
    -- 自动模式：从系统获取当前是否是夜间
    -- 由于自动模式也要重启，所以这里将自动模式映射一下。
    -- 把 AndroidManifest.xml 对应 Activity 的 android:configChanges 的 uiMode 部分删除也可。 
    local isSystemNight = isSystemNightMode()
    targetMode = isSystemNight and AppCompatDelegate.MODE_NIGHT_YES or AppCompatDelegate.MODE_NIGHT_NO
  else
    targetMode = AppCompatDelegate.MODE_NIGHT_NO
  end
  
  -- 如果模式设置不一致，就重建
  if currentMode ~= targetMode then
    AppCompatDelegate.setDefaultNightMode(targetMode)
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
  -- 获取主题资源 ID
  local resources = activity.resources
  local packageName = activity.packageName
  local themeResId = resources.getIdentifier("Theme." .. themeName, "style", packageName)
  if themeResId ~= 0 then
    activity.theme = themeResId
   else
    tip("当前选择主题已失效")
  end
end

return M