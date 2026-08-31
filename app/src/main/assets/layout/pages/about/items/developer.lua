-- layout/pages/about/items/developer.lua
-- 关于页面开发者列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.imageview.ShapeableImageView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

local avatarShapeModel = L.circleShape()
return L.card({ style = "setting", noMargin = true, strokeWidth = 0, radius = 0, cardBackgroundColor = colors.surface, horizontal = true, inner = { layout_width = "fill", layout_height = "wrap", gravity = "center_vertical", minHeight = "72dp" } },
{
  ShapeableImageView,
  id = "avatar",
  layout_width = "44dp",
  layout_height = "44dp",
  shapeAppearanceModel = avatarShapeModel,
  strokeWidth = "1dp",
}
,{
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = 0,
  layout_weight = 1,
  layout_marginLeft = AppSpacing.lg,
  L.text("title", AppTextStyle.titleSmall, nil),
  L.text("summary", AppTextStyle.bodySmall, nil, { layout_marginTop = AppSpacing.xs })
}
,{
  AppCompatImageView,
  id = "external_icon",
  layout_width = "20dp",
  layout_height = "20dp",
  layout_marginRight = AppSpacing.xl,
  imageBitmap = Helpers.Static.materialIcon("twotone_open_in_new"),
  colorFilter = colors.onSurfaceVariant,
  visibility = View.GONE,
}
)