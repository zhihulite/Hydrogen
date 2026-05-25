-- layout/cards/recommend.lua
-- 首页推荐卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"

local colors = AppTheme.getColors()

return {
  LinearLayoutCompat,
  layout_width = "match_parent",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "card",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_margin = "12dp",
    layout_marginTop = "6dp",
    layout_marginBottom = "6dp",
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      padding = "12dp",
      {
        MaterialTextView,
        id = "title",
        textSize = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface = AppTextStyle.titleSmall.font,
        maxLines = 2,
        ellipsize = "end",
      },
      {
        MaterialTextView,
        id = "preview",
        textSize = AppTextStyle.bodyMedium.size,
        textColor = AppTextStyle.bodyMedium.color,
        typeface = AppTextStyle.bodyMedium.font,
        maxLines = 3,
        ellipsize = "end",
        layout_marginTop = "6dp",
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_marginTop = "8dp",
        {
          LinearLayoutCompat,
          id = "like_layout",
          gravity = "center",
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
            text = "0",
            textSize = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface = AppTextStyle.bodySmall.font,
            layout_marginLeft = "4dp",
          }
        },
        {
          LinearLayoutCompat,
          id = "comment_layout",
          layout_marginLeft = "16dp",
          gravity = "center",
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
            text = "0",
            textSize = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface = AppTextStyle.bodySmall.font,
            layout_marginLeft = "4dp",
          }
        }
      }
    }
  }
}