-- layout/pages/answer/screenshot_preview.lua
-- 截图预览布局（全宽图片）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.github.chrisbanes.photoview.PhotoView"

return {
  LinearLayoutCompat,
  layout_width = -1,
  layout_height = -1,
  {
    PhotoView,
    id = "iv",
    layout_width = "fill",
    layout_height = "wrap",
    adjustViewBounds = true,
  },
}