-- layout/cards/hot.lua
-- 热榜卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "android.view.View"

local L = Helpers.Layout

-- 创建圆角 ShapeAppearanceModel (8dp圆角)
local cornerShapeBuilder = ShapeAppearanceModel.builder()
cornerShapeBuilder.allCornerSizes = dp2px(8)
local cornerShapeModel = cornerShapeBuilder.build()

return L.card({ style = "basic", inner = { orientation = "horizontal", layout_width = "fill", layout_height = "wrap_content" } },
L.text("rank", AppTextStyle.titleSmall, "1", {
  layout_width = "32dp",
  gravity = "center",
}),
{
  LinearLayoutCompat,
  layout_width = 0,
  layout_weight = 1,
  orientation = "vertical",
  layout_marginStart = AppSpacing.md,
  L.text("title", AppTextStyle.titleSmall, "热点标题"),
  {
    LinearLayoutCompat,
    id = "heat_row",
    orientation = "horizontal",
    layout_width = "wrap_content",
    layout_height = "wrap_content",
    layout_marginTop = AppSpacing.md,
    L.text("heat", AppTextStyle.bodySmall, "热度")
  }
},
{
  LinearLayoutCompat,
  id = "image_container",
  layout_width = "wrap_content",
  layout_height = "wrap_content",
  layout_marginStart = AppSpacing.lg,
  gravity = "center_vertical",
  {
    ShapeableImageView,
    id = "image",
    layout_width = "80dp",
    layout_height = "60dp",
    scaleType = "centerCrop",
    shapeAppearanceModel = cornerShapeModel,
  }
}
)