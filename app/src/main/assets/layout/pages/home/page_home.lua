-- layout/pages/home/page_home.lua
-- 主页子页面容器布局（TabLayout + ViewPager + BottomNav）

import "androidx.coordinatorlayout.widget.CoordinatorLayout"
import "com.google.android.material.bottomnavigation.BottomNavigationView"
import "com.google.android.material.tabs.TabLayout"
import "com.hydrogen.view.CustomViewPager"
import "android.view.View"

return {
  CoordinatorLayout,
  layout_width = "fill",
  layout_height = "fill",
  {
    TabLayout,
    id = "tab_layout",
    layout_width = "fill",
    layout_height = "wrap",
    tabMode = TabLayout.MODE_SCROLLABLE,
    tabGravity = TabLayout.GRAVITY_FILL,
    visibility = View.GONE,
  },
  {
    CustomViewPager,
    id = "view_pager",
    layout_width = "fill",
    layout_height = "fill",
    layout_behavior = "@string/appbar_scrolling_view_behavior",
    nestedScrollingEnabled = true,
  },
  {
    BottomNavigationView,
    id = "bottom_nav",
    layout_width = "fill",
    layout_height = "wrap",
    layout_gravity = "bottom",
    layout_behavior = "@string/hide_bottom_view_on_scroll_behavior",
    labelVisibilityMode = BottomNavigationView.LABEL_VISIBILITY_LABELED,
  }
}