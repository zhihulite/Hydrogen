-- layout/pages/home/tabs/followed.lua
-- 关注页面子 Tab 布局（TabLayout + ViewPager）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.tabs.TabLayout"
import "com.hydrogen.view.CustomViewPager"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  padding = "8dp",
  {
    TabLayout,
    id = "sub_tab_layout",
    layout_width = "fill",
    layout_height = "48dp",
    tabMode = TabLayout.MODE_FIXED,
    tabGravity = TabLayout.GRAVITY_FILL,
  },
  {
    CustomViewPager,
    id = "sub_view_pager",
    layout_width = "fill",
    layout_height = "fill",
    nestedScrollingEnabled = true,
  }
}