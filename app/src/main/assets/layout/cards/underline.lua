-- layout/cards/underline.lua
-- 用户划线内容卡片

import "com.google.android.material.divider.MaterialDivider"

local L = Helpers.Layout

local colors = AppTheme.colors

return L.card({ style = "basic", cardBackgroundColor = colors.surface, strokeColor = colors.outline },
L.text("content", AppTextStyle.bodyMedium, nil, { maxLines = 5, ellipsize = "end" }),
{
  MaterialDivider,
  layout_width = "fill",
  layout_height = "wrap_content",
  layout_marginTop = AppSpacing.md,
},
L.text("source_title", AppTextStyle.bodySmall, nil, { layout_marginTop = AppSpacing.md, maxLines = 1, ellipsize = "end" }),
L.text("bottom_text", AppTextStyle.bodySmall, nil, { layout_marginTop = AppSpacing.sm })
)