-- layout/pages/home/page_collections.lua
-- 收藏夹页面布局（TabLayout + ViewPager）

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
    elevation = "4dp",
    tabMode = TabLayout.MODE_FIXED,
    tabGravity = TabLayout.GRAVITY_FILL,
  },
  {
    CustomViewPager,
    id = "view_pager",
    layout_width = "fill",
    layout_height = "fill",
    nestedScrollingEnabled = true,
  },
}