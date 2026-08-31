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
    layout_marginLeft = AppCardStyle.basic.marginLeft,
    layout_marginRight = AppCardStyle.basic.marginRight,
    layout_marginTop = AppCardStyle.basic.marginTop,
    layout_marginBottom = AppCardStyle.basic.marginBottom,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      paddingLeft = AppCardStyle.basic.innerPaddingLeft,
      paddingRight = AppCardStyle.basic.innerPaddingRight,
      paddingTop = AppCardStyle.basic.innerPaddingTop,
      paddingBottom = AppCardStyle.basic.innerPaddingBottom,
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
          maxLines = 3,
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