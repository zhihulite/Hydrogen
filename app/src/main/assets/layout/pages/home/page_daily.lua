-- layout/pages/home/page_daily.lua
-- 日报页面布局（SwipeRefreshLayout + RecyclerView）

local L = Helpers.Layout

return L.refreshList({
  refreshId = "swipe_refresh",
  recyclerId = "recycler_view",
  orientation = "vertical",
})