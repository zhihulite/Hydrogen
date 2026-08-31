-- layout/pages/about/items/item.lua
-- 关于页面通用列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

return L.card({ style = "setting", noMargin = true, strokeWidth = 0, radius = 0, cardBackgroundColor = colors.surface, horizontal = true, inner = { layout_width = "fill", layout_height = "wrap", gravity = "center_vertical", minHeight = "56dp" } },
{
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = 0,
  layout_weight = 1,
  L.text("title", AppTextStyle.titleSmall, nil),
  L.text("summary", AppTextStyle.bodySmall, nil, { layout_marginTop = AppSpacing.xs, visibility = View.GONE })
}
,{
  AppCompatImageView,
  id = "arrow",
  layout_width = "20dp",
  layout_height = "20dp",
  layout_marginLeft = AppSpacing.md,
  layout_marginRight = AppSpacing.xl,
  imageBitmap = Helpers.Static.materialIcon("twotone_chevron_right"),
  colorFilter = colors.onSurfaceVariant,
  visibility = View.GONE,
}
)