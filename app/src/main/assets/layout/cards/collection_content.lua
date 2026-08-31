-- layout/cards/collection_content.lua
-- 收藏夹内容列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"

local colors = AppTheme.colors

local L = Helpers.Layout

return L.card({ style = "basic", cardBackgroundColor = colors.surface, strokeColor = colors.outline, inner = { layout_width = "fill", layout_height = "wrap_content" } },
L.text("title", AppTextStyle.titleSmall, nil, { layout_width = "fill", layout_height = "wrap_content", maxLines = 2, ellipsize = "end" }),
L.text("preview", AppTextStyle.bodyMedium, nil, { layout_width = "fill", layout_height = "wrap_content", layout_marginTop = "6dp", maxLines = 3, ellipsize = "end" }),
{
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap_content",
  layout_marginTop = "10dp",
  orientation = "horizontal",
  L.metric("like", "twotone_thumb_up", {gap = "4dp"}),
  L.metric("comment", "twotone_message", {gap = "4dp", marginLeft = "16dp"})
}
)