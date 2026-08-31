-- layout/pages/settings/items/home_tab_item.lua
-- 主页Tab排序项 inner

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.radiobutton.MaterialRadioButton"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  orientation = "horizontal",
  gravity = "center_vertical",
  id = "itemRoot",
  L.text("title", AppTextStyle.titleSmall, nil, { layout_width = 0, layout_weight = 1, layout_marginLeft = AppSpacing.xl }),
  {
    MaterialRadioButton,
    id = "radio",
    focusable = false,
    clickable = false,
    layout_marginRight = AppSpacing.xl,
  }
}