-- layout/pages/history/main.lua
-- 历史记录页面主布局

import "android.view.View"

local L = Helpers.Layout

return L.listPage({
  toolbar = "toolbar",
  tabsId = "tab_layout",
  refreshId = "swipe_refresh",
  recyclerId = "recycler_view",
  empty = L.emptyState({
    icon = Helpers.Static.materialIcon("twotone_history"),
    iconTint = AppTheme.colors.onSurfaceVariant,
    title = "暂无历史记录",
    subtitle = "浏览过的内容会显示在这里",
  }),
})
