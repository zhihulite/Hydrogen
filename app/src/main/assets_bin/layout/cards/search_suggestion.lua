-- layout/cards/search_suggestion.lua
-- 搜索建议/热词卡片

import "com.google.android.material.textview.MaterialTextView"

return {
  MaterialTextView,
  id = "text",
  layout_width = "match_parent",
  layout_height = "wrap",
  paddingLeft = "16dp",
  paddingRight = "16dp",
  paddingTop = "12dp",
  paddingBottom = "12dp",
  textSize  = AppTextStyle.title.size,
  textColor = AppTextStyle.title.color,
  typeface  = AppTextStyle.title.font,
  maxLines = 2,
  ellipsize = "end",
  gravity = "center_vertical",
}