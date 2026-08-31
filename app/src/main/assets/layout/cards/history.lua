-- layout/cards/history.lua
-- 历史记录卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

return L.card({ inner = { layout_width = "fill" } },
{
  LinearLayoutCompat,
  layout_width = "fill",
  orientation = "horizontal",
  gravity = "center_vertical",
  {
    MaterialCardView,
    id = "type_badge",
    layout_width = "wrap",
    layout_height = "24dp",
    radius = "12dp",
    layout_marginRight = AppSpacing.lg,
    cardElevation = 0,
    cardBackgroundColor = colors.primary,
    L.text("type_text", AppTextStyle.bodySmall, nil,
    { textColor = colors.surfaceBright, paddingLeft = "10dp", paddingRight = "10dp", layout_gravity = "center" }),
  },
  L.text("title", AppTextStyle.titleSmall, nil,
  { layout_width = 0, layout_weight = 1, maxLines = 1, ellipsize = "end" }),
},
L.text("preview", AppTextStyle.bodySmall, nil,
{ layout_marginTop = AppSpacing.sm, maxLines = 2, ellipsize = "end", visibility = View.GONE })
)
