-- layout/pages/settings/dialogs/block_words.lua
-- 屏蔽词设置弹窗

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatEditText"

return {
  LinearLayoutCompat,
  orientation = "vertical",
  padding = "16dp",
  {
    AppCompatEditText,
    id = "edit",
    hint = "输入屏蔽词，用空格分隔",
    layout_width = "fill",
    maxLines = 5,
    textColor = AppTextStyle.body.color,
    typeface = AppTextStyle.body.font,
    textSize = AppTextStyle.body.size
  }
}