-- layout/pages/theme_picker/item.lua
-- 主题选择器列表项

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.radiobutton.MaterialRadioButton"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  {
    MaterialCardView,
    id = "card",
    layout_width = "fill",
    layout_height = "wrap",
    layout_marginLeft = AppSpacing.lg,
    layout_marginRight = AppSpacing.lg,
    layout_marginTop = AppSpacing.xs,
    layout_marginBottom = AppSpacing.xs,
    cardBackgroundColor = colors.surface,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap",
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "wrap",
        gravity = "center_vertical",
        minHeight = "48dp",
        {
          MaterialCardView,
          id = "color_preview",
          layout_width = "24dp",
          layout_height = "24dp",
          layout_marginLeft = "16dp",
          radius = "12dp",
          cardElevation = 0,
          strokeWidth = 0,
        },
        L.text("title", AppTextStyle.titleSmall, nil, { layout_width = 0, layout_weight = 1, layout_marginLeft = AppSpacing.lg }),
        {
          MaterialRadioButton,
          id = "radio",
          layout_width = "wrap",
          layout_height = "wrap",
          layout_marginRight = "16dp",
          focusable = false,
          clickable = false,
        }
      },
      L.text("summary", AppTextStyle.bodySmall, nil, { visibility = View.GONE, layout_marginLeft = "40dp", layout_marginRight = "16dp", layout_marginBottom = "10dp" })
    }
  }
}