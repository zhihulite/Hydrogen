-- layout/cards/search_result.lua
-- 搜索结果卡片

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
        id = "action_text",
        text = "添加了内容",
        textSize  = AppTextStyle.caption.size,
        textColor = AppTextStyle.caption.color,
        typeface  = AppTextStyle.caption.font,
      },
      {
        MaterialTextView,
        id = "title",
        text = "标题",
        layout_marginTop = "8dp",
        textSize  = AppTextStyle.title.size,
        textColor = AppTextStyle.title.color,
        typeface  = AppTextStyle.title.font,
        maxLines = 2,
        ellipsize = "end",
      },
      {
        MaterialTextView,
        id = "preview",
        text = "预览内容",
        layout_marginTop = "6dp",
        textSize  = AppTextStyle.body.size,
        textColor = AppTextStyle.body.color,
        typeface  = AppTextStyle.body.font,
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
            ImageBitmap = Helpers.Static.materialIcon("twotone_thumb_up"),
            colorFilter = colors.onSurfaceVariant,
          },
          {
            MaterialTextView,
            id = "like_count",
            text = "0",
            textSize  = AppTextStyle.caption.size,
            textColor = AppTextStyle.caption.color,
            typeface  = AppTextStyle.caption.font,
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
            ImageBitmap = Helpers.Static.materialIcon("twotone_message"),
            colorFilter = colors.onSurfaceVariant,
          },
          {
            MaterialTextView,
            id = "comment_count",
            text = "0",
            textSize  = AppTextStyle.caption.size,
            textColor = AppTextStyle.caption.color,
            typeface  = AppTextStyle.caption.font,
            layout_marginLeft = "4dp",
          }
        }
      }
    }
  }
}