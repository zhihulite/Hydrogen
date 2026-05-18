-- layout/pages/about/items/item.lua
-- 关于页面通用列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
import "android.view.View"
import "com.google.android.material.shape.ShapeAppearanceModel"

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
    strokeWidth = 0,
    CardBackgroundColor = colors.surface,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "fill",
      layout_height = "wrap",
      gravity = "center_vertical",
      minHeight = "56dp",
      {
        LinearLayoutCompat,
        orientation = "vertical",
        layout_width = "0dp",
        layout_weight = 1,
        {
          MaterialTextView,
          id = "title",
          textSize = AppTextStyle.title.size,
          textColor = AppTextStyle.title.color,
          typeface = AppTextStyle.title.font,
        },
        {
          MaterialTextView,
          id = "summary",
          textSize = AppTextStyle.caption.size,
          textColor = AppTextStyle.caption.color,
          typeface = AppTextStyle.caption.font,
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
        ImageBitmap = Helpers.Static.materialIcon("twotone_chevron_right"),
        colorFilter = colors.onSurfaceVariant,
        visibility = View.GONE,
      }
    }
  }
}