-- layout/pages/settings/items/slider_card.lua
-- 设置页面滑块项

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.slider.Slider"

local L = Helpers.Layout

local colors = AppTheme.colors

return L.card({ style = "setting", strokeWidth = 0, radius = 0, cardBackgroundColor = colors.surfaceContainer, inner = { layout_width = "fill", layout_height = "wrap", minHeight = "56dp" } },
L.text("title", AppTextStyle.titleSmall, nil, { layout_marginTop = AppSpacing.lg })
,{
  LinearLayoutCompat,
  orientation = "horizontal",
  layout_width = "fill",
  layout_marginTop = AppSpacing.md,
  layout_marginBottom = AppSpacing.lg,
  gravity = "center_vertical",
  {
    Slider,
    id = "slider",
    layout_weight = 1,
  },
  L.text("value", AppTextStyle.bodySmall, nil, { layout_marginLeft = AppSpacing.xl, minWidth = "40dp" })
}
)