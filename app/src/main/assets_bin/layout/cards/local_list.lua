-- layout/cards/local_list.lua
-- 本地内容列表项卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  {
    MaterialCardView,
    id = "card",
    layout_width = "fill",
    layout_height = "wrap",
    layout_marginLeft = "16dp",
    layout_marginRight = "16dp",
    layout_marginTop = "2dp",
    layout_marginBottom = "2dp",
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      padding = "12dp",
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        gravity = "center_vertical",
        {
          MaterialTextView,
          id = "title",
          layout_width = 0,
          layout_weight = 1,
          textSize = AppTextStyle.titleSmall.size,
          textColor = AppTextStyle.titleSmall.color,
          typeface = AppTextStyle.titleSmall.font,
          maxLines = 1,
          ellipsize = "end",
        },
        {
          MaterialTextView,
          id = "count",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
          layout_marginLeft = "8dp",
        }
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_marginTop = "4dp",
        {
          MaterialTextView,
          id = "time",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
          layout_width = 0,
          layout_weight = 1,
        }
      }
    }
  }
}