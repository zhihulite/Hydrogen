-- layout/cards/hot.lua
-- 热榜卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"

-- 创建圆角 ShapeAppearanceModel (8dp圆角)
local cornerShape = ShapeAppearanceModel.builder()
  .setAllCornerSizes(dp2px(8))
  .build()

return {
  LinearLayoutCompat,
  layout_width = "match_parent",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "card",
    layout_margin = "12dp",
    layout_marginTop = "6dp",
    layout_marginBottom = "6dp",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    clickable = true,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      padding = "16dp",
      {
        MaterialTextView,
        id = "rank",
        text = "1",
        textSize  = AppTextStyle.title.size,
        typeface  = AppTextStyle.title.font,
        layout_width = "32dp",
        gravity = "center",
      },
      {
        LinearLayoutCompat,
        layout_width = "0dp",
        layout_weight = 1,
        orientation = "vertical",
        layout_marginStart = "8dp",
        {
          MaterialTextView,
          id = "title",
          text = "热点标题",
          textSize  = AppTextStyle.title.size,
          typeface  = AppTextStyle.title.font,
          textColor = AppTextStyle.title.color,
          maxLines = 2,
          ellipsize = "end",
        },
        {
          LinearLayoutCompat,
          id = "heat_row",
          orientation = "horizontal",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
          layout_marginTop = "8dp",
          {
            MaterialTextView,
            id = "heat",
            text = "热度",
            textSize  = AppTextStyle.caption.size,
            textColor = AppTextStyle.caption.color,
            typeface  = AppTextStyle.caption.font,
          }
        }
      },
      {
        LinearLayoutCompat,
        id = "image_container",
        layout_width = "wrap_content",
        layout_height = "wrap_content",
        layout_marginStart = "12dp",
        gravity = "center_vertical",
        {
          ShapeableImageView,
          id = "image",
          layout_width = "80dp",
          layout_height = "60dp",
          scaleType = "centerCrop",
          shapeAppearanceModel = cornerShape,
        }
      }
    }
  }
}