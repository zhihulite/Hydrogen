-- layout/pages/history/main.lua
-- 历史记录页面主布局

import "android.view.View"
import "android.widget.HorizontalScrollView"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.hydrogen.view.CustomSwipeRefresh"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  id = "main_container",
  backgroundColor = colors.background,
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "fill",
    layout_height = "wrap"
  },
  {
    HorizontalScrollView,
    layout_width = "fill",
    layout_height = "48dp",
    {
      LinearLayoutCompat,
      id = "tab_layout",
      layout_width = "wrap",
      layout_height = "fill",
      orientation = "horizontal",
    }
  },
  {
    CustomSwipeRefresh,
    id = "swipe_refresh",
    layout_width = "fill",
    layout_height = "fill",
    {
      RecyclerView,
      id = "recycler_view",
      layout_width = "fill",
      layout_height = "fill",
      clipToPadding = false,
    }
  },
  {
    LinearLayoutCompat,
    id = "empty_view",
    layout_width = "fill",
    layout_height = "fill",
    gravity = "center",
    orientation = "vertical",
    visibility = View.GONE,
    {
      AppCompatImageView,
      layout_width = "80dp",
      layout_height = "80dp",
      layout_marginBottom = "16dp",
      imageBitmap = Helpers.Static.materialIcon("history"),
      colorFilter = colors.onSurfaceVariant,
    },
    {
      MaterialTextView,
      text = "暂无历史记录",
      textSize  = AppTextStyle.titleSmall.size,
      textColor = AppTextStyle.titleSmall.color,
      typeface  = AppTextStyle.titleSmall.font,
    },
    {
      MaterialTextView,
      text = "浏览过的内容会显示在这里",
      textSize  = AppTextStyle.bodySmall.size,
      textColor = AppTextStyle.bodySmall.color,
      typeface  = AppTextStyle.bodySmall.font,
      layout_marginTop = "8dp",
    }
  }
}