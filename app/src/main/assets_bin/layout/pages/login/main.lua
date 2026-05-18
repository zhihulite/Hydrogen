-- layout/pages/login/main.lua
-- 登录页面主布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "android.widget.FrameLayout"
import "com.hydrogen.view.LuaWebView"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.progressindicator.CircularProgressIndicator"

return {
  LinearLayoutCompat,
  layout_width = "match_parent",
  layout_height = "match_parent",
  orientation = "vertical",
  id = "main_container",
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "match_parent",
    layout_height = "wrap"
  },
  {
    FrameLayout,
    layout_width = "match_parent",
    layout_height = "match_parent",
    {
      LuaWebView,
      id = "webview",
      layout_width = "match_parent",
      layout_height = "match_parent",
    },
    {
      CircularProgressIndicator,
      id = "progress",
      visibility = View.GONE,
      layout_gravity = "center",
      layout_width = "48dp",
      layout_height = "48dp",
      indeterminate = true,
      trackThickness = "4dp",
    },
  },
}