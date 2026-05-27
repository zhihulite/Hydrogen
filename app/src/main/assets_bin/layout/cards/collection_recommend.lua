-- layout/cards/collection_recommend.lua
-- 收藏推荐卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "match_parent",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "card",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_marginLeft = AppCardStyle.basic.marginLeft,
    layout_marginRight = AppCardStyle.basic.marginRight,
    layout_marginTop = AppCardStyle.basic.marginTop,
    layout_marginBottom = AppCardStyle.basic.marginBottom,
    cardBackgroundColor = colors.surface,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      padding = "12dp",
      {
        MaterialTextView,
        id = "title",
        textSize = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface = AppTextStyle.titleSmall.font,
      },
      {
        MaterialTextView,
        id = "description",
        textSize = AppTextStyle.bodyMedium.size,
        textColor = AppTextStyle.bodyMedium.color,
        typeface = AppTextStyle.bodyMedium.font,
        maxLines = 2,
        layout_marginTop = "4dp",
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "4dp",
        {
          MaterialTextView,
          id = "creator",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
          layout_width = 0,
          layout_weight = 1,
        },
        {
          MaterialTextView,
          id = "stats",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
        }
      }
    }
  }
}