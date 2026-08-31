-- layout/cards/collection_content.lua
-- 收藏夹内容列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"

local colors = AppTheme.colors

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
      orientation = "vertical",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      paddingLeft = AppCardStyle.basic.innerPaddingLeft,
      paddingRight = AppCardStyle.basic.innerPaddingRight,
      paddingTop = AppCardStyle.basic.innerPaddingTop,
      paddingBottom = AppCardStyle.basic.innerPaddingBottom,
      {
        MaterialTextView,
        id = "title",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        textSize = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface = AppTextStyle.titleSmall.font,
        maxLines = 2,
        ellipsize = "end",
      },
      {
        MaterialTextView,
        id = "preview",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "6dp",
        textSize = AppTextStyle.bodyMedium.size,
        textColor = AppTextStyle.bodyMedium.color,
        typeface = AppTextStyle.bodyMedium.font,
        maxLines = 3,
        ellipsize = "end",
      },
      {
        LinearLayoutCompat,
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "10dp",
        orientation = "horizontal",
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
            imageBitmap = Helpers.Static.materialIcon("twotone_thumb_up"),
            colorFilter = colors.onSurfaceVariant,
          },
          {
            MaterialTextView,
            id = "like_count",
            layout_marginLeft = "4dp",
            text = "0",
            textSize = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface = AppTextStyle.bodySmall.font,
          }
        },
        {
          LinearLayoutCompat,
          id = "comment_layout",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
          layout_marginLeft = "16dp",
          gravity = "center_vertical",
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
            textSize = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface = AppTextStyle.bodySmall.font,
          }
        }
      }
    }
  }
}