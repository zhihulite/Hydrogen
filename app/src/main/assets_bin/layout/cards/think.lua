-- layout/cards/think.lua
-- 想法卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"

local colors = AppTheme.getColors()
local imageShapeModel = ShapeAppearanceModel.builder()
  .setAllCornerSizes(RelativeCornerSize(0.03))
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
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      padding = "16dp",
      {
        MaterialTextView,
        id = "title",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        textSize  = AppTextStyle.body.size,
        textColor = AppTextStyle.body.color,
        typeface  = AppTextStyle.body.font,
        maxLines  = 10,
        ellipsize = "end",
      },
      {
        ShapeableImageView,
        id = "image",
        layout_width = "match_parent",
        layout_height = "200dp",
        layout_marginTop = "12dp",
        scaleType = "centerCrop",
        shapeAppearanceModel = imageShapeModel,
        visibility = View.GONE,
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "12dp",
        {
          LinearLayoutCompat,
          id = "like_layout",
          orientation = "horizontal",
          layout_width = "wrap_content",
          padding = "8dp",
          {
            AppCompatImageView,
            id = "like_icon",
            layout_width = "20dp",
            layout_height = "20dp",
            ImageBitmap = Helpers.Static.materialIcon("twotone_thumb_up"),
            colorFilter = colors.onSurfaceVariant,
          },
          {
            MaterialTextView,
            id = "like_count",
            layout_width = "wrap_content",
            layout_height = "wrap_content",
            layout_marginLeft = "4dp",
            text = "0",
            textSize  = AppTextStyle.caption.size,
            textColor = AppTextStyle.caption.color,
            typeface  = AppTextStyle.caption.font,
          }
        },
        {
          LinearLayoutCompat,
          id = "comment_layout",
          orientation = "horizontal",
          layout_width = "wrap_content",
          padding = "8dp",
          {
            AppCompatImageView,
            layout_width = "20dp",
            layout_height = "20dp",
            ImageBitmap = Helpers.Static.materialIcon("twotone_message"),
            colorFilter = colors.onSurfaceVariant,
          },
          {
            MaterialTextView,
            id = "comment_count",
            layout_width = "wrap_content",
            layout_height = "wrap_content",
            layout_marginLeft = "4dp",
            text = "0",
            textSize  = AppTextStyle.caption.size,
            textColor = AppTextStyle.caption.color,
            typeface  = AppTextStyle.caption.font,
          }
        }
      }
    }
  }
}