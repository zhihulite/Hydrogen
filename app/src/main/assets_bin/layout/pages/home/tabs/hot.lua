-- layout/pages/home/tabs/hot.lua
-- 热榜页面布局（SwipeRefreshLayout + RecyclerView）

import "android.widget.FrameLayout"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.hydrogen.view.CustomSwipeRefresh"
import "androidx.recyclerview.widget.RecyclerView"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  padding = "8dp",
  {
    CustomSwipeRefresh,
    id = "swipe_refresh",
    layout_height = "fill",
    layout_width = "fill",
    {
      RecyclerView,
      id = "recycler_view",
      layout_height = "fill",
      layout_width = "fill",
      nestedScrollingEnabled = true,
    }
  }
}