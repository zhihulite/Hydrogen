-- layout/pages/welcome/main.lua
-- 欢迎页面主布局

import "android.widget.FrameLayout"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.appbar.MaterialToolbar"

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
    layout_height = "wrap",
    titleCentered = true
  },
  {
    FrameLayout,
    id = "pageContainer",
    layout_width = "fill",
    layout_height = 0,
    layout_weight = 1,
  },
  {
    LinearLayoutCompat,
    layout_width = "fill",
    layout_height = "wrap",
    orientation = "horizontal",
    gravity = "center",
    padding = "16dp",
    {
      MaterialButton,
      id = "nextButton",
      text = "下一步",
      layout_width = "fill",
      layout_height = "wrap",
    }
  }
}