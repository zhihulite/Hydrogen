-- layout/pages/question/excerpt_dialog.lua
-- 问题详情弹窗布局

import "org.luajvm.android.widget.LuaWebView"

local colors = AppTheme.colors

return {
  LuaWebView,
  id = "webview",
  layout_width = "fill",
  layout_height = "wrap",
}
