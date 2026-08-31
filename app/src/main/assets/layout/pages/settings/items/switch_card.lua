-- layout/pages/settings/items/switch_card.lua
-- 设置页面开关项（标题 + 副标题 + 开关）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.materialswitch.MaterialSwitch"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

return L.card({ style = "setting", strokeWidth = 0, radius = 0, cardBackgroundColor = colors.surfaceContainer, horizontal = true, inner = { layout_width = "fill", layout_height = "wrap", gravity = "center_vertical", minHeight = "56dp" } },
{
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = 0,
  layout_weight = 1,
  L.text("title", AppTextStyle.titleSmall, nil),
  L.text("summary", AppTextStyle.bodySmall, nil, { layout_marginTop = AppSpacing.xs, visibility = View.GONE })
},
{
  MaterialSwitch,
  id = "switch_btn",
  layout_marginLeft = AppSpacing.md,
  focusable = false,
  clickable = false,
}
)