-- layout/cards/follow_group_sub.lua
-- 关注流分组子项布局（普通内容）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "android.view.View"

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
    layout_marginLeft = "8dp",
    layout_marginRight = "8dp",
    layout_marginTop = "4dp",
    layout_marginBottom = "4dp",
    cardBackgroundColor = colors.surfaceVariant,
    strokeColor = colors.outline,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      padding = "12dp",
      {
        MaterialTextView,
        id = "title",
        textSize = AppTextStyle.title.size,
        textColor = AppTextStyle.title.color,
        typeface = AppTextStyle.title.font,
        maxLines = 2,
        ellipsize = "end",
      },
      {
        MaterialTextView,
        id = "preview",
        textSize = AppTextStyle.body.size,
        textColor = AppTextStyle.body.color,
        typeface = AppTextStyle.body.font,
        layout_marginTop = "4dp",
        maxLines = 2,
        ellipsize = "end",
        visibility = View.GONE,
      },
      {
        MaterialTextView,
        id = "desc",
        textSize = AppTextStyle.caption.size,
        textColor = AppTextStyle.caption.color,
        typeface = AppTextStyle.caption.font,
        layout_marginTop = "4dp",
        maxLines = 1,
        ellipsize = "end",
      }
    }
  }
}