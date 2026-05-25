-- layout/pages/question/header.lua
-- 问题详情页头部布局

import "android.widget.HorizontalScrollView"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"

local colors = AppTheme.getColors()

local circleShape = ShapeAppearanceModel.builder()
.setAllCornerSizes(RelativeCornerSize(0.5))
.build()

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "match_parent",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "question_header",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_margin = "12dp",
    layout_marginBottom = "8dp",
    cardBackgroundColor = colors.surface,
    strokeColor = colors.outline,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      padding = "16dp",
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        gravity = "center_vertical",
        layout_marginBottom = "8dp",
        {
          ShapeableImageView,
          id = "author_avatar",
          layout_width = "32dp",
          layout_height = "32dp",
          shapeAppearanceModel = circleShape,
          visibility = View.GONE,
        },
        {
          MaterialTextView,
          id = "author_name",
          layout_width = "0dp",
          layout_weight = 1,
          layout_marginLeft = "8dp",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
          visibility = View.GONE,
        },
      },
      {
        MaterialTextView,
        id = "question_title",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        textSize = AppTextStyle.titleLarge.size,
        textColor = AppTextStyle.titleLarge.color,
        typeface = AppTextStyle.titleLarge.font,
        layout_marginBottom = "8dp",
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "8dp",
        {
          MaterialTextView,
          id = "answer_count",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
        },
        {
          MaterialTextView,
          id = "follower_count",
          layout_marginLeft = "16dp",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
        },
      },
      {
        HorizontalScrollView,
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "12dp",
        {
          LinearLayoutCompat,
          id = "topics_container",
          orientation = "horizontal",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
        }
      },
      {
        MaterialTextView,
        id = "excerpt",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "8dp",
        textSize = AppTextStyle.bodyMedium.size,
        textColor = colors.primary,
        typeface = AppTextStyle.bodyMedium.font,
        maxLines = 3,
        ellipsize = "end",
        visibility = View.GONE,
      }
    }
  }
}