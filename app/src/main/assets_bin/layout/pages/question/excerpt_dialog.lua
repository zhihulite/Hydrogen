-- layout/pages/question/excerpt_dialog.lua
-- 问题详情弹窗布局

import "androidx.core.widget.NestedScrollView"
import "com.hydrogen.view.LuaWebView"

local colors = AppTheme.getColors()

return {
  NestedScrollView,
  layout_width = "fill",
  layout_height = "fill",
  {
    LuaWebView,
    id = "webview",
    layout_width = "fill",
    layout_height = "fill",
    backgroundColor = colors.surface,
  }
}