-- layout/pages/about/items/title.lua
-- 关于页面分组标题

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  gravity = "center_vertical",
  L.text("title", AppTextStyle.labelSmall, nil, { paddingLeft = AppCardStyle.setting.innerPaddingLeft, paddingRight = AppCardStyle.setting.innerPaddingLeft, paddingTop = AppCardStyle.setting.innerPaddingTop, paddingBottom = AppCardStyle.setting.innerPaddingBottom })
}