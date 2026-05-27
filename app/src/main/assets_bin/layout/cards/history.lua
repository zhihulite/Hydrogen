-- layout/cards/history.lua
-- 历史记录卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "android.view.View"

local colors = AppTheme.colors

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
      layout_width = "fill",
      orientation = "vertical",
      paddingLeft = "12dp",
      paddingRight = "12dp",
      paddingTop = "12dp",
      paddingBottom = "12dp",
      {
        LinearLayoutCompat,
        layout_width = "fill",
        orientation = "horizontal",
        gravity = "center_vertical",
        {
          MaterialCardView,
          id = "type_badge",
          layout_width = "wrap",
          layout_height = "24dp",
          radius = "12dp",
          layout_marginRight = "12dp",
          cardElevation = 0,
          cardBackgroundColor = colors.primary,
          {
            MaterialTextView,
            id = "type_text",
            textSize = AppTextStyle.bodySmall.size,
            textColor = colors.surfaceBright,
            typeface = AppTextStyle.bodySmall.font,
            paddingLeft = "10dp",
            paddingRight = "10dp",
            layout_gravity = "center",
          }
        },
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
        }
      },
      {
        MaterialTextView,
        id = "preview",
        layout_marginTop = "4dp",
        textSize = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface = AppTextStyle.bodySmall.font,
        maxLines = 2,
        ellipsize = "end",
        visibility = View.GONE,
      }
    }
  }
}