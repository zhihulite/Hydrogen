-- layout/cards/basic.lua
-- 基础卡片（通用列表项）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"

local colors = AppTheme.colors

local circleShapeBuilder = ShapeAppearanceModel.builder()
circleShapeBuilder.allCornerSizes = RelativeCornerSize(0.5)
local circleShapeModel = circleShapeBuilder.build()

return {
  LinearLayoutCompat,
  layout_width = "match_parent",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "card",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_marginLeft = AppCardStyle.basic.marginLeft,
    layout_marginRight = AppCardStyle.basic.marginRight,
    layout_marginTop = AppCardStyle.basic.marginTop,
    layout_marginBottom = AppCardStyle.basic.marginBottom,
    cardBackgroundColor = colors.surface,
    strokeColor = colors.outline,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      paddingLeft = AppCardStyle.basic.innerPaddingLeft,
      paddingRight = AppCardStyle.basic.innerPaddingRight,
      paddingTop = AppCardStyle.basic.innerPaddingTop,
      paddingBottom = AppCardStyle.basic.innerPaddingBottom,
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
        layout_width = 0,
        layout_weight = 1,
        {
          MaterialTextView,
          id = "title",
          textColor = AppTextStyle.titleSmall.color,
          textSize  = AppTextStyle.titleSmall.size,
          typeface  = AppTextStyle.titleSmall.font,
          maxLines  = 2,
          ellipsize = "end",
        },
        {
          MaterialTextView,
          id = "preview",
          textColor = AppTextStyle.bodyMedium.color,
          textSize  = AppTextStyle.bodyMedium.size,
          typeface  = AppTextStyle.bodyMedium.font,
          layout_marginTop = "4dp",
          maxLines  = 3,
          ellipsize = "end",
          visibility = View.GONE,
        },
        {
          MaterialTextView,
          id = "bottom_text",
          textColor = AppTextStyle.bodyMedium.color,
          textSize  = AppTextStyle.bodyMedium.size,
          typeface  = AppTextStyle.bodyMedium.font,
          layout_marginTop = "4dp",
          visibility = View.GONE,
        }
      }
    }
  }
}