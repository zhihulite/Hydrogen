-- layout/pages/open_source/main.lua
-- 开源协议页面主布局

import "androidx.appcompat.widget.LinearLayoutCompat"
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
    RecyclerView,
    id = "recycler_view",
    layout_width = "fill",
    layout_height = "fill",
    clipToPadding = false,
  }
}