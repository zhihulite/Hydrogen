-- layout/cards/follow_group_people_sub.lua
-- 关注流分组子项布局（用户）

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
    layout_marginLeft = AppCardStyle.child.marginLeft,
    layout_marginRight = AppCardStyle.child.marginRight,
    layout_marginTop = AppCardStyle.child.marginTop,
    layout_marginBottom = AppCardStyle.child.marginBottom,
    cardBackgroundColor = colors.surfaceVariant,
    strokeColor = colors.outline,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      padding = "12dp",
      gravity = "center_vertical",
      {
        ShapeableImageView,
        id = "people_avatar",
        layout_width = "40dp",
        layout_height = "40dp",
        shapeAppearanceModel = circleShape,
      },
      {
        LinearLayoutCompat,
        orientation = "vertical",
        layout_width = 0,
        layout_weight = 1,
        layout_marginLeft = "12dp",
        {
          MaterialTextView,
          id = "people_name",
          layout_width = "wrap_content",
          textSize = AppTextStyle.titleSmall.size,
          textColor = AppTextStyle.titleSmall.color,
          typeface = AppTextStyle.titleSmall.font,
          maxLines = 1,
          ellipsize = "end",
        },
        {
          MaterialTextView,
          id = "people_headline",
          layout_width = "wrap_content",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
          layout_marginTop = "2dp",
          maxLines = 1,
          ellipsize = "end",
        },
        {
          MaterialTextView,
          id = "people_followers",
          layout_width = "wrap_content",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
          layout_marginTop = "2dp",
        }
      }
    }
  }
}