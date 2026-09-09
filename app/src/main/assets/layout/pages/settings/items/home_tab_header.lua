-- layout/pages/settings/items/home_tab_header.lua
-- 主页Tab排序分组标题

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  L.text("header", AppTextStyle.labelLarge, nil, { layout_marginLeft = AppSpacing.xl, layout_marginTop = AppSpacing.lg, layout_marginBottom = AppSpacing.xs })
}