-- layout/cards/people_content.lua
-- 用户内容卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
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
  orientation = "vertical",
  {
    MaterialCardView,
    id = "card",
    layout_height = "wrap_content",
    layout_width = "match_parent",
    layout_marginTop = "8dp",
    layout_marginBottom = "8dp",
    layout_marginLeft = "16dp",
    layout_marginRight = "16dp",
    cardBackgroundColor = colors.surfaceVariant,
    strokeColor = colors.outline,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      padding = "16dp",
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
          {
            MaterialTextView,
            id = "action_text",
            layout_marginLeft = "6dp",
            textSize  = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface  = AppTextStyle.bodySmall.font,
          }
        },
        {
          MaterialTextView,
          id = "title",
          textSize  = AppTextStyle.titleSmall.size,
          textColor = AppTextStyle.titleSmall.color,
          typeface  = AppTextStyle.titleSmall.font,
          layout_marginTop = "8dp",
        },
        {
          MaterialTextView,
          id = "preview",
          textSize  = AppTextStyle.bodyMedium.size,
          textColor = AppTextStyle.bodyMedium.color,
          typeface  = AppTextStyle.bodyMedium.font,
          maxLines = 3,
          ellipsize = "end",
          layout_marginTop = "8dp",
          visibility = View.GONE,
        },
        {
          LinearLayoutCompat,
          layout_marginTop = "8dp",
          orientation = "horizontal",
          {
            LinearLayoutCompat,
            id = "like_layout",
            gravity = "center",
            {
              AppCompatImageView,
              layout_width = "16dp",
              layout_height = "16dp",
              imageBitmap = Helpers.Static.materialIcon("twotone_thumb_up"),
              colorFilter = colors.onSurfaceVariant,
            },
            {
              MaterialTextView,
              id = "like_count",
              layout_marginLeft = "4dp",
              text = "0",
              textSize  = AppTextStyle.bodySmall.size,
              textColor = AppTextStyle.bodySmall.color,
              typeface  = AppTextStyle.bodySmall.font,
            }
          },
          {
            LinearLayoutCompat,
            id = "comment_layout",
            layout_marginLeft = "16dp",
            gravity = "center",
            {
              AppCompatImageView,
              layout_width = "16dp",
              layout_height = "16dp",
              imageBitmap = Helpers.Static.materialIcon("twotone_message"),
              colorFilter = colors.onSurfaceVariant,
            },
            {
              MaterialTextView,
              id = "comment_count",
              layout_marginLeft = "4dp",
              text = "0",
              textSize  = AppTextStyle.bodySmall.size,
              textColor = AppTextStyle.bodySmall.color,
              typeface  = AppTextStyle.bodySmall.font,
            }
          }
        }
      }
    }
  }
}