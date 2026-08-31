-- layout/cards/people_content.lua
-- 用户内容卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"
import "android.view.View"

local colors = AppTheme.colors

local L = Helpers.Layout

local circleShapeModel = L.circleShape()
return L.card({ style = "basic", cardBackgroundColor = colors.surfaceVariant, strokeColor = colors.outline, inner = { orientation = "horizontal" } },
{
  LinearLayoutCompat,
  orientation = "vertical",
  layout_weight = 1,
  {
    LinearLayoutCompat,
    orientation = "horizontal",
    gravity = "center_vertical",
    {
      ShapeableImageView,
      id = "avatar",
      layout_width = "20dp",
      layout_height = "20dp",
      shapeAppearanceModel = circleShapeModel,
    },
    L.text("action_text", AppTextStyle.bodySmall, nil, { layout_marginLeft = "6dp" })
  },
  L.text("title", AppTextStyle.titleSmall, nil, { layout_marginTop = AppSpacing.md }),
  L.text("preview", AppTextStyle.bodyMedium, nil, { maxLines = 3, ellipsize = "end", layout_marginTop = AppSpacing.md, visibility = View.GONE }),
  {
    LinearLayoutCompat,
    layout_marginTop = AppSpacing.md,
    orientation = "horizontal",
    L.metric("like", "twotone_thumb_up", {gap = "4dp"}),
    L.metric("comment", "twotone_message", {gap = "4dp", marginLeft = "16dp"})
  }
}
)