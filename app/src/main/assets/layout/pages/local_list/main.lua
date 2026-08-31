-- layout/pages/local_list/main.lua
-- 本地内容列表页布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.hydrogen.view.CustomSwipeRefresh"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
import "android.view.View"

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
    CustomSwipeRefresh,
    id = "swipe_refresh",
    layout_width = "fill",
    layout_height = "fill",
    {
      RecyclerView,
      id = "recycler_view",
      layout_width = "fill",
      layout_height = "fill",
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
      imageBitmap = Helpers.Static.materialIcon("inbox"),
      colorFilter = colors.onSurfaceVariant,
    },
    {
      MaterialTextView,
      text = "暂无本地内容",
      textSize = AppTextStyle.titleSmall.size,
      textColor = AppTextStyle.titleSmall.color,
      typeface = AppTextStyle.titleSmall.font,
    },
    {
      MaterialTextView,
      text = "在回答页面点击保存即可收藏",
      textSize = AppTextStyle.bodySmall.size,
      textColor = AppTextStyle.bodySmall.color,
      typeface = AppTextStyle.bodySmall.font,
      layout_marginTop = "8dp",
    }
  }
}