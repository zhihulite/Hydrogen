-- layout/cards/collection_recommend.lua
-- 收藏推荐卡片

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

local colors = AppTheme.colors

return L.card({ style = "basic", cardBackgroundColor = colors.surface, inner = { layout_width = "fill", layout_height = "wrap_content" } },
L.text("title", AppTextStyle.titleSmall, nil),
L.text("preview", AppTextStyle.bodyMedium, nil, { maxLines = 2, layout_marginTop = AppSpacing.sm }),
{
  LinearLayoutCompat,
  orientation = "horizontal",
  layout_width = "fill",
  layout_height = "wrap_content",
  layout_marginTop = AppSpacing.sm,
  L.text("creator", AppTextStyle.bodySmall, nil, { layout_width = 0, layout_weight = 1 }),
  L.text("stats", AppTextStyle.bodySmall, nil)
}
)