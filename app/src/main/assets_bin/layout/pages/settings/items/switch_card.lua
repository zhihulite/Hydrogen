-- layout/pages/settings/items/switch_card.lua
-- 设置页面开关项（带卡片包裹）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.materialswitch.MaterialSwitch"

local colors = AppTheme.getColors()

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
    radius = "0dp",
    cardElevation = "0dp",
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "fill",
      layout_height = "wrap",
      gravity = "center_vertical",
      paddingLeft = "16dp",
      paddingRight = "16dp",
      minHeight = "56dp",
      {
        MaterialTextView,
        id = "title",
        layout_width = "0dp",
        layout_weight = 1,
        textSize  = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface  = AppTextStyle.titleSmall.font,
      },
      {
        MaterialSwitch,
        id = "switch_btn",
        layout_marginLeft = "8dp",
        focusable = false,
        clickable = false,
      }
    }
  }
}