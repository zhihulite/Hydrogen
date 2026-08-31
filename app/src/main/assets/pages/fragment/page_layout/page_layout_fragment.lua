-- pages/fragment/page_layout/page_layout_fragment.lua
-- 页面布局设置 Fragment：字号与卡片边距，改动实时反映到预览卡

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.slider.Slider"

local BaseFragment = require("pages.base.base_fragment")

local PageLayoutFragment = Extensions.Class(BaseFragment, { "page_layout" })
local SharedDataKeys = Constants.SharedDataKeys

-- 基准字号：LuaActivity 用 font_size / BASE_FONT_SIZE 换算 Configuration.fontScale
local BASE_FONT_SIZE = 20

-- 四项滑块：id 前缀对应布局里的 <id>_slider / <id>_value / <id>_title
local SLIDERS = {
  { id = "font", key = SharedDataKeys.FONT_SIZE, from = 12, to = 30, unit = "sp" },
  { id = "margin", key = SharedDataKeys.PAGE_MARGIN, from = 4, to = 32, unit = "dp" },
  { id = "gap", key = SharedDataKeys.CARD_GAP, from = 0, to = 16, unit = "dp" },
  { id = "padding", key = SharedDataKeys.CARD_PADDING, from = 4, to = 24, unit = "dp" },
}

local function clamp(value, minVal, maxVal)
  if value < minVal then return minVal end
  if value > maxVal then return maxVal end
  return value
end

--- 预览卡布局：结构对齐首页推荐卡（标题 + 摘要 + 计量行）
--- @param values table 各滑块当前值，按 SLIDERS 的 id 索引
--- @return table 布局表
local function previewLayout(values)
  local colors = AppTheme.colors
  local density = Screen.density
  local scale = values.font / BASE_FONT_SIZE

  -- 预览要显示滑块选中的目标字号。sp 会被当前 Context 已生效的 fontScale
  -- 再放大一次，换算成 px 传入才能绕开它
  local function px(sp)
    return tostring(math.floor(sp * density * scale + 0.5)) .. "px"
  end

  local margin = dp2px(values.margin)
  local padding = dp2px(values.padding)

  local card = {
    MaterialCardView,
    layout_width = "fill",
    layout_height = "wrap",
    layout_marginLeft = margin,
    layout_marginRight = margin,
    layout_marginTop = dp2px(values.gap),
    cardBackgroundColor = colors.surface,
    clickable = false,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap",
      paddingLeft = padding,
      paddingRight = padding,
      paddingTop = padding,
      paddingBottom = padding,
      Helpers.Layout.text(nil, AppTextStyle.titleSmall, "如何评价这次的布局调整？", {
        textSize = px(AppTextStyle.titleSmall.size),
      }),
      Helpers.Layout.text(nil, AppTextStyle.bodyMedium, "拖动下方滑块，这张卡片会同步显示字号与边距的效果。", {
        textSize = px(AppTextStyle.bodyMedium.size),
        layout_marginTop = dp2px(6),
      }),
      Helpers.Layout.text(nil, AppTextStyle.bodySmall, "1024 赞同 · 36 评论", {
        textSize = px(AppTextStyle.bodySmall.size),
        layout_marginTop = AppSpacing.md,
      }),
    },
  }

  return {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "wrap",
    card,
  }
end

function PageLayoutFragment:ctor()
  -- 当前值与进页快照：返回时比对，决定是否需要重启
  self.values = {}
  self.snapshot = {}
end

function PageLayoutFragment:onCreate(params)
  for _, conf in ipairs(SLIDERS) do
    local raw = Extensions.Config.getNumber(conf.key)
    local value = math.floor(clamp(raw, conf.from, conf.to) + 0.5)
    self.values[conf.id] = value
    self.snapshot[conf.id] = value
  end
end

function PageLayoutFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.page_layout.main, self.views)
end

function PageLayoutFragment:initViews()
  local views = self.views

  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = { views.content_scroll },
  })

  Helpers.UI.setupToolbar(views.toolbar, {
    title = "页面布局",
    navCallback = function() self:leave() end,
  })

  self:addBackPressedCallback({
    handleOnBackPressed = function() self:leave() end,
  })

  for _, conf in ipairs(SLIDERS) do
    self:setupSlider(conf)
  end

  if views.reset_btn then
    views.reset_btn.onClick = function() self:resetDefaults() end
  end

  self:refreshPreview()
end

--- 绑定单个滑块：拖动中只刷预览，抬手才写配置
--- @param conf table SLIDERS 中的一项
function PageLayoutFragment:setupSlider(conf)
  local views = self.views
  local slider = views[conf.id .. "_slider"]
  if not slider then return end

  slider.valueFrom = conf.from
  slider.valueTo = conf.to
  slider.stepSize = 1
  slider.value = self.values[conf.id]
  self:updateValueLabel(conf)

  local dragging = false
  local pendingValue = nil

  slider.addOnChangeListener(luajava.createProxy(Slider.OnChangeListener, {
    onValueChange = function(view, value, fromUser)
      if not fromUser then return end
      local saveValue = math.floor(value + 0.5)
      self.values[conf.id] = saveValue
      self:updateValueLabel(conf)
      self:refreshPreview()
      if dragging then
        pendingValue = saveValue
       else
        -- 无障碍与按键改值不走触摸回调，当场写入
        Extensions.Config.set(conf.key, saveValue)
      end
    end
  }))

  slider.addOnSliderTouchListener(luajava.createProxy(Slider.OnSliderTouchListener, {
    onStartTrackingTouch = function()
      dragging = true
      pendingValue = nil
    end,
    onStopTrackingTouch = function()
      dragging = false
      if pendingValue then
        Extensions.Config.set(conf.key, pendingValue)
        pendingValue = nil
      end
    end
  }))
end

--- 刷新滑块右侧的数值标签
--- @param conf table SLIDERS 中的一项
function PageLayoutFragment:updateValueLabel(conf)
  local label = self.views[conf.id .. "_value"]
  if label then
    label.text = self.values[conf.id] .. conf.unit
  end
end

--- 按当前值重建预览卡。布局表在 require 时已按旧配置定型，
--- 预览必须现场构建才能反映未重启的新值
function PageLayoutFragment:refreshPreview()
  local container = self.views.preview_container
  if not container then return end
  container.removeAllViews()
  container.addView(loadlayout(previewLayout(self.values)))
end

--- 四项回到默认值并写入配置
function PageLayoutFragment:resetDefaults()
  for _, conf in ipairs(SLIDERS) do
    local default = Constants.defaults[conf.key] or conf.from
    local value = math.floor(clamp(default, conf.from, conf.to) + 0.5)
    self.values[conf.id] = value
    Extensions.Config.set(conf.key, value)
    local slider = self.views[conf.id .. "_slider"]
    if slider then slider.value = value end
    self:updateValueLabel(conf)
  end
  self:refreshPreview()
  tip("已恢复默认")
end

--- 是否有值与进页时不同
--- @return boolean
function PageLayoutFragment:isDirty()
  for id, value in pairs(self.values) do
    if self.snapshot[id] ~= value then return true end
  end
  return false
end

--- 离开页面：有改动时确认重启，字号经 attachBaseContext 生效，
--- 已构建的视图也要重建才能跟上新边距
function PageLayoutFragment:leave()
  if not self:isDirty() then
    Router.back()
    return
  end
  Helpers.BottomDialog.confirm("布局改动必须重启软件才能完全生效，是否立即重启？", function()
    activity.recreate()
    end, function()
    Router.back()
  end)
end

return PageLayoutFragment
