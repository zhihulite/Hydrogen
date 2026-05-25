-- layout/pages/answer/screenshot_header.lua
-- 回答截图头部布局（标题 + 头像 + 作者 + 分割线）

import "com.google.android.material.divider.MaterialDivider"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.textview.MaterialTextView"

local colors = AppTheme.getColors()

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "match_parent",
  layout_height = "wrap_content",
  backgroundColor = colors.surface,
  paddingLeft = "16dp",
  paddingRight = "16dp",
  paddingTop = "16dp",
  paddingBottom = "12dp",
  {
    MaterialTextView,
    id = "title",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    textSize = AppTextStyle.titleSmall.size,
    typeface = AppTextStyle.titleSmall.font,
    textColor = AppTextStyle.titleSmall.color,
    maxLines = 2,
    ellipsize = "end",
  },
  {
    LinearLayoutCompat,
    orientation = "horizontal",
    layout_width = "wrap_content",
    layout_height = "wrap_content",
    layout_marginTop = "12dp",
    gravity = "center_vertical",
    {
      AppCompatImageView,
      id = "avatar",
      layout_width = "32dp",
      layout_height = "32dp",
    },
    {
      MaterialTextView,
      id = "author",
      layout_width = "wrap_content",
      layout_height = "wrap_content",
      layout_marginLeft = "8dp",
      textSize = AppTextStyle.bodySmall.size,
      typeface = AppTextStyle.bodySmall.font,
      textColor = AppTextStyle.bodySmall.color,
    },
  },
  {
    MaterialDivider,
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_marginTop = "12dp",
  },
}