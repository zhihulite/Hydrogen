-- layout/cards/comment_children.lua
-- 子评论列表项布局（紧凑行，无卡片）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"
import "android.view.View"

local L = Helpers.Layout

local circleShapeModel = L.circleShape()
return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap_content",
  orientation = "horizontal",
  paddingTop = "6dp",
  paddingBottom = "6dp",
  id = "card",
  {
    ShapeableImageView,
    id = "avatar",
    layout_width = "28dp",
    layout_height = "28dp",
    shapeAppearanceModel = circleShapeModel,
    layout_marginTop = AppSpacing.xs,
  },
  {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "wrap_content",
    layout_marginLeft = AppSpacing.md,
    id = "content_container",
    L.text("author_name", AppTextStyle.titleSmall, nil, { layout_width = "wrap_content", layout_height = "wrap_content", maxLines = 1, ellipsize = "end" }),
    L.text("comment_content", AppTextStyle.bodyMedium, nil, { layout_width = "fill", layout_height = "wrap_content", layout_marginTop = AppSpacing.xs }),
    {
      -- 子评论图片
      ShapeableImageView,
      id = "comment_image",
      layout_width = "wrap_content",
      layout_height = "wrap_content",
      layout_marginTop = AppSpacing.sm,
      visibility = View.GONE,
      scaleType = "centerCrop",
    },
    {
      LinearLayoutCompat,
      layout_width = "fill",
      layout_height = "wrap_content",
      layout_marginTop = AppSpacing.sm,
      orientation = "horizontal",
      gravity = "center_vertical",
      L.text("comment_bottom", AppTextStyle.bodySmall, nil, { layout_width = "wrap_content", layout_height = "wrap_content" }),
      {
        View,
        layout_width = 0,
        layout_weight = 1,
        layout_height = "1dp",
      },
      L.metric("like", "outline_favorite_border", {iconSize = "14dp", gap = "2dp"})
    }
  }
}