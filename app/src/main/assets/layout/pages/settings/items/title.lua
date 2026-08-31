-- layout/pages/settings/items/title.lua
-- 设置页面分组标题

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "44dp",
  gravity = "center_vertical",
  {
    MaterialTextView,
    id = "title",
    -- marginLeft 需要加上卡片的左边距
    layout_marginLeft = AppCardStyle.setting.marginLeft + dp2px(4),
    layout_marginRight = AppCardStyle.setting.marginRight,
    layout_marginTop = AppCardStyle.setting.marginTop,
    layout_marginBottom = AppCardStyle.setting.marginBottom,
    textSize  = AppTextStyle.labelSmall.size,
    textColor = AppTextStyle.labelSmall.color,
    typeface  = AppTextStyle.labelSmall.font
  }
}