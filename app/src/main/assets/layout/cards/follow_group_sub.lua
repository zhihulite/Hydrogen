-- layout/cards/follow_group_sub.lua
-- 关注流分组子项布局（普通内容）

import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

return L.card({
  style = "child",
  paddingStyle = "basic",
  cardBackgroundColor = colors.surfaceVariant,
  strokeColor = colors.outline,
  inner = { layout_width = "fill", layout_height = "wrap_content" },
},
L.text("title", AppTextStyle.titleSmall, nil, { maxLines = 2, ellipsize = "end" }),
L.text("preview", AppTextStyle.bodyMedium, nil,
{ layout_marginTop = AppSpacing.sm, maxLines = 2, ellipsize = "end", visibility = View.GONE }),
L.text("desc", AppTextStyle.bodySmall, nil, { layout_marginTop = AppSpacing.sm, maxLines = 1, ellipsize = "end" })
)
