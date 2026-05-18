-- layout/pages/home/page_follow.lua
-- 关注页面布局（TabLayout + ViewPager）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.tabs.TabLayout"
import "com.hydrogen.view.CustomViewPager"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  {
    TabLayout,
    id = "tab_layout",
    layout_width = "fill",
    layout_height = "wrap",
    tabMode = TabLayout.MODE_SCROLLABLE,
    tabGravity = TabLayout.GRAVITY_FILL,
  },
  {
    CustomViewPager,
    id = "view_pager",
    layout_width = "fill",
    layout_height = "fill",
    nestedScrollingEnabled = true,
  }
}