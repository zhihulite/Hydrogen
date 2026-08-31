-- layout/pages/home/tabs/recommend.lua
-- 推荐页面布局（TabLayout + SwipeRefreshLayout + RecyclerView，多列网格）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.tabs.TabLayout"
import "com.hydrogen.view.CustomSwipeRefresh"
import "androidx.recyclerview.widget.RecyclerView"
import "android.view.View"

-- 网格列数由 RecommendModel:setupSingle 按容器实际宽度创建 GridLayoutManager 决定

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
      nestedScrollingEnabled = true
    }
  }
}