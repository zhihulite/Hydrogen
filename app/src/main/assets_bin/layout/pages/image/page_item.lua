-- layout/pages/image/page_item.lua
-- 图片查看器 ViewPager2 单页布局

import "com.github.chrisbanes.photoview.PhotoView"
import "com.google.android.material.progressindicator.CircularProgressIndicator"
import "android.widget.FrameLayout"
import "android.view.View"

return {
  FrameLayout,
  layout_width = "fill",
  layout_height = "fill",
  {
    PhotoView,
    id = "photo_view",
    layout_width = "fill",
    layout_height = "fill",
    visibility = View.INVISIBLE,
  },
  {
    FrameLayout,
    id = "loading_container",
    layout_width = "fill",
    layout_height = "fill",
    {
      CircularProgressIndicator,
      id = "progress",
      layout_width = "48dp",
      layout_height = "48dp",
      layout_gravity = "center",
      indeterminate = true,
    },
  },
}