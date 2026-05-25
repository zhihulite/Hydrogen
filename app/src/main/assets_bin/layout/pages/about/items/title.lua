-- layout/pages/about/items/title.lua
-- 关于页面分组标题

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  gravity = "center_vertical",
  {
    MaterialTextView,
    id = "title",
    layout_marginLeft = "16dp",
    layout_marginTop = "16dp",
    layout_marginBottom = "8dp",
    textSize = AppTextStyle.labelSmall.size,
    textColor = AppTextStyle.labelSmall.color,
    typeface = AppTextStyle.labelSmall.font,
  }
}