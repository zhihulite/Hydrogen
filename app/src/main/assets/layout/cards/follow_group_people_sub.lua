-- layout/cards/follow_group_people_sub.lua
-- 关注流分组子项布局（用户）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

local circleShapeModel = L.circleShape()
return L.card({
  style = "child",
  paddingStyle = "basic",
  horizontal = true,
  cardBackgroundColor = colors.surfaceVariant,
  strokeColor = colors.outline,
  inner = { layout_width = "fill", layout_height = "wrap_content", gravity = "center_vertical" },
},
{
  ShapeableImageView,
  id = "people_avatar",
  layout_width = "40dp",
  layout_height = "40dp",
  shapeAppearanceModel = circleShapeModel,
},
{
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = 0,
  layout_weight = 1,
  layout_marginLeft = AppSpacing.lg,
  L.text("people_name", AppTextStyle.titleSmall, nil,
  { layout_width = "wrap_content", maxLines = 1, ellipsize = "end" }),
  L.text("people_headline", AppTextStyle.bodySmall, nil,
  { layout_width = "wrap_content", layout_marginTop = AppSpacing.xs, maxLines = 1, ellipsize = "end" }),
  L.text("people_followers", AppTextStyle.bodySmall, nil,
  { layout_width = "wrap_content", layout_marginTop = AppSpacing.xs }),
}
)
