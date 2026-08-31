-- layout/pages/home/page_collections.lua
-- 收藏夹页面布局（TabLayout + ViewPager）

local L = Helpers.Layout

return L.pagerPage({
  tabId = "tab_layout",
  pagerId = "view_pager",
  tabMode = TabLayout.MODE_FIXED,
  elevation = "4dp",
})