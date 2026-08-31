-- layout/cards/people_more.lua
-- 用户更多内容卡片

import "android.view.View"

local L = Helpers.Layout

return L.card({ style = "basic" },
L.text("title", AppTextStyle.titleSmall, nil),
L.text("preview", AppTextStyle.bodyMedium, nil, { layout_marginTop = AppSpacing.sm, visibility = View.GONE }),
L.text("bottom_text", AppTextStyle.bodySmall, nil, { layout_marginTop = AppSpacing.sm, visibility = View.GONE })
)