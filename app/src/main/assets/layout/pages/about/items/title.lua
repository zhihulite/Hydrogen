-- layout/pages/about/items/title.lua
-- 关于页面分组标题

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "48dp",
  gravity = "center_vertical",
  L.text("title", AppTextStyle.labelLarge, nil, { layout_marginLeft = AppCardStyle.setting.marginLeft + dp2px(4), layout_marginRight = AppCardStyle.setting.marginRight, layout_marginTop = AppCardStyle.setting.marginTop, layout_marginBottom = AppCardStyle.setting.marginBottom })
}
