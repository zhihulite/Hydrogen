-- layout/common/search_input.lua
-- 搜索输入框布局

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  orientation = "vertical",
  padding = AppSpacing.content,
  L.edit("edit", AppTextStyle.bodyMedium, "输入搜索关键词")
}
