-- layout/cards/people_more.lua
-- 用户更多内容卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "android.view.View"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  {
    MaterialCardView,
    id = "card",
    layout_width = "fill",
    layout_height = "wrap",
    layout_marginLeft = AppCardStyle.basic.marginLeft,
    layout_marginRight = AppCardStyle.basic.marginRight,
    layout_marginTop = AppCardStyle.basic.marginTop,
    layout_marginBottom = AppCardStyle.basic.marginBottom,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      paddingLeft = AppCardStyle.basic.innerPaddingLeft,
      paddingRight = AppCardStyle.basic.innerPaddingRight,
      paddingTop = AppCardStyle.basic.innerPaddingTop,
      paddingBottom = AppCardStyle.basic.innerPaddingBottom,
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
        visibility = View.GONE,
      },
      {
        MaterialTextView,
        id = "bottom_text",
        textSize  = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface  = AppTextStyle.bodySmall.font,
        layout_marginTop = "4dp",
        visibility = View.GONE,
      }
    }
  }
}