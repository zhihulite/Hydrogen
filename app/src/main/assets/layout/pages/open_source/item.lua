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
  L.text("name", AppTextStyle.titleSmall, nil, { textColor = colors.primary }),
  L.text("message", AppTextStyle.bodySmall, nil, { layout_marginTop = AppSpacing.xs, visibility = View.GONE })
}
,
L.text("license", AppTextStyle.bodySmall, nil, { layout_marginLeft = AppSpacing.md })
)
