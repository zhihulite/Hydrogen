-- layout/pages/settings/items/home_tab_item.lua
-- 主页Tab排序项 inner

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.radiobutton.MaterialRadioButton"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  orientation = "horizontal",
  gravity = "center_vertical",
  id = "itemRoot",
  {
    MaterialTextView,
    id = "title",
    layout_width = "0dp",
    layout_weight = 1,
    layout_marginLeft = "16dp",
    textSize = AppTextStyle.titleSmall.size,
    textColor = AppTextStyle.titleSmall.color,
    typeface = AppTextStyle.titleSmall.font
  },
  {
    MaterialRadioButton,
    id = "radio",
    focusable = false,
    clickable = false,
    layout_marginRight = "16dp",
  }
}