-- layout/cards/local_list.lua
-- 本地内容列表项卡片

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return L.card({ style = "basic" },
{
  LinearLayoutCompat,
  orientation = "horizontal",
  gravity = "center_vertical",
  L.text("title", AppTextStyle.titleSmall, nil, { layout_width = 0, layout_weight = 1, maxLines = 3, ellipsize = "end" }),
  L.text("count", AppTextStyle.bodySmall, nil, { layout_marginLeft = AppSpacing.md })
},
{
  LinearLayoutCompat,
  orientation = "horizontal",
  layout_marginTop = AppSpacing.sm,
  L.text("time", AppTextStyle.bodySmall, nil, { layout_width = 0, layout_weight = 1 })
}
)