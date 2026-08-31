-- layout/pages/image/main.lua
-- 图片浏览器主布局（CoordinatorLayout，点击切换底栏，全屏沉浸）

import "android.animation.LayoutTransition"
import "android.view.View"
import "androidx.coordinatorlayout.widget.CoordinatorLayout"
import "androidx.viewpager2.widget.ViewPager2"
import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

-- 沉浸在黑色背景上，文字色不取主题值
local WHITE = 0xFFFFFFFF
local WHITE_80 = 0xCCFFFFFF

return {
  CoordinatorLayout,
  layout_width = "fill",
  layout_height = "fill",
  backgroundColor = "#FF000000",
  id = "main_container",
  layoutTransition = LayoutTransition(),
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
    L.text("now_count", AppTextStyle.headlineSmall, "0", { textColor = WHITE }),
    L.text(nil, AppTextStyle.titleSmall, "/", { textColor = WHITE_80 }),
    L.text("all_count", AppTextStyle.titleSmall, "0", { textColor = WHITE_80 }),
  },
  {
    Helpers.MaterialWidgets.IconButton_Filled,
    id = "download_btn",
    layout_width = "48dp",
    layout_height = "48dp",
    layout_gravity = "bottom|end",
    layout_marginRight = "20dp",
    layout_marginBottom = "32dp",
    icon = Helpers.Static.materialDrawable("twotone_download", 24, true),
  },
}