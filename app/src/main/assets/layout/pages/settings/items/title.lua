-- layout/pages/settings/items/title.lua
-- 设置页面分组标题

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "44dp",
  gravity = "center_vertical",
  L.text("title", AppTextStyle.labelSmall, nil, { layout_marginLeft = AppCardStyle.setting.marginLeft + dp2px(4), layout_marginRight = AppCardStyle.setting.marginRight, layout_marginTop = AppCardStyle.setting.marginTop, layout_marginBottom = AppCardStyle.setting.marginBottom })
}