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

local colors = AppTheme.colors

local avatarShapeBuilder = ShapeAppearanceModel.builder()
avatarShapeBuilder.allCornerSizes = RelativeCornerSize(0.5)
local avatarShapeModel = avatarShapeBuilder.build()

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  {
    MaterialCardView,
    id = "card",
    layout_width = "fill",
    layout_height = "wrap",
    cardElevation = 0,
    strokeWidth = 0,
    radius = 0,
    cardBackgroundColor = colors.surface,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "fill",
      layout_height = "wrap",
      layout_marginLeft = "16dp",
      layout_marginRight = "16dp",
      layout_marginTop = "2dp",
      layout_marginBottom = "2dp",
      gravity = "center_vertical",
      minHeight = "72dp",
      {
        ShapeableImageView,
        id = "avatar",
        layout_width = "44dp",
        layout_height = "44dp",
        shapeAppearanceModel = avatarShapeModel,
        strokeWidth = "1dp",
      },
      {
        LinearLayoutCompat,
        orientation = "vertical",
        layout_width = 0,
        layout_weight = 1,
        layout_marginLeft = "12dp",
        {
          MaterialTextView,
          id = "title",
          textSize = AppTextStyle.titleSmall.size,
          textColor = AppTextStyle.titleSmall.color,
          typeface = AppTextStyle.titleSmall.font,
        },
        {
          MaterialTextView,
          id = "summary",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
          layout_marginTop = "2dp",
        }
      },
      {
        AppCompatImageView,
        id = "external_icon",
        layout_width = "20dp",
        layout_height = "20dp",
        layout_marginRight = "16dp",
        imageBitmap = Helpers.Static.materialIcon("twotone_open_in_new"),
        colorFilter = colors.onSurfaceVariant,
        visibility = View.GONE,
      }
    }
  }
}