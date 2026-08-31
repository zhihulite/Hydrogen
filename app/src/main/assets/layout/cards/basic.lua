-- layout/cards/basic.lua
-- 基础卡片（通用列表项）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

local circleShapeModel = L.circleShape()
return L.card({ style = "basic", cardBackgroundColor = colors.surface, strokeColor = colors.outline, inner = { orientation = "horizontal" } },
{
  ShapeableImageView,
  id = "avatar",
  layout_width = "40dp",
  layout_height = "40dp",
  layout_marginRight = AppSpacing.lg,
  shapeAppearanceModel = circleShapeModel,
  visibility = View.GONE,
},
{
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = 0,
  layout_weight = 1,
  L.text("title", AppTextStyle.titleSmall, nil, { maxLines = 2, ellipsize = "end" }),
  L.text("preview", AppTextStyle.bodyMedium, nil, { layout_marginTop = AppSpacing.sm, maxLines = 3, ellipsize = "end", visibility = View.GONE }),
  L.text("bottom_text", AppTextStyle.bodyMedium, nil, { layout_marginTop = AppSpacing.sm, visibility = View.GONE })
}
)