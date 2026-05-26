-- layout/cards/topic.lua
-- 话题内容列表项布局

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
    layout_margin = "16dp",
    layout_marginTop = "8dp",
    layout_marginBottom = "8dp",
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      padding = "16dp",
      {
        MaterialTextView,
        id = "title",
        textSize  = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface  = AppTextStyle.titleSmall.font,
      },
      {
        MaterialTextView,
        id = "preview",
        textSize  = AppTextStyle.bodyMedium.size,
        textColor = AppTextStyle.bodyMedium.color,
        typeface  = AppTextStyle.bodyMedium.font,
        layout_marginTop = "4dp",
        maxLines  = 3,
        ellipsize = "end",
      },
      {
        MaterialTextView,
        id = "bottom_text",
        textSize  = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface  = AppTextStyle.bodySmall.font,
        layout_marginTop = "4dp",
      },
      {
        LinearLayoutCompat,
        id = "stats_layout",
        orientation = "horizontal",
        layout_marginTop = "8dp",
        {
          LinearLayoutCompat,
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
            id = "voteup_count",
            layout_marginLeft = "4dp",
            text = "0",
            textSize  = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface  = AppTextStyle.bodySmall.font,
          }
        },
        {
          LinearLayoutCompat,
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