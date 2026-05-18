-- layout/pages/open_source/item.lua
-- 开源许可列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "android.view.View"

local colors = AppTheme.getColors()
local cardCornerSize = 16

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
    cardElevation = "0dp",
    strokeWidth = 0,
    CardBackgroundColor = colors.surface,
    shapeAppearanceModel = ShapeAppearanceModel.builder().setAllCornerSizes(cardCornerSize).build(),
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap",
      paddingLeft = "16dp",
      paddingRight = "16dp",
      paddingTop = "16dp",
      paddingBottom = "16dp",
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "wrap",
        gravity = "center_vertical",
        {
          LinearLayoutCompat,
          orientation = "vertical",
          layout_width = "0dp",
          layout_weight = 1,
          {
            MaterialTextView,
            id = "name",
            textSize  = AppTextStyle.title.size,
            textColor = colors.primary,            -- 保留品牌色强调
            typeface  = AppTextStyle.title.font,
          },
          {
            MaterialTextView,
            id = "message",
            textSize  = AppTextStyle.body.size,
            textColor = AppTextStyle.body.color,
            typeface  = AppTextStyle.body.font,
            layout_marginTop = "4dp",
            visibility = View.GONE,
          }
        },
        {
          MaterialTextView,
          id = "license",
          textSize  = AppTextStyle.caption.size,
          textColor = AppTextStyle.caption.color,
          typeface  = AppTextStyle.caption.font,
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