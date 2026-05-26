-- layout/pages/settings/items/slider_card.lua
-- 设置页面滑块项

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.slider.Slider"

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  {
    MaterialCardView,
    id = "card",
    strokeWidth = 0,
    cardBackgroundColor = colors.surfaceContainer,
    layout_width = "fill",
    layout_height = "wrap",
    layout_marginLeft = "12dp",
    layout_marginRight = "12dp",
    layout_marginTop = "2dp",
    layout_marginBottom = "2dp",
    radius = 0,
    cardElevation = 0,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap",
      paddingLeft = "16dp",
      paddingRight = "16dp",
      minHeight = "56dp",
      {
        MaterialTextView,
        id = "title",
        layout_marginTop = "12dp",
        textSize  = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface  = AppTextStyle.titleSmall.font,
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "fill",
        layout_marginTop = "8dp",
        layout_marginBottom = "12dp",
        gravity = "center_vertical",
        {
          Slider,
          id = "slider",
          layout_weight = 1,
        },
        {
          MaterialTextView,
          id = "value",
          layout_marginLeft = "16dp",
          textSize  = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface  = AppTextStyle.bodySmall.font,
          minWidth  = "40dp",
        }
      }
    }
  }
}