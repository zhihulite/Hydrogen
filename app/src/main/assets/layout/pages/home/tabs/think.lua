-- layout/pages/home/tabs/think.lua
-- 想法页面布局（SwipeRefreshLayout + RecyclerView）

local L = Helpers.Layout

return L.refreshList({
  refreshId = "swipe_refresh",
  recyclerId = "recycler_view",
  padding = AppSpacing.list,
})