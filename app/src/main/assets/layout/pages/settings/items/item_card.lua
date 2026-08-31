-- layout/pages/settings/items/item_card.lua
-- 设置页面通用列表项

import "androidx.appcompat.widget.AppCompatImageView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

return L.card({ style = "setting", strokeWidth = 0, radius = 0, cardBackgroundColor = colors.surfaceContainer, horizontal = true, inner = { layout_width = "fill", layout_height = "wrap", gravity = "center_vertical", minHeight = "56dp" } },
L.text("title", AppTextStyle.titleSmall, nil, { layout_width = 0, layout_weight = 1 }),
{
  AppCompatImageView,
  id = "arrow",
  layout_width = "24dp",
  layout_height = "24dp",
  imageBitmap = Helpers.Static.materialIcon("twotone_chevron_right"),
  colorFilter = colors.onSurfaceVariant,
  visibility = View.GONE,
}
)