-- layout/pages/about/items/title.lua
-- 关于页面分组标题

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  gravity = "center_vertical",
  {
    MaterialTextView,
    id = "title",
    -- 标题下方为列表项，使用 padding 控制内边距
    paddingLeft = AppCardStyle.setting.innerPaddingLeft,
    paddingRight = AppCardStyle.setting.innerPaddingLeft,
    paddingTop = AppCardStyle.setting.innerPaddingTop,
    paddingBottom = AppCardStyle.setting.innerPaddingBottom,
    textSize = AppTextStyle.labelSmall.size,
    textColor = AppTextStyle.labelSmall.color,
    typeface = AppTextStyle.labelSmall.font,
  }
}