-- layout/common/webview_page.lua
-- 通用 webview 页布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.progressindicator.LinearProgressIndicator"
import "com.hydrogen.view.LuaWebView"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.hydrogen.view.CustomSwipeRefresh"

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  id = "main_container",
  backgroundColor = colors.background,
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "fill",
    layout_height = "wrap"
  },
  {
    LinearProgressIndicator,
    id = "progress_bar",
    layout_width = "fill",
    layout_height = "2dp",
    progress = 0,
    visibility = View.GONE,
  },
  {
    CustomSwipeRefresh,
    id = "swipe_refresh",
    layout_width = "fill",
    layout_height = "fill",
    {
      LuaWebView,
      id = "webview",
      layout_width = "fill",
      layout_height = "fill",
    }
  }
}