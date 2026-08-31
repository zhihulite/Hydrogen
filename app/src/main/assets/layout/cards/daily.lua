-- layout/cards/daily.lua
-- 日报卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"

local L = Helpers.Layout

local colors = AppTheme.colors

-- 创建圆角 ShapeAppearanceModel (8dp圆角)
local cornerShapeBuilder = ShapeAppearanceModel.builder()
cornerShapeBuilder.allCornerSizes = dp2px(8)
local cornerShapeModel = cornerShapeBuilder.build()

return L.card({ style = "basic", strokeColor = colors.outline, inner = { orientation = "horizontal", layout_width = "fill", layout_height = "wrap_content", gravity = "center_vertical" } },
L.text("title", AppTextStyle.titleSmall, nil, { layout_width = 0, layout_weight = 1, layout_height = "wrap_content", maxLines = 3, ellipsize = "end" }),
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