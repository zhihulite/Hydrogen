-- layout/cards/collection_tab.lua
-- 收藏 Tab 卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
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
    layout_marginLeft = AppCardStyle.basic.marginLeft,
    layout_marginRight = AppCardStyle.basic.marginRight,
    layout_marginTop = AppCardStyle.basic.marginTop,
    layout_marginBottom = AppCardStyle.basic.marginBottom,
    cardBackgroundColor = colors.surface,
    strokeColor = colors.outline,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      paddingLeft = AppCardStyle.basic.innerPaddingLeft,
      paddingRight = AppCardStyle.basic.innerPaddingRight,
      paddingTop = AppCardStyle.basic.innerPaddingTop,
      paddingBottom = AppCardStyle.basic.innerPaddingBottom,
      {
        LinearLayoutCompat,
        orientation = "vertical",
        layout_weight = 1,
        {
          LinearLayoutCompat,
          orientation = "horizontal",
          gravity = "center_vertical",
          {
            MaterialTextView,
            id = "title",
            textSize  = AppTextStyle.titleSmall.size,
            textColor = AppTextStyle.titleSmall.color,
            typeface  = AppTextStyle.titleSmall.font,
            maxLines  = 1,
            ellipsize = "end",
            layout_weight = 1,
          },
          {
            AppCompatImageView,
            id = "lock_icon",
            layout_width = "16dp",
            layout_height = "16dp",
            layout_marginLeft = "8dp",
            imageBitmap = Helpers.Static.materialIcon("twotone_lock"),
            colorFilter = colors.onSurfaceVariant,
            visibility = View.GONE,
          }
        },
        {
          MaterialTextView,
          id = "preview",
          textSize  = AppTextStyle.bodyMedium.size,
          textColor = AppTextStyle.bodyMedium.color,
          typeface  = AppTextStyle.bodyMedium.font,
          layout_marginTop = "4dp",
          maxLines  = 2,
          ellipsize = "end",
        },
        {
          LinearLayoutCompat,
          orientation = "horizontal",
          layout_marginTop = "8dp",
          {
            MaterialTextView,
            id = "item_count",
            textSize  = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface  = AppTextStyle.bodySmall.font,
          },
          {
            MaterialTextView,
            id = "follower_count",
            layout_marginLeft = "16dp",
            textSize  = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface  = AppTextStyle.bodySmall.font,
          },
          {
            MaterialTextView,
            id = "creator_name",
            layout_marginLeft = "16dp",
            textSize  = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface  = AppTextStyle.bodySmall.font,
          }
        }
      }
    }
  }
}