-- layout/pages/question/excerpt_dialog.lua
-- 问题详情弹窗布局

import "com.hydrogen.view.LuaWebView"

local colors = AppTheme.getColors()

return {
  LuaWebView,
  id = "webview",
  layout_width = "fill",
  layout_height = "wrap",
}
