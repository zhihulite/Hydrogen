-- layout/cards/question_answer.lua
-- 问题回答列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"

local colors = AppTheme.colors

local L = Helpers.Layout

local circleShapeModel = L.circleShape()
return L.card({ style = "basic", cardBackgroundColor = colors.surface, strokeColor = colors.outline, inner = { layout_width = "fill", layout_height = "wrap_content" } },
{
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap_content",
  gravity = "center_vertical",
  {
    ShapeableImageView,
    id = "avatar",
    layout_width = "36dp",
    layout_height = "36dp",
    shapeAppearanceModel = circleShapeModel,
  },
  L.text("title", AppTextStyle.titleSmall, nil, { layout_width = 0, layout_weight = 1, layout_height = "wrap_content", layout_marginLeft = "10dp" })
},
L.text("preview", AppTextStyle.bodyMedium, nil, { layout_width = "fill", layout_height = "wrap_content", layout_marginTop = AppSpacing.md, maxLines = 3, ellipsize = "end" }),
{
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap_content",
  layout_marginTop = "10dp",
  gravity = "center_vertical",
  L.metric("like", "twotone_thumb_up", {gap = "4dp"}),
  L.metric("comment", "twotone_message", {gap = "4dp", marginLeft = "16dp"})
}
)