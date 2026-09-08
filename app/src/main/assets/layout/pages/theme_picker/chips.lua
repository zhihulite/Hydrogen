-- layout/pages/theme_picker/chips.lua
-- 主题选择器选项组（标签 + 一行多选项的 chip 流）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.hydrogen.FixedChipGroup"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  orientation = "vertical",
  paddingLeft = AppSpacing.xl,
  paddingRight = AppSpacing.xl,
  paddingTop = AppSpacing.md,
  paddingBottom = AppSpacing.xs,
  L.text("label", AppTextStyle.labelLarge, nil, { layout_marginBottom = AppSpacing.sm }),
  {
    FixedChipGroup,
    id = "chip_group",
    layout_width = "fill",
    layout_height = "wrap",
    chipSpacingHorizontal = AppSpacing.md,
    chipSpacingVertical = AppSpacing.sm,
  }
}
