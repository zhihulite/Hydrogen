-- layout/pages/image/main.lua
-- 图片浏览器主布局（CoordinatorLayout，点击根布局切换底栏，全屏沉浸）

import "androidx.coordinatorlayout.widget.CoordinatorLayout"
import "androidx.viewpager2.widget.ViewPager2"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"

local colors = AppTheme.getColors()

return {
  CoordinatorLayout,
  layout_width = "fill",
  layout_height = "fill",
  backgroundColor = "#FF000000",
  id = "main_container",
  {
    ViewPager2,
    id = "view_pager",
    layout_width = "fill",
    layout_height = "fill",
  },
  -- 页码指示器
  {
    LinearLayoutCompat,
    id = "bottom_bar",
    orientation = "horizontal",
    layout_width = "wrap_content",
    layout_height = "wrap_content",
    layout_gravity = "bottom|start",
    layout_marginLeft = "32dp",
    layout_marginBottom = "32dp",
    {
      MaterialTextView,
      id = "now_count",
      text = "0",
      textSize = AppTextStyle.headlineSmall.size,
      textColor = colors.surfaceBright,
    },
    {
      MaterialTextView,
      text = "/",
      textSize = AppTextStyle.titleSmall.size,
      textColor = colors.surfaceBright,
    },
    {
      MaterialTextView,
      id = "all_count",
      text = "0",
      textSize = AppTextStyle.titleSmall.size,
      textColor = colors.surfaceBright,
    },
  },
  {
    ShapeableImageView,
    id = "download_btn",
    layout_width = "48dp",
    layout_height = "48dp",
    layout_gravity = "bottom|end",
    layout_marginRight = "20dp",
    layout_marginBottom = "32dp",
    ImageDrawable = Helpers.Static.materialDrawable("twotone_download", 24, true),
    shapeAppearanceModel = ShapeAppearanceModel.builder()
    .setAllCornerSizes(RelativeCornerSize(0.5))
    .build(),
    scaleType = "center",
    colorFilter=0xffffffff,
    backgroundColor = colors.primary,
  },
}