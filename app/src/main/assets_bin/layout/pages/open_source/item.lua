-- layout/pages/open_source/item.lua
-- 开源许可列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "android.view.View"

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
    strokeWidth = 0,
    radius = 0,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap",
      paddingLeft = AppCardStyle.setting.innerPaddingLeft,
      paddingRight = AppCardStyle.setting.innerPaddingLeft,
      paddingTop = AppCardStyle.setting.innerPaddingTop,
      paddingBottom = AppCardStyle.setting.innerPaddingBottom,
      gravity = "center_vertical",
      minHeight = "56dp",
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "wrap",
        gravity = "center_vertical",
        {
          LinearLayoutCompat,
          orientation = "vertical",
          layout_width = 0,
          layout_weight = 1,
          {
            MaterialTextView,
            id = "name",
            textSize = AppTextStyle.titleSmall.size,
            textColor = colors.primary, -- 保留品牌色强调
            typeface = AppTextStyle.titleSmall.font,
          },
          {
            MaterialTextView,
            id = "message",
            textSize = AppTextStyle.bodyMedium.size,
            textColor = AppTextStyle.bodyMedium.color,
            typeface = AppTextStyle.bodyMedium.font,
            layout_marginTop = "4dp",
            visibility = View.GONE,
          }
        },
        {
          MaterialTextView,
          id = "license",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
          layout_marginLeft = "8dp",
          paddingLeft = "8dp",
          paddingRight = "8dp",
          paddingTop = "4dp",
          paddingBottom = "4dp",
        }
      }
    }
  }
}