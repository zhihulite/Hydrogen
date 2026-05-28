-- layout/cards/follow_group_sub.lua
-- 关注流分组子项布局（普通内容）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "android.view.View"

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
    layout_marginLeft = AppCardStyle.child.marginLeft,
    layout_marginRight = AppCardStyle.child.marginRight,
    layout_marginTop = AppCardStyle.child.marginTop,
    layout_marginBottom = AppCardStyle.child.marginBottom,
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
        layout_marginTop = "4dp",
        maxLines = 2,
        ellipsize = "end",
        visibility = View.GONE,
      },
      {
        MaterialTextView,
        id = "desc",
        textSize = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface = AppTextStyle.bodySmall.font,
        layout_marginTop = "4dp",
        maxLines = 1,
        ellipsize = "end",
      }
    }
  }
}