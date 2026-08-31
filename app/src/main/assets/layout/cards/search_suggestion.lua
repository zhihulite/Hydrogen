-- layout/cards/search_suggestion.lua
-- 搜索建议/热词卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"

local L = Helpers.Layout

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap_content",
  orientation = "vertical",
  {
    MaterialCardView,
    id = "suggestion_card",
    layout_width = "fill",
    layout_height = "wrap_content",
    radius = 0,
    cardElevation = 0,
    cardBackgroundColor = colors.surface,
    strokeWidth = 0,
    clickable = true,
    L.text("text", AppTextStyle.titleSmall, nil, { layout_width = "fill", layout_height = "wrap", layout_marginLeft = AppCardStyle.basic.marginLeft, layout_marginRight = AppCardStyle.basic.marginRight, layout_marginTop = AppSpacing.lg, layout_marginBottom = AppSpacing.lg, maxLines = 2, ellipsize = "end", gravity = "center_vertical" })
  }
}