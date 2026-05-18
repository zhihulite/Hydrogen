-- layout/pages/topic/detail.lua
-- 话题详情页布局

import "androidx.core.widget.NestedScrollView"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"

local colors = AppTheme.getColors()
local avatarShape = ShapeAppearanceModel.builder()
.setAllCornerSizes(RelativeCornerSize(0.5))
.build()

return {
  NestedScrollView,
  layout_width = "fill",
  layout_height = "fill",
  id = "root",
  fillViewport = true,
  {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    padding = "16dp",
    {
      MaterialCardView,
      layout_width = "fill",
      layout_height = "wrap",
      radius = "16dp",
      cardBackgroundColor = colors.surfaceVariant,
      strokeWidth = "1dp",
      strokeColor = colors.outline,
      cardElevation = "0dp",
      {
        LinearLayoutCompat,
        layout_width = "fill",
        layout_height = "fill",
        orientation = "vertical",
        padding = "24dp",
        gravity = "center",
        {
          ShapeableImageView,
          id = "detail_avatar",
          layout_width = "80dp",
          layout_height = "80dp",
          shapeAppearanceModel = avatarShape,
        },
        {
          MaterialTextView,
          id = "detail_name",
          layout_marginTop = "12dp",
          textSize = AppTextStyle.headline.size,
          textColor = AppTextStyle.headline.color,
          typeface = AppTextStyle.headline.font,
          gravity = "center",
        },
        {
          MaterialTextView,
          id = "detail_intro",
          layout_marginTop = "8dp",
          textSize = AppTextStyle.body.size,
          textColor = AppTextStyle.body.color,
          typeface = AppTextStyle.body.font,
          gravity = "center",
          maxLines = 10,
          ellipsize = "end",
        },
        {
          LinearLayoutCompat,
          layout_width = "fill",
          layout_height = "wrap_content",
          layout_marginTop = "20dp",
          gravity = "center",
          {
            LinearLayoutCompat,
            orientation = "vertical",
            gravity = "center",
            layout_weight = 1,
            {
              MaterialTextView,
              id = "detail_followers",
              text = "0",
              textSize = AppTextStyle.title.size,
              textColor = AppTextStyle.title.color,
              typeface = AppTextStyle.title.font,
              gravity = "center",
            },
            {
              MaterialTextView,
              text = "关注者",
              layout_marginTop = "2dp",
              textSize = AppTextStyle.caption.size,
              textColor = AppTextStyle.caption.color,
              typeface = AppTextStyle.caption.font,
              gravity = "center",
            },
          },
          {
            View,
            layout_width = "1dp",
            layout_height = "match_parent",
            backgroundColor = colors.outlineVariant,
          },
          {
            LinearLayoutCompat,
            orientation = "vertical",
            gravity = "center",
            layout_weight = 1,
            {
              MaterialTextView,
              id = "detail_questions",
              text = "0",
              textSize = AppTextStyle.title.size,
              textColor = AppTextStyle.title.color,
              typeface = AppTextStyle.title.font,
              gravity = "center",
            },
            {
              MaterialTextView,
              text = "问题",
              layout_marginTop = "2dp",
              textSize = AppTextStyle.caption.size,
              textColor = AppTextStyle.caption.color,
              typeface = AppTextStyle.caption.font,
              gravity = "center",
            },
          },
          {
            View,
            layout_width = "1dp",
            layout_height = "match_parent",
            backgroundColor = colors.outlineVariant,
          },
          {
            LinearLayoutCompat,
            orientation = "vertical",
            gravity = "center",
            layout_weight = 1,
            {
              MaterialTextView,
              id = "detail_best_answers",
              text = "0",
              textSize = AppTextStyle.title.size,
              textColor = AppTextStyle.title.color,
              typeface = AppTextStyle.title.font,
              gravity = "center",
            },
            {
              MaterialTextView,
              text = "精华",
              layout_marginTop = "2dp",
              textSize = AppTextStyle.caption.size,
              textColor = AppTextStyle.caption.color,
              typeface = AppTextStyle.caption.font,
              gravity = "center",
            },
          },
        },
      }
    }
  }
}