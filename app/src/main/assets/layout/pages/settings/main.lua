-- layout/pages/settings/main.lua
-- 设置页面主布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.appbar.MaterialToolbar"
import "android.view.View"
import "android.content.res.ColorStateList"

local L = Helpers.Layout

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  id = "main_container",
  backgroundColor = colors.background,
  clipToPadding=false,
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "fill",
    layout_height = "wrap",
  },
  {
    LinearLayoutCompat,
    id = "search_container",
    layout_width = "fill",
    layout_height = "wrap",
    orientation = "horizontal",
    gravity = "center_vertical",
    visibility = View.GONE,
    layout_marginLeft = AppSpacing.md,
    layout_marginRight = AppSpacing.md,
    layout_marginBottom = AppSpacing.sm,
    L.edit("search_input", AppTextStyle.bodyMedium, "搜索设置项", {
      layout_width = 0,
      layout_weight = 1,
      layout_height = "wrap_content",
    }),
    {
      Helpers.MaterialWidgets.IconButton_ExtraSmall,
      id = "search_clear_btn",
      layout_width = "wrap_content",
      layout_height = "wrap_content",
      icon = Helpers.Static.materialDrawable("twotone_close", 24, true),
      iconTint = ColorStateList.valueOf(colors.primary),
      clickable = true,
    },
  },
  {
    RecyclerView,
    id = "recycler_view",
    layout_width = "fill",
    layout_height = "fill",
    clipToPadding = false,
  }
}