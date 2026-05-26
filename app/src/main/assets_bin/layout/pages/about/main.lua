-- layout/pages/about/main.lua
-- 关于页面主布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.appbar.MaterialToolbar"

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  id = "main_container",
  orientation="vertical";
  backgroundColor = colors.background,
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "fill",
    layout_height = "wrap"
  },
  {
    RecyclerView,
    id = "recycler_view",
    layout_width = "fill",
    layout_height = "fill",
    clipToPadding=false,
  }
}