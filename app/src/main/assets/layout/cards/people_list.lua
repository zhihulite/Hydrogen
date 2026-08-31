-- layout/cards/people_list.lua
-- 用户列表卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.imageview.ShapeableImageView"

local L = Helpers.Layout


local circleShapeModel = L.circleShape()
return L.card({ style = "basic", inner = { orientation = "horizontal", layout_width = "fill", gravity = "center_vertical" } },
{
  ShapeableImageView,
  id = "avatar",
  layout_width = "48dp",
  layout_height = "48dp",
  shapeAppearanceModel = circleShapeModel,
},
{
  LinearLayoutCompat,
  orientation = "vertical",
  layout_weight = 1,
  layout_marginLeft = AppSpacing.lg,
  L.text("title", AppTextStyle.titleSmall, nil, { maxLines = 1, ellipsize = "end" }),
  L.text("preview", AppTextStyle.bodySmall, nil, { layout_marginTop = AppSpacing.xs, maxLines = 1, ellipsize = "end" })
},
{
  MaterialButton,
  id = "action_btn",
  layout_width = "wrap_content",
  layout_height = "wrap_content",
  textSize = AppTextStyle.bodySmall.size,
  typeface = AppTextStyle.bodySmall.font,
  paddingLeft = "12dp",
  paddingRight = "12dp",
}
)