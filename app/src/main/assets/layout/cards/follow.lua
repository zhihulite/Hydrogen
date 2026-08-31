-- layout/cards/follow.lua
-- 关注流卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"
import "android.view.View"

local L = Helpers.Layout

local circleShapeModel = L.circleShape()
return L.card({ style = "basic", inner = { layout_width = "fill", layout_height = "wrap_content"} },
L.text("group_badge", AppTextStyle.labelSmall, "为你推荐", { layout_marginBottom = AppSpacing.sm, visibility = View.GONE }),
{
  LinearLayoutCompat,
  orientation = "horizontal",
  layout_width = "fill",
  {
    ShapeableImageView,
    id = "avatar",
    layout_width = "28dp",
    layout_height = "28dp",
    shapeAppearanceModel = circleShapeModel,
  },
  L.text("action_text", AppTextStyle.bodySmall, nil, { layout_marginLeft = AppSpacing.lg, layout_weight = 1, maxLines = 1, ellipsize = "end", layout_gravity = "center" })
},
L.text("title", AppTextStyle.titleSmall, nil, { layout_marginTop = AppSpacing.md, maxLines = 2, ellipsize = "end" }),
L.text("preview", AppTextStyle.bodyMedium, nil, { layout_marginTop = AppSpacing.sm, maxLines = 3, ellipsize = "end", visibility = View.GONE }),
{
  LinearLayoutCompat,
  id = "stats_layout",
  orientation = "horizontal",
  layout_marginTop = AppSpacing.md,
  L.metric("like", "twotone_thumb_up", {gap = "4dp"}),
  L.metric("comment", "twotone_message", {gap = "4dp", marginLeft = "16dp"})
}
)