-- layout/pages/settings/items/title.lua
-- 设置页面分组标题

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "44dp",
  gravity = "center_vertical",
  {
    MaterialTextView,
    id = "title",
    layout_marginLeft = "20dp",
    textSize  = AppTextStyle.labelSmall.size,
    textColor = AppTextStyle.labelSmall.color,
    typeface  = AppTextStyle.labelSmall.font
  }
}