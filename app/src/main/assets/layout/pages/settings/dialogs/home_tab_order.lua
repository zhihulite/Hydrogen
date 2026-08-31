-- layout/pages/settings/dialogs/home_tab_order.lua
-- 主页Tab排序弹窗

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.recyclerview.widget.RecyclerView"

return {
  LinearLayoutCompat,
  orientation = "vertical",
  {
    RecyclerView,
    id = "recycler",
    layout_width = "match_parent",
    layout_height = "wrap_content",
  }
}