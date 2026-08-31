-- layout/pages/open_source/item.lua
-- 开源许可列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

return L.card({ style = "setting", noMargin = true, strokeWidth = 0, radius = 0, horizontal = true, inner = { layout_width = "fill", layout_height = "wrap", gravity = "center_vertical", minHeight = "56dp" } },
{
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = 0,
  layout_weight = 1,
  L.text("name", AppTextStyle.titleSmall, nil, { textColor = colors.primary }), -- 保留品牌色强调
  L.text("message", AppTextStyle.bodyMedium, nil, { layout_marginTop = AppSpacing.sm, visibility = View.GONE })
},
L.text("license", AppTextStyle.bodySmall, nil, { layout_marginLeft = AppSpacing.md, paddingLeft = "8dp", paddingRight = "8dp", paddingTop = "4dp", paddingBottom = "4dp" })
)
