-- layout/pages/home/page_follow.lua
-- 关注页面布局（TabLayout + ViewPager）

local L = Helpers.Layout

return L.pagerPage({
  tabId = "tab_layout",
  pagerId = "view_pager",
})