-- layout/pages/people/sort_bar.lua
-- 回答排序栏

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.card.MaterialCardView"
import "androidx.appcompat.widget.AppCompatImageView"

local colors = AppTheme.getColors()

return {
  LinearLayoutCompat,
  id = "sort_bar",
  layout_width = "fill",
  layout_height = "wrap_content",
  orientation = "horizontal",
  gravity = "center_vertical",
  paddingLeft = "16dp",
  paddingRight = "16dp",
  paddingTop = "8dp",
  paddingBottom = "8dp",
  backgroundColor = colors.surface,
  {
    LinearLayoutCompat,
    layout_width = "0dp",
    layout_weight = 1,
    layout_height = "wrap",
  },
  {
    MaterialTextView,
    id = "sort_label",
    text = "排序：",
    textSize  = AppTextStyle.bodySmall.size,
    textColor = AppTextStyle.bodySmall.color,
    typeface  = AppTextStyle.bodySmall.font,
  },
  {
    MaterialCardView,
    id = "sort_btn",
    layout_width = "wrap",
    layout_height = "32dp",
    layout_marginLeft = "8dp",
    cardBackgroundColor = colors.surfaceVariant,
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      gravity = "center",
      layout_gravity = "center",
      paddingLeft = "12dp",
      paddingRight = "8dp",
      {
        MaterialTextView,
        id = "sort_name",
        text = "默认",
        textSize  = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface  = AppTextStyle.bodySmall.font,
        gravity = "center",
      },
      {
        AppCompatImageView,
        layout_width = "18dp",
        layout_height = "18dp",
        layout_marginLeft = "2dp",
        ImageBitmap = Helpers.Static.materialIcon("twotone_arrow_drop_down"),
        colorFilter = AppTextStyle.bodySmall.color,
      },
    }
  }
}