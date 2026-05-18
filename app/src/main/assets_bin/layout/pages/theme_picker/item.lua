-- layout/pages/theme_picker/item.lua
-- 主题选择器列表项

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.radiobutton.MaterialRadioButton"

local colors = AppTheme.getColors()

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
    layout_marginTop = "2dp",
    layout_marginBottom = "2dp",
    CardBackgroundColor = colors.surface,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "fill",
      layout_height = "wrap",
      gravity = "center_vertical",
      minHeight = "64dp",
      {
        MaterialCardView,
        id = "color_preview",
        layout_width = "32dp",
        layout_height = "32dp",
        layout_marginLeft = "20dp",
        radius = "16dp",
        cardElevation = "0dp",
        strokeWidth = 0,
      },
      {
        MaterialTextView,
        id = "title",
        layout_width = "0dp",
        layout_weight = 1,
        layout_marginLeft = "16dp",
        textSize  = AppTextStyle.title.size,
        textColor = AppTextStyle.title.color,
        typeface  = AppTextStyle.title.font,
      },
      {
        MaterialRadioButton,
        id = "radio",
        layout_width = "wrap",
        layout_height = "wrap",
        layout_marginRight = "20dp",
        focusable = false,
        clickable = false,
      }
    }
  }
}