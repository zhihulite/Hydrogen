-- layout/pages/login/main.lua
-- 登录页面主布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "android.widget.FrameLayout"
import "org.luajvm.android.widget.LuaWebView"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.progressindicator.CircularProgressIndicator"
import "android.view.View"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  id = "main_container",
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "fill",
    layout_height = "wrap"
  },
  {
    FrameLayout,
    layout_width = "fill",
    layout_height = "fill",
    {
      LuaWebView,
      id = "webview",
      layout_width = "fill",
      layout_height = "fill",
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