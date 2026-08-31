-- layout/pages/simple_list/main.lua
-- 简单列表页面主布局

return Helpers.Layout.listPage({
  toolbar = "toolbar",
  refreshId = "swipe_refresh",
  recyclerId = "recycler_view",
})