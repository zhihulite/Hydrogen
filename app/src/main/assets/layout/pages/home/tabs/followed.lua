-- layout/pages/home/tabs/followed.lua
-- 关注页面子 Tab 布局（TabLayout + ViewPager）

local L = Helpers.Layout

return L.pagerPage({
  tabId = "sub_tab_layout",
  pagerId = "sub_view_pager",
  tabMode = TabLayout.MODE_FIXED,
  tabHeight = "48dp",
  padding = AppSpacing.list,
})