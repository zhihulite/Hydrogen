-- layout/collections/main.lua
-- 收藏夹详情页布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.hydrogen.view.CustomSwipeRefresh"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.appbar.MaterialToolbar"

local colors = AppTheme.getColors()

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
    }
  }
}