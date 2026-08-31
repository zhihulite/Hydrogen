-- layout/pages/home/page_daily.lua
-- 日报页面布局（SwipeRefreshLayout + RecyclerView）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.hydrogen.view.CustomSwipeRefresh"
import "androidx.recyclerview.widget.RecyclerView"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  {
    CustomSwipeRefresh,
    id = "swipe_refresh",
    layout_width = "fill",
    layout_height = "fill",
    {
      RecyclerView,
      id = "recycler_view",
      layout_width = "fill",
      layout_height = "fill",
      nestedScrollingEnabled = true,
    },
  },
}