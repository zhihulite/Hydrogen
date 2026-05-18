-- layout/pages/about/items/developer.lua
-- 关于页面开发者列表项布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"

local colors = AppTheme.getColors()
local avatarShape = ShapeAppearanceModel.builder()
.setAllCornerSizes(RelativeCornerSize(0.5))
.build()

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  {
    MaterialCardView,
    id = "card",
    layout_width = "fill",
    layout_height = "wrap",
    layout_marginLeft = "16dp",
    layout_marginRight = "16dp",
    layout_marginTop = "2dp",
    layout_marginBottom = "2dp",
    cardElevation = "0dp",
    strokeWidth = 0,
    CardBackgroundColor = colors.surface,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "fill",
      layout_height = "wrap",
      gravity = "center_vertical",
      minHeight = "72dp",
      {
        ShapeableImageView,
        id = "avatar",
        layout_width = "44dp",
        layout_height = "44dp",
        shapeAppearanceModel = avatarShape,
        strokeWidth = "1dp",
      },
      {
        LinearLayoutCompat,
        orientation = "vertical",
        layout_width = "0dp",
        layout_weight = 1,
        layout_marginLeft = "12dp",
        {
          MaterialTextView,
          id = "title",
          textSize = AppTextStyle.title.size,
          textColor = AppTextStyle.title.color,
          typeface = AppTextStyle.title.font,
        },
        {
          MaterialTextView,
          id = "summary",
          textSize = AppTextStyle.caption.size,
          textColor = AppTextStyle.caption.color,
          typeface = AppTextStyle.caption.font,
          layout_marginTop = "2dp",
        }
      },
      {
        AppCompatImageView,
        id = "external_icon",
        layout_width = "20dp",
        layout_height = "20dp",
        layout_marginRight = "16dp",
        ImageBitmap = Helpers.Static.materialIcon("twotone_open_in_new"),
        colorFilter = colors.onSurfaceVariant,
        visibility = View.GONE,
      }
    }
  }
}