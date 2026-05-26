-- layout/question/main.lua
-- 问题详情页布局（使用 RecyclerView + Header 方式）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.hydrogen.view.CustomSwipeRefresh"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"

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
      clipToPadding = false,
      paddingTop = "8dp",
      paddingBottom = "8dp",
    }
  }
}