-- layout/pages/settings/items/switch_card.lua
-- 设置页面开关项

import "com.google.android.material.materialswitch.MaterialSwitch"

local L = Helpers.Layout

local colors = AppTheme.colors

return L.card({ style = "setting", strokeWidth = 0, radius = 0, cardBackgroundColor = colors.surfaceContainer, horizontal = true, inner = { layout_width = "fill", layout_height = "wrap", gravity = "center_vertical", minHeight = "56dp" } },
L.text("title", AppTextStyle.titleSmall, nil, { layout_width = 0, layout_weight = 1 })
,{
  MaterialSwitch,
  id = "switch_btn",
  layout_marginLeft = AppSpacing.md,
  focusable = false,
  clickable = false,
}
)