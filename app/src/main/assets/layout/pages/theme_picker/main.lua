-- layout/pages/theme_picker/main.lua
-- 主题选择器主布局：工具栏 + 列表（占满剩余）+ 底部应用栏

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.appbar.MaterialToolbar"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.button.MaterialButton"

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  id = "main_container",
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  backgroundColor = colors.background,
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "fill",
    layout_height = "wrap",
  },
  {
    RecyclerView,
    id = "recycler_view",
    layout_width = "fill",
    layout_height = 0,
    layout_weight = 1,
    clipToPadding = false,
  },
  {
    LinearLayoutCompat,
    id = "apply_bar",
    layout_width = "fill",
    layout_height = "wrap",
    orientation = "vertical",
    paddingLeft = AppSpacing.xl,
    paddingRight = AppSpacing.xl,
    paddingTop = "8dp",
    paddingBottom = "12dp",
    {
      MaterialButton,
      id = "apply_btn",
      layout_width = "fill",
      layout_height = "48dp",
      text = "应用主题",
      textColor = colors.onPrimary,
      backgroundColor = colors.primary,
      cornerRadius = "24dp",
      textSize = AppTextStyle.labelLarge.size,
      typeface = AppTextStyle.labelLarge.font,
    },
  },
}
