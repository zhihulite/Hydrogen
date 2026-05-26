-- components/views/TabBar.lua
-- 横向滚动 Tab 栏组件

import "android.widget.LinearLayout"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.card.MaterialCardView"

-- 默认配置
local DEFAULT_CONFIG = {
  tabHeight = "32dp", -- Tab 高度
  tabMargin = "8dp", -- 左右外边距
  tabRadius = "16dp", -- 圆角半径
  textSize = AppTextStyle.labelSmall.size, -- 统一使用全局 label 尺寸 (11sp 对应像素值)
  paddingHorizontal = "16dp", -- 左右内边距
  typeface = AppTextStyle.labelSmall.font, -- 统一使用全局 label 字重 (Medium)
}

local TabBar = {}

--- 创建 TabBar
---@param parent ViewGroup 父容器
---@param tabNames table 标签名数组
---@param onSelected function 选中回调 function(index, name)
---@param options table|nil 可选配置（覆盖默认值）
---@return table tabs  { card, label, name } 数组
function TabBar.create(parent, tabNames, onSelected, options)
  local opt = options or {}
  local colors = AppTheme.colors

  -- 合并默认配置
  local tabHeight = opt.tabHeight or DEFAULT_CONFIG.tabHeight
  local tabMargin = opt.tabMargin or DEFAULT_CONFIG.tabMargin
  local tabRadius = opt.tabRadius or DEFAULT_CONFIG.tabRadius
  local textSize = opt.textSize or DEFAULT_CONFIG.textSize
  local paddingHorizontal = opt.paddingHorizontal or DEFAULT_CONFIG.paddingHorizontal
  local typeface = opt.typeface or DEFAULT_CONFIG.typeface

  local normalColor = opt.normalColor or colors.surfaceContainerLow
  local normalTextColor = opt.normalTextColor or colors.onSurface

  local tabs = {}

  local function createTab(name, index)
    local tabViews = {}
    local tab = loadlayout({
      LinearLayout,
      layout_width = "wrap",
      layout_height = "wrap",
      {
        MaterialCardView,
        id = "card",
        layout_width = "wrap",
        layout_height = tabHeight,
        layout_marginLeft = tabMargin,
        layout_marginRight = tabMargin,
        layout_marginTop = tabMargin,
        layout_marginBottom = tabMargin,
        radius = tabRadius,
        cardBackgroundColor = normalColor,
        clickable = true,
        {
          MaterialTextView,
          id = "label",
          text = name,
          textSize = textSize,
          textColor = normalTextColor,
          typeface = typeface,
          paddingLeft = paddingHorizontal,
          paddingRight = paddingHorizontal,
          layout_gravity = "center",
        }
      }
    }, tabViews)

    tabViews.card.onClick = function()
      onSelected(index, name)
    end
    parent.addView(tab)

    return {
      card = tabViews.card,
      label = tabViews.label,
      name = name,
    }
  end

  for i, name in ipairs(tabNames) do
    tabs[i] = createTab(name, i)
  end

  -- 默认选中第一个
  TabBar.select(tabs, 1, {
    -- 选中色由组件内部定义，不强制使用全局 AppTextStyle 颜色
    selectedColor = opt.selectedColor or colors.primary,
    selectedTextColor = opt.selectedTextColor or colors.surfaceBright,
    normalColor = normalColor,
    normalTextColor = normalTextColor,
  })

  return tabs
end

--- 选中指定 Tab
---@param tabs table
---@param index number
---@param colorsConfig table { selectedColor, selectedTextColor, normalColor, normalTextColor }
function TabBar.select(tabs, index, colorsConfig)
  local colors = AppTheme.colors
  local cfg = colorsConfig or {}
  local selectedColor = cfg.selectedColor or colors.primary
  local selectedTextColor = cfg.selectedTextColor or colors.surfaceBright
  local normalColor = cfg.normalColor or colors.surfaceContainerLow
  local normalTextColor = cfg.normalTextColor or colors.onSurface

  for _, tab in ipairs(tabs) do
    tab.card.cardBackgroundColor = normalColor
    tab.label.textColor = normalTextColor
  end

  local selected = tabs[index]
  if selected then
    selected.card.cardBackgroundColor = selectedColor
    selected.label.textColor = selectedTextColor
  end
end

return TabBar