-- layout/cards/question_answer.lua
-- 问题回答列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"

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
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_marginLeft = "12dp",
    layout_marginRight = "12dp",
    layout_marginTop = "6dp",
    layout_marginBottom = "6dp",
    cardBackgroundColor = colors.surface,
    strokeColor = colors.outline,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      padding = "12dp",
      {
        LinearLayoutCompat,
        layout_width = "match_parent",
        layout_height = "wrap_content",
        gravity = "center_vertical",
        {
          ShapeableImageView,
          id = "avatar",
          layout_width = "36dp",
          layout_height = "36dp",
          shapeAppearanceModel = circleShapeModel,
        },
        {
          LinearLayoutCompat,
          layout_width = "0dp",
          layout_weight = 1,
          layout_height = "wrap_content",
          orientation = "vertical",
          layout_marginLeft = "10dp",
          {
            MaterialTextView,
            id = "title",
            layout_width = "wrap_content",
            layout_height = "wrap_content",
            textSize = AppTextStyle.title.size,
            textColor = AppTextStyle.title.color,
            typeface = AppTextStyle.title.font,
          },
        }
      },
      {
        MaterialTextView,
        id = "preview",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "8dp",
        textSize = AppTextStyle.body.size,
        textColor = AppTextStyle.body.color,
        typeface = AppTextStyle.body.font,
        maxLines = 3,
        ellipsize = "end",
      },
      {
        LinearLayoutCompat,
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "10dp",
        gravity = "center_vertical",
        {
          LinearLayoutCompat,
          id = "like_layout",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
          gravity = "center_vertical",
          {
            AppCompatImageView,
            layout_width = "16dp",
            layout_height = "16dp",
            ImageBitmap = Helpers.Static.materialIcon("twotone_thumb_up"),
            colorFilter = colors.onSurfaceVariant,
          },
          {
            MaterialTextView,
            id = "like_count",
            layout_marginLeft = "4dp",
            text = "0",
            textSize = AppTextStyle.caption.size,
            textColor = AppTextStyle.caption.color,
            typeface = AppTextStyle.caption.font,
          }
        },
        {
          LinearLayoutCompat,
          id = "comment_layout",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
          gravity = "center_vertical",
          layout_marginLeft = "16dp",
          {
            AppCompatImageView,
            layout_width = "16dp",
            layout_height = "16dp",
            ImageBitmap = Helpers.Static.materialIcon("twotone_message"),
            colorFilter = colors.onSurfaceVariant,
          },
          {
            MaterialTextView,
            id = "comment_count",
            layout_marginLeft = "4dp",
            text = "0",
            textSize = AppTextStyle.caption.size,
            textColor = AppTextStyle.caption.color,
            typeface = AppTextStyle.caption.font,
          }
        }
      }
    }
  }
}