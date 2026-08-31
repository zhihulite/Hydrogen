-- core/app_theme.lua
-- 主题管理

local M = {}

import "android.view.View"
import "androidx.appcompat.app.AppCompatDelegate"
import "android.content.res.Configuration"
import "android.app.UiModeManager"
import "android.content.Context"

-- 取色规则：key 即 MD3 颜色角色名，attr 名 = "color" + 首字母大写；
-- 仅 background 用 android 命名空间的 colorBackground。未知角色返回 0。
local function getColorValue(key)
  local ok, v
  if key == "background" then
    ok, v = pcall(function() return Helpers.Resources.android.attr.colorBackground end)
   else
    local attr = "color" .. key:sub(1, 1):upper() .. key:sub(2)
    ok, v = pcall(function() return Helpers.Resources.app.attr[attr] end)
  end
  if ok and type(v) == "number" then return v end
  return 0
end

M.colors = setmetatable({}, {
  __index = function()
    error("AppTheme 未初始化，请先调用 AppTheme.init()")
  end
})

-- 判断系统全局的深色模式状态
local function isSystemNightMode()
  local uiModeManager = activity.getSystemService(Context.UI_MODE_SERVICE)
  -- MODE_NIGHT_YES 通常值为 2
  return uiModeManager.getNightMode() == UiModeManager.MODE_NIGHT_YES
end

-- 启动期立即校正 Resources 的 uiMode：
-- AppCompatDelegate.setDefaultNightMode 只对之后的 Activity 生效，本 Activity 首帧
-- 仍按 Manifest 默认渲染；直接改当前 Resources 的 config，View 构造时取到的
-- 主题（含 Monet 动态色）立即就是目标模式，省掉一次 recreate 的引擎重建。

local function applyUiModeNow()
  local isManualNight = Extensions.Config.getBool(Constants.SharedDataKeys.NIGHT_MODE)
  local isAutoNight = Extensions.Config.getBool(Constants.SharedDataKeys.AUTO_NIGHT_MODE)
  local resources = activity.getResources()
  local config = resources.getConfiguration()
  local currentUiMode = config.uiMode & Configuration.UI_MODE_NIGHT_MASK
  local targetUiMode = Configuration.UI_MODE_NIGHT_NO

  if isManualNight then
    targetUiMode = Configuration.UI_MODE_NIGHT_YES
   elseif isAutoNight then
    targetUiMode = currentUiMode
  end

  if currentUiMode ~= targetUiMode then
    config.uiMode = (config.uiMode & ~Configuration.UI_MODE_NIGHT_MASK) | targetUiMode
    resources.updateConfiguration(config, resources.getDisplayMetrics())
  end
end

local initialized = false
-- 初始化主题
function M.init()
  if initialized then return end
  pcall(applyUiModeNow)
  M.applyNightMode()
  M.applyTheme()
  initialized = true

  -- 构建颜色缓存：值从当前 theme 的 attr 解析，已含 OLED 覆盖层叠加后的结果
  local colorsCache = setmetatable({}, {
    __index = function(t, k)
      local v = getColorValue(k)
      rawset(t, k, v)
      return v
    end
  })
  M.colors = colorsCache
end

-- 判断 App 当前是否为夜间模式
function M.isAppNight()
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
  local currentMode = AppCompatDelegate.defaultNightMode
  -- 确定目标模式
  local targetMode
  if isManualNight then
    targetMode = AppCompatDelegate.MODE_NIGHT_YES
   elseif isAutoNight then
    -- 自动模式：从系统获取当前是否是夜间
    -- 由于自动模式也要重启，所以这里将自动模式映射一下。
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
  -- 主题名失效时回落默认主题，并写回配置
  if themeResId == 0 then
    M.setThemeConfig("Default")
    themeResId = resources.getIdentifier("Theme.Default", "style", packageName)
  end
  if themeResId ~= 0 then
    activity.theme = themeResId
  end

  -- OLED 纯黑：经主题覆盖层叠加，?attr/colorSurface 系列与 AppTheme.colors 同步生效
  if Extensions.Config.getBool(Constants.SharedDataKeys.OLED_MODE) and M.isAppNight() then
    local oledOverlayId = resources.getIdentifier("ThemeOverlay.Hydrogen.Oled", "style", packageName)
    if oledOverlayId ~= 0 then
      activity.theme.applyStyle(oledOverlayId, true)
    end
  end
end

return M