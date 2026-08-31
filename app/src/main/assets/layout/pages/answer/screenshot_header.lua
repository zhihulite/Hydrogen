-- layout/pages/answer/screenshot_header.lua
-- 回答截图头部布局（标题 + 头像 + 作者 + 分割线）

import "com.google.android.material.divider.MaterialDivider"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"

local L = Helpers.Layout

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "wrap_content",
  backgroundColor = colors.surface,
  paddingLeft = "16dp",
  paddingRight = "16dp",
  paddingTop = "16dp",
  paddingBottom = "12dp",
  L.text("title", AppTextStyle.titleSmall, nil, { layout_width = "fill", layout_height = "wrap_content" }),
  {
    LinearLayoutCompat,
    orientation = "horizontal",
    layout_width = "wrap_content",
    layout_height = "wrap_content",
    layout_marginTop = AppSpacing.lg,
    gravity = "center_vertical",
    {
      AppCompatImageView,
      id = "avatar",
      layout_width = "32dp",
      layout_height = "32dp",
    },
    L.text("author", AppTextStyle.bodySmall, nil, { layout_width = "wrap_content", layout_height = "wrap_content", layout_marginLeft = AppSpacing.md }),
  },
  {
    MaterialDivider,
    layout_width = "fill",
    layout_height = "wrap_content",
    layout_marginTop = AppSpacing.lg,
  },
}