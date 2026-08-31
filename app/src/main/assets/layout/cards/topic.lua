-- layout/cards/topic.lua
-- 话题内容列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return L.card({ style = "basic" },
L.text("title", AppTextStyle.titleSmall, nil),
L.text("preview", AppTextStyle.bodyMedium, nil, { layout_marginTop = AppSpacing.sm, maxLines = 3, ellipsize = "end" }),
L.text("bottom_text", AppTextStyle.bodySmall, nil, { layout_marginTop = AppSpacing.sm }),
{
  LinearLayoutCompat,
  id = "stats_layout",
  orientation = "horizontal",
  layout_marginTop = AppSpacing.md,
  L.metric("voteup", "twotone_thumb_up", {gap = "4dp"}),
  L.metric("comment", "twotone_message", {gap = "4dp", marginLeft = "16dp"})
}
)