-- layout/cards/underline.lua
-- 用户划线内容卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.divider.MaterialDivider"

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
    layout_marginLeft = "16dp",
    layout_marginRight = "16dp",
    layout_marginTop = "4dp",
    layout_marginBottom = "4dp",
    cardBackgroundColor = colors.surface,
    strokeColor = colors.outline,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      padding = "16dp",
      {
        MaterialTextView,
        id = "content",
        textSize  = AppTextStyle.bodyMedium.size,
        textColor = AppTextStyle.bodyMedium.color,
        typeface  = AppTextStyle.bodyMedium.font,
        maxLines  = 5,
        ellipsize = "end",
      },
      {
        MaterialDivider,
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "8dp",
      },
      {
        MaterialTextView,
        id = "source_title",
        textSize  = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface  = AppTextStyle.bodySmall.font,
        layout_marginTop = "8dp",
        maxLines  = 1,
        ellipsize = "end",
      },
      {
        MaterialTextView,
        id = "bottom_text",
        textSize  = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface  = AppTextStyle.bodySmall.font,
        layout_marginTop = "4dp",
      }
    }
  }
}