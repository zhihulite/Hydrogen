-- layout/cards/collection_recommend.lua
-- 收藏推荐卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"

local colors = AppTheme.getColors()

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "match_parent",
  layout_height = "wrap_content",
  paddingLeft = "16dp",
  paddingRight = "16dp",
  {
    MaterialCardView,
    id = "card",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_marginTop = "4dp",
    layout_marginBottom = "4dp",
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
        textSize = AppTextStyle.title.size,
        textColor = AppTextStyle.title.color,
        typeface = AppTextStyle.title.font,
      },
      {
        MaterialTextView,
        id = "description",
        textSize = AppTextStyle.body.size,
        textColor = AppTextStyle.body.color,
        typeface = AppTextStyle.body.font,
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
          textSize = AppTextStyle.caption.size,
          textColor = AppTextStyle.caption.color,
          typeface = AppTextStyle.caption.font,
          layout_width = "0dp",
          layout_weight = 1,
        },
        {
          MaterialTextView,
          id = "stats",
          textSize = AppTextStyle.caption.size,
          textColor = AppTextStyle.caption.color,
          typeface = AppTextStyle.caption.font,
        }
      }
    }
  }
}