-- layout/pages/page_layout/main.lua
-- 页面布局设置主布局：预览区 + 滑块区

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.core.widget.NestedScrollView"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.slider.Slider"

local L = Helpers.Layout

local colors = AppTheme.colors

--- 一组滑块：标题 + 当前值 + 说明 + Slider
--- @param id string 生成 <id>_title / <id>_value / <id>_slider
--- @param title string
--- @param summary string
--- @return table
local function sliderRow(id, title, summary)
  return {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "wrap",
    layout_marginTop = AppSpacing.lg,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "fill",
      layout_height = "wrap",
      gravity = "center_vertical",
      L.text(id .. "_title", AppTextStyle.titleSmall, title, {
        layout_width = 0,
        layout_weight = 1,
      }),
      L.text(id .. "_value", AppTextStyle.labelLarge, nil),
    },
    L.text(id .. "_summary", AppTextStyle.bodySmall, summary, { layout_marginTop = AppSpacing.xs }),
    {
      Slider,
      id = id .. "_slider",
      layout_width = "fill",
      layout_height = "wrap",
    },
  }
end

return {
  LinearLayoutCompat,
  id = "main_container",
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  backgroundColor = colors.background,
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "fill",
    layout_height = "wrap",
  },
  {
    NestedScrollView,
    id = "content_scroll",
    layout_width = "fill",
    layout_height = "fill",
    fillViewport = true,
    clipToPadding = false,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap",
      -- 预览容器：内容由 Fragment 按当前滑块值现场构建
      {
        LinearLayoutCompat,
        id = "preview_container",
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        layout_marginTop = AppSpacing.md,
      },
      {
        LinearLayoutCompat,
        orientation = "vertical",
        layout_width = "fill",
        layout_height = "wrap",
        paddingLeft = AppSpacing.content,
        paddingRight = AppSpacing.content,
        paddingBottom = AppSpacing.content,
        sliderRow("font", "字体大小", "同时影响列表、卡片与网页正文"),
        sliderRow("margin", "页边距", "卡片距屏幕左右两侧的距离"),
        sliderRow("gap", "卡片间距", "相邻卡片之间的留白"),
        sliderRow("padding", "卡片内边距", "卡片边框到文字的距离"),
        {
          MaterialButton,
          id = "reset_btn",
          layout_width = "fill",
          layout_height = "wrap",
          layout_marginTop = AppSpacing.xl,
          text = "恢复默认",
        },
      },
    },
  },
}
