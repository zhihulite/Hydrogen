-- layout/cards/search_result.lua
-- 搜索结果卡片

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
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      padding = "12dp",
      {
        MaterialTextView,
        id = "action_text",
        text = "添加了内容",
        textSize  = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface  = AppTextStyle.bodySmall.font,
      },
      {
        MaterialTextView,
        id = "title",
        text = "标题",
        layout_marginTop = "8dp",
        textSize  = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface  = AppTextStyle.titleSmall.font,
        maxLines = 2,
        ellipsize = "end",
      },
      {
        MaterialTextView,
        id = "preview",
        text = "预览内容",
        layout_marginTop = "6dp",
        textSize  = AppTextStyle.bodyMedium.size,
        textColor = AppTextStyle.bodyMedium.color,
        typeface  = AppTextStyle.bodyMedium.font,
        maxLines = 3,
        ellipsize = "end",
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_marginTop = "8dp",
        gravity = "end",
        {
          LinearLayoutCompat,
          gravity = "center",
          {
            AppCompatImageView,
            id = "like_icon",
            layout_width = "16dp",
            layout_height = "16dp",
            imageBitmap = Helpers.Static.materialIcon("twotone_thumb_up"),
            colorFilter = colors.onSurfaceVariant,
          },
          {
            MaterialTextView,
            id = "like_count",
            text = "0",
            textSize  = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface  = AppTextStyle.bodySmall.font,
            layout_marginLeft = "4dp",
          }
        },
        {
          LinearLayoutCompat,
          layout_marginLeft = "16dp",
          gravity = "center",
          {
            AppCompatImageView,
            id = "comment_icon",
            layout_width = "16dp",
            layout_height = "16dp",
            imageBitmap = Helpers.Static.materialIcon("twotone_message"),
            colorFilter = colors.onSurfaceVariant,
          },
          {
            MaterialTextView,
            id = "comment_count",
            text = "0",
            textSize  = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface  = AppTextStyle.bodySmall.font,
            layout_marginLeft = "4dp",
          }
        }
      }
    }
  }
}