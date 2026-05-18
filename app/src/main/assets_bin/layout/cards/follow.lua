-- layout/cards/follow.lua
-- 关注流卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
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
    clickable = true,
    {
      LinearLayoutCompat,
      layout_width = "match_parent",
      layout_height = "wrap_content",
      orientation = "vertical",
      padding = "12dp",
      {
        MaterialTextView,
        id = "group_badge",
        text = "为你推荐",
        textSize = AppTextStyle.label.size,
        textColor = AppTextStyle.label.color,
        typeface = AppTextStyle.label.font,
        layout_marginBottom = "4dp",
        visibility = View.GONE,
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        {
          ShapeableImageView,
          id = "avatar",
          layout_width = "28dp",
          layout_height = "28dp",
          shapeAppearanceModel = circleShape,
        },
        {
          MaterialTextView,
          id = "action_text",
          layout_marginLeft = "12dp",
          layout_weight = 1,
          textSize = AppTextStyle.caption.size,
          textColor = AppTextStyle.caption.color,
          typeface = AppTextStyle.caption.font,
          maxLines = 1,
          ellipsize = "end",
          layout_gravity = "center",
        }
      },
      {
        MaterialTextView,
        id = "title",
        layout_marginTop = "8dp",
        textSize = AppTextStyle.title.size,
        textColor = AppTextStyle.title.color,
        typeface = AppTextStyle.title.font,
        maxLines = 2,
        ellipsize = "end",
      },
      {
        MaterialTextView,
        id = "preview",
        layout_marginTop = "4dp",
        textSize = AppTextStyle.body.size,
        textColor = AppTextStyle.body.color,
        typeface = AppTextStyle.body.font,
        maxLines = 3,
        ellipsize = "end",
        visibility = View.GONE,
      },
      {
        LinearLayoutCompat,
        id = "stats_layout",
        orientation = "horizontal",
        layout_marginTop = "8dp",
        {
          LinearLayoutCompat,
          id = "like_layout",
          orientation = "horizontal",
          gravity = "center_vertical",
          {
            AppCompatImageView,
            id = "like_icon",
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
          orientation = "horizontal",
          layout_marginLeft = "16dp",
          gravity = "center_vertical",
          {
            AppCompatImageView,
            id = "comment_icon",
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