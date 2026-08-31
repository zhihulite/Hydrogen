-- layout/pages/local_list/main.lua
-- 本地内容列表页布局

local L = Helpers.Layout

return L.listPage({
  toolbar = "toolbar",
  refreshId = "swipe_refresh",
  recyclerId = "recycler_view",
  empty = L.emptyState({
    icon = Helpers.Static.materialIcon("twotone_inbox"),
    iconTint = AppTheme.colors.onSurfaceVariant,
    title = "暂无本地内容",
    subtitle = "在回答页面点击保存即可收藏",
  }),
})
