-- layout/pages/settings/items/home_tab_header.lua
-- 主页Tab排序分组标题

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  L.text("header", AppTextStyle.labelSmall, nil, { layout_margin = AppSpacing.xl })
}