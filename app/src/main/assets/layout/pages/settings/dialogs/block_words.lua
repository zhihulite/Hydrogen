-- layout/pages/settings/dialogs/block_words.lua
-- 屏蔽词设置弹窗

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  orientation = "vertical",
  padding = AppSpacing.content,
  L.edit("edit", AppTextStyle.bodyMedium, "输入屏蔽词，用空格分隔", { maxLines = 5 })
}
