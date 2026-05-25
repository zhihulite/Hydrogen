-- layout/pages/feedback/items/title_content.lua
-- 反馈页面标题与内容项

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  orientation = "vertical",
  padding = "16dp",
  {
    MaterialTextView,
    id = "title",
    textSize = AppTextStyle.titleSmall.size,
    textColor = AppTextStyle.titleSmall.color,
    typeface = AppTextStyle.titleSmall.font,
    layout_marginBottom = "8dp",
  },
  {
    MaterialTextView,
    id = "content",
    textSize = AppTextStyle.bodyMedium.size,
    textColor = AppTextStyle.bodyMedium.color,
    typeface = AppTextStyle.bodyMedium.font,
  }
}