-- layout/pages/home/tabs/hot.lua
-- 热榜页面布局（SwipeRefreshLayout + RecyclerView）

local L = Helpers.Layout

return L.refreshList({
  refreshId = "swipe_refresh",
  recyclerId = "recycler_view",
  padding = AppSpacing.list,
})