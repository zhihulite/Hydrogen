-- layout/pages/home/tabs/recommend.lua
-- 推荐页面布局（TabLayout + SwipeRefreshLayout + RecyclerView，多列网格）

import "android.widget.FrameLayout"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.tabs.TabLayout"
import "com.hydrogen.view.CustomSwipeRefresh"
import "androidx.recyclerview.widget.RecyclerView"
import "androidx.recyclerview.widget.GridLayoutManager"
import "android.view.View"

local itemWidth = 300  -- 每个项目的宽度(dp)
local availableWidth = px2dp(activity.getWidth() / 2)
local columnCount = math.max(availableWidth // itemWidth, 1)

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  {
    TabLayout,
    id = "tab_layout",
    layout_width = "fill",
    layout_height = "wrap",
    tabMode = TabLayout.MODE_SCROLLABLE,
    tabGravity = TabLayout.GRAVITY_FILL,
    visibility = View.GONE,
  },
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
      LayoutManager = GridLayoutManager(activity, columnCount),
    }
  }
}