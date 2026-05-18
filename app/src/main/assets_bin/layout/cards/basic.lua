-- layout/cards/basic.lua
-- 基础卡片（通用列表项）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"

local colors = AppTheme.getColors()

local circleShapeModel = ShapeAppearanceModel.builder()
  .setAllCornerSizes(RelativeCornerSize(0.5))
  .build()

return {
  LinearLayoutCompat,
  layout_width = "match_parent",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "card",
    layout_margin = "8dp",
    layout_marginLeft = "16dp",
    layout_marginRight = "16dp",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    cardBackgroundColor = colors.surface,
    strokeColor = colors.outline,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      padding = "16dp",
      {
        ShapeableImageView,
        id = "avatar",
        layout_width = "40dp",
        layout_height = "40dp",
        shapeAppearanceModel = circleShapeModel,
        visibility = View.GONE,
      },
      {
        LinearLayoutCompat,
        orientation = "vertical",
        layout_width = "0dp",
        layout_weight = 1,
        {
          MaterialTextView,
          id = "title",
          textColor = AppTextStyle.title.color,
          textSize  = AppTextStyle.title.size,
          typeface  = AppTextStyle.title.font,
          maxLines  = 2,
          ellipsize = "end",
        },
        {
          MaterialTextView,
          id = "preview",
          textColor = AppTextStyle.body.color,
          textSize  = AppTextStyle.body.size,
          typeface  = AppTextStyle.body.font,
          layout_marginTop = "4dp",
          maxLines  = 3,
          ellipsize = "end",
          visibility = View.GONE,
        },
        {
          MaterialTextView,
          id = "bottom_text",
          textColor = AppTextStyle.body.color,
          textSize  = AppTextStyle.body.size,
          typeface  = AppTextStyle.body.font,
          layout_marginTop = "4dp",
          visibility = View.GONE,
        }
      }
    }
  }
}