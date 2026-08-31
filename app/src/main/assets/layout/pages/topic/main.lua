-- layout/pages/topic/main.lua
-- 话题详情页布局（CoordinatorLayout + AppBar + TabLayout + ViewPager）

import "androidx.coordinatorlayout.widget.CoordinatorLayout"
import "com.google.android.material.appbar.AppBarLayout"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.tabs.TabLayout"
import "androidx.viewpager.widget.ViewPager"
import "android.view.View"

local colors = AppTheme.colors

return {
  CoordinatorLayout,
  layout_width = "fill",
  layout_height = "fill",
  id = "main_container",
  backgroundColor = colors.background,
  {
    AppBarLayout,
    id = "appbar",
    layout_width = "fill",
    layout_height = "wrap_content",
    {
      MaterialToolbar,
      id = "toolbar",
      layout_width = "fill",
      layout_height = "wrap"
    },
    {
      TabLayout,
      id = "tab_layout",
      layout_width = "fill",
      layout_height = "wrap",
      tabMode = TabLayout.MODE_FIXED,
      tabGravity = TabLayout.GRAVITY_FILL,
    }
  },
  {
    -- 内容区域
    ViewPager,
    id = "view_pager",
    layout_width = "fill",
    layout_height = "fill",
    layout_behavior = "@string/appbar_scrolling_view_behavior",
  }
}