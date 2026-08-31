-- layout/common/search_input.lua
-- 搜索输入框布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatEditText"

return {
  LinearLayoutCompat,
  orientation = "vertical",
  padding = "16dp",
  {
    AppCompatEditText,
    id = "edit",
    hint = "输入搜索关键词",
    layout_width = "match_parent",
    textSize  = AppTextStyle.bodyMedium.size,
    textColor = AppTextStyle.bodyMedium.color,
    typeface  = AppTextStyle.bodyMedium.font,
  }
}