-- layout/cards/recommend.lua
-- 首页推荐卡片

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return L.card({ style = "basic" },
L.text("title", AppTextStyle.titleSmall, nil, { maxLines = 2, ellipsize = "end" }),
L.text("preview", AppTextStyle.bodyMedium, nil, { maxLines = 3, ellipsize = "end", layout_marginTop = "6dp" }),
{
  LinearLayoutCompat,
  orientation = "horizontal",
  layout_marginTop = AppSpacing.md,
  L.metric("like", "twotone_thumb_up", {gap = "4dp"}),
  L.metric("comment", "twotone_message", {gap = "4dp", marginLeft = "16dp"})
}
)