-- layout/cards/think.lua
-- 想法卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"

local colors = AppTheme.colors

local L = Helpers.Layout

local imageShapeBuilder = ShapeAppearanceModel.builder()
imageShapeBuilder.allCornerSizes = RelativeCornerSize(0.03)
local imageShapeModel = imageShapeBuilder.build()

return L.card({ style = "basic", cardBackgroundColor = colors.surface },
L.text("title", AppTextStyle.bodyMedium, nil, { layout_width = "fill", layout_height = "wrap_content", maxLines = 10, ellipsize = "end" }),
{
  ShapeableImageView,
  id = "image",
  layout_width = "fill",
  layout_height = "200dp",
  layout_marginTop = AppSpacing.lg,
  scaleType = "centerCrop",
  shapeAppearanceModel = imageShapeModel,
  visibility = View.GONE,
},
{
  LinearLayoutCompat,
  orientation = "horizontal",
  layout_width = "fill",
  layout_height = "wrap_content",
  layout_marginTop = AppSpacing.lg,
  L.metric("like", "twotone_thumb_up", {iconSize = "20dp", gap = "4dp", padding = "8dp"}),
  L.metric("comment", "twotone_message", {iconSize = "20dp", gap = "4dp", padding = "8dp"})
})