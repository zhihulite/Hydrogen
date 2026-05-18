-- layout/pages/feedback/items/button.lua
-- 反馈页面底部操作按钮

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.button.MaterialButton"

local colors = AppTheme.getColors()

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  gravity = "center",
  padding = "24dp",
  {
    MaterialButton,
    id = "button",
    layout_width = "wrap",
    layout_height = "48dp",
    textColor = colors.background,
    backgroundColor = colors.primary,
    cornerRadius = "24dp",
    textSize = AppTextStyle.label.size,
    typeface = AppTextStyle.label.font,
  }
}