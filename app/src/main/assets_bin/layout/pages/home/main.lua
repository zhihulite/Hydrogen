-- layout/pages/home/main.lua
-- 主页布局（Drawer + Toolbar + 页面容器）

import "androidx.drawerlayout.widget.DrawerLayout"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.appbar.MaterialToolbar"
import "android.widget.FrameLayout"
import "com.google.android.material.navigation.NavigationView"

local colors = AppTheme.getColors()

return {
  DrawerLayout,
  id = "drawer",
  layout_width = "fill",
  layout_height = "fill",
  {
    LinearLayoutCompat,
    id = "main_container",
    layout_width = "fill",
    layout_height = "fill",
    orientation = "vertical",
    {
      MaterialToolbar,
      id = "toolbar",
      layout_width = "fill",
      layout_height = "wrap",
    },
    {
      FrameLayout,
      id = "page_container",
      layout_width = "fill",
      layout_height = "0dp",
      layout_weight = 1,
      backgroundColor = colors.background,
    }
  },
  {
    NavigationView,
    id = "nav_view",
    layout_width = "280dp",
    layout_height = "fill",
    layout_gravity = "start"
  }
}