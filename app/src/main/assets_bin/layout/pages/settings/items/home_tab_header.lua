-- layout/pages/settings/items/home_tab_header.lua
-- 主页Tab排序分组标题

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  {
    MaterialTextView,
    id = "header",
    layout_margin = "16dp",
    textSize = AppTextStyle.label.size,
    textColor = AppTextStyle.label.color,
    typeface = AppTextStyle.label.font
  }
}