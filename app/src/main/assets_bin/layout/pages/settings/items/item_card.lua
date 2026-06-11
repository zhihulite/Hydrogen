-- layout/pages/settings/items/item_card.lua
-- 设置页面通用列表项

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
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
    layout_marginLeft = AppCardStyle.setting.marginLeft,
    layout_marginRight = AppCardStyle.setting.marginRight,
    layout_marginTop = AppCardStyle.setting.marginTop,
    layout_marginBottom = AppCardStyle.setting.marginBottom,
    strokeWidth = 0,
    radius = 0,
    cardBackgroundColor = colors.surfaceContainer,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "fill",
      layout_height = "wrap",
      gravity = "center_vertical",
      paddingLeft = AppCardStyle.setting.innerPaddingLeft,
      paddingRight = AppCardStyle.setting.innerPaddingRight,
      paddingTop = AppCardStyle.setting.innerPaddingTop,
      paddingBottom = AppCardStyle.setting.innerPaddingBottom,
      minHeight = "56dp",
      {
        MaterialTextView,
        id = "title",
        layout_width = 0,
        layout_weight = 1,
        textSize  = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface  = AppTextStyle.titleSmall.font,
      },
      {
        AppCompatImageView,
        id = "arrow",
        layout_width = "24dp",
        layout_height = "24dp",
        imageBitmap = Helpers.Static.materialIcon("twotone_chevron_right"),
        colorFilter = colors.onSurfaceVariant,
        visibility = View.GONE,
      }
    }
  }
}