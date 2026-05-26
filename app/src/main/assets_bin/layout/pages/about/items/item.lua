-- layout/pages/about/items/item.lua
-- 关于页面通用列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
import "android.view.View"
import "com.google.android.material.shape.ShapeAppearanceModel"

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
    cardBackgroundColor = colors.surface,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "fill",
      layout_height = "wrap",
      layout_marginLeft = "16dp",
      layout_marginRight = "16dp",
      layout_marginTop = "2dp",
      layout_marginBottom = "2dp",
      gravity = "center_vertical",
      minHeight = "56dp",
      {
        LinearLayoutCompat,
        orientation = "vertical",
        layout_width = 0,
        layout_weight = 1,
        {
          MaterialTextView,
          id = "title",
          textSize = AppTextStyle.titleSmall.size,
          textColor = AppTextStyle.titleSmall.color,
          typeface = AppTextStyle.titleSmall.font,
        },
        {
          MaterialTextView,
          id = "summary",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
          layout_marginTop = "2dp",
          visibility = View.GONE,
        }
      },
      {
        AppCompatImageView,
        id = "arrow",
        layout_width = "20dp",
        layout_height = "20dp",
        layout_marginLeft = "8dp",
        layout_marginRight = "16dp",
        imageBitmap = Helpers.Static.materialIcon("twotone_chevron_right"),
        colorFilter = colors.onSurfaceVariant,
        visibility = View.GONE,
      }
    }
  }
}