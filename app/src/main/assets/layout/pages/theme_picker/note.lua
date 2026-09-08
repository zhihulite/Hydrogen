-- layout/pages/theme_picker/note.lua
-- 分组说明（灰色小字）

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  paddingLeft = AppSpacing.xl,
  paddingRight = AppSpacing.xl,
  paddingTop = "2dp",
  paddingBottom = "2dp",
  L.text("note", AppTextStyle.bodySmall, ""),
}
