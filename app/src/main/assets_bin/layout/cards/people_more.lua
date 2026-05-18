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
    layout_marginLeft = "16dp",
    layout_marginRight = "16dp",
    layout_marginTop = "4dp",
    layout_marginBottom = "4dp",
    {
      LinearLayoutCompat,
      orientation = "vertical",
      padding = "16dp",
      {
        MaterialTextView,
        id = "title",
        textSize  = AppTextStyle.title.size,
        textColor = AppTextStyle.title.color,
        typeface  = AppTextStyle.title.font,
      },
      {
        MaterialTextView,
        id = "preview",
        textSize  = AppTextStyle.body.size,
        textColor = AppTextStyle.body.color,
        typeface  = AppTextStyle.body.font,
        layout_marginTop = "4dp",
        visibility = View.GONE,
      },
      {
        MaterialTextView,
        id = "bottom_text",
        textSize  = AppTextStyle.caption.size,
        textColor = AppTextStyle.caption.color,
        typeface  = AppTextStyle.caption.font,
        layout_marginTop = "4dp",
        visibility = View.GONE,
      }
    }
  }
}