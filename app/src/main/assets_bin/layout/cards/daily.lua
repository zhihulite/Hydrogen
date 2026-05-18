-- layout/cards/daily.lua
-- 日报卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"

local colors = AppTheme.getColors()

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "card",
    layout_width = "fill",
    layout_height = "wrap_content",
    layout_margin = "8dp",
    layout_marginLeft = "16dp",
    layout_marginRight = "16dp",
    strokeColor = colors.outline,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "fill",
      layout_height = "wrap_content",
      padding = "12dp",
      gravity = "center_vertical",
      {
        MaterialTextView,
        id = "title",
        layout_width = "fill",
        layout_height = "wrap_content",
        textSize = AppTextStyle.title.size,
        textColor = AppTextStyle.title.color,
        typeface = AppTextStyle.title.font,
        maxLines = 3,
        ellipsize = "end",
      },
    },
  },
}