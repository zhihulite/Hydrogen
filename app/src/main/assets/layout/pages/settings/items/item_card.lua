-- layout/pages/settings/items/item_card.lua
-- 设置页面通用列表项（标题 + 副标题 + 箭头）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
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
  AppCompatImageView,
  id = "arrow",
  layout_width = "24dp",
  layout_height = "24dp",
  layout_marginLeft = AppSpacing.md,
  imageBitmap = Helpers.Static.materialIcon("twotone_chevron_right"),
  colorFilter = colors.onSurfaceVariant,
  visibility = View.GONE,
}
)