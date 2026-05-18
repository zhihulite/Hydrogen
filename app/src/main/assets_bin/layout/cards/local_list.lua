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
          layout_width = "0dp",
          layout_weight = 1,
          textSize = AppTextStyle.title.size,
          textColor = AppTextStyle.title.color,
          typeface = AppTextStyle.title.font,
          maxLines = 1,
          ellipsize = "end",
        },
        {
          MaterialTextView,
          id = "count",
          textSize = AppTextStyle.caption.size,
          textColor = AppTextStyle.caption.color,
          typeface = AppTextStyle.caption.font,
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
          textSize = AppTextStyle.caption.size,
          textColor = AppTextStyle.caption.color,
          typeface = AppTextStyle.caption.font,
          layout_width = "0dp",
          layout_weight = 1,
        }
      }
    }
  }
}