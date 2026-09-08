-- layout/pages/theme_picker/title.lua
-- 主题选择器分组标题

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "48dp",
  gravity = "center_vertical",
  L.text("title", AppTextStyle.labelLarge, nil, { layout_marginLeft = AppSpacing.xl, layout_marginRight = AppCardStyle.setting.marginRight, layout_marginTop = AppCardStyle.setting.marginTop, layout_marginBottom = AppCardStyle.setting.marginBottom })
}
