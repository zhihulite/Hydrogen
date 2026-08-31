-- layout/pages/settings/dialogs/home_location.lua
-- 主页城市设置弹窗

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.core.widget.NestedScrollView"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  orientation = "vertical",
  focusable = true,
  focusableInTouchMode = true,
  layout_width = "fill",
  layout_height = "wrap",
  L.edit("edit", AppTextStyle.bodyMedium, "输入城市名", { layout_margin = AppSpacing.xl }),
  {
    NestedScrollView,
    layout_width = "fill",
    layout_height = "wrap",
    L.text("city_list", AppTextStyle.bodySmall, nil, { layout_margin = AppSpacing.xl, textIsSelectable = true })
  }
}