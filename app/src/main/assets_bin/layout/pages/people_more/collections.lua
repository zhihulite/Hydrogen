-- layout/pages/people_more/collections.lua
-- 用户更多 - 收藏夹布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.appbar.MaterialToolbar"

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "fill",
  id = "main_container",
  backgroundColor = colors.background,
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "fill",
    layout_height = "wrap",
    elevation = 0,
  },
  {
    LinearLayoutCompat,
    layout_width = "fill",
    layout_height = 0,
    layout_weight = 1,
    Layouts.pages.home.page_collections,
  }
}