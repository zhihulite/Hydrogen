-- layout/cards/search_suggestion.lua
-- 搜索建议/热词卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.card.MaterialCardView"

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  layout_width = "match_parent",
  layout_height = "wrap_content",
  orientation = "vertical",
  {
    MaterialCardView,
    id = "suggestion_card",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    radius = 0,
    cardElevation = 0,
    cardBackgroundColor = colors.surface,
    strokeWidth = 0,
    clickable = true,
    {
      MaterialTextView,
      id = "text",
      layout_width = "match_parent",
      layout_height = "wrap",
      layout_marginLeft = AppCardStyle.basic.marginLeft,
      layout_marginRight = AppCardStyle.basic.marginRight,
      layout_marginTop = "12dp",
      layout_marginBottom = "12dp",
      textSize = AppTextStyle.titleSmall.size,
      textColor = AppTextStyle.titleSmall.color,
      typeface = AppTextStyle.titleSmall.font,
      maxLines = 2,
      ellipsize = "end",
      gravity = "center_vertical",
    }
  }
}