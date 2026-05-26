-- layout/cards/people_list.lua
-- 用户列表卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"

local colors = AppTheme.colors

local circleShapeBuilder = ShapeAppearanceModel.builder()
circleShapeBuilder.allCornerSizes = RelativeCornerSize(0.5)
local circleShapeModel = circleShapeBuilder.build()

return {
  LinearLayoutCompat,
  id = "root",
  layout_width = "match_parent",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "card",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_margin = "8dp",
    layout_marginLeft = "16dp",
    layout_marginRight = "16dp",
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "match_parent",
      padding = "12dp",
      gravity = "center_vertical",
      {
        ShapeableImageView,
        id = "avatar",
        layout_width = "48dp",
        layout_height = "48dp",
        shapeAppearanceModel = circleShapeModel,
      },
      {
        LinearLayoutCompat,
        orientation = "vertical",
        layout_weight = 1,
        layout_marginLeft = "12dp",
        {
          MaterialTextView,
          id = "title",
          textSize = AppTextStyle.titleSmall.size,
          textColor = AppTextStyle.titleSmall.color,
          typeface = AppTextStyle.titleSmall.font,
          maxLines = 1,
          ellipsize = "end",
        },
        {
          MaterialTextView,
          id = "preview",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
          layout_marginTop = "2dp",
          maxLines = 1,
          ellipsize = "end",
        }
      },
      {
        MaterialButton,
        id = "action_btn",
        layout_width = "wrap_content",
        layout_height = "wrap_content",
        textSize = AppTextStyle.bodySmall.size,
        typeface = AppTextStyle.bodySmall.font,
        paddingLeft = "12dp",
        paddingRight = "12dp",
      }
    }
  }
}