-- layout/cards/history.lua
-- 历史记录卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "android.view.View"

local colors = AppTheme.getColors()

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
          cardElevation = "0dp",
          cardBackgroundColor = colors.primary,
          {
            MaterialTextView,
            id = "type_text",
            textSize = AppTextStyle.caption.size,
            textColor = colors.surfaceBright,
            typeface = AppTextStyle.caption.font,
            paddingLeft = "10dp",
            paddingRight = "10dp",
            layout_gravity = "center",
          }
        },
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
        }
      },
      {
        MaterialTextView,
        id = "preview",
        layout_marginTop = "4dp",
        textSize = AppTextStyle.caption.size,
        textColor = AppTextStyle.caption.color,
        typeface = AppTextStyle.caption.font,
        maxLines = 2,
        ellipsize = "end",
        visibility = View.GONE,
      }
    }
  }
}