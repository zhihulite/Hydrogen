-- layout/pages/feedback/items/title_content.lua
-- 反馈页面标题与内容项

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  orientation = "vertical",
  padding = AppSpacing.content,
  L.text("title", AppTextStyle.titleSmall, nil, { layout_marginBottom = AppSpacing.md }),
  L.text("content", AppTextStyle.bodyMedium, nil)
}