-- layout/cards/search_result.lua
-- 搜索结果卡片

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return L.card({ style = "basic" },
L.text("action_text", AppTextStyle.bodySmall, "添加了内容"),
L.text("title", AppTextStyle.titleSmall, "标题", { layout_marginTop = AppSpacing.md, maxLines = 2, ellipsize = "end" }),
L.text("preview", AppTextStyle.bodyMedium, "预览内容", { layout_marginTop = "6dp", maxLines = 3, ellipsize = "end" }),
{
  LinearLayoutCompat,
  orientation = "horizontal",
  layout_marginTop = AppSpacing.md,
  gravity = "end",
  L.metric("like", "twotone_thumb_up", {gap = "4dp"}),
  L.metric("comment", "twotone_message", {gap = "4dp", marginLeft = "16dp"})
}
)