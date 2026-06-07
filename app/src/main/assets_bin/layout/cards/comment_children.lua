-- layout/cards/comment_children.lua
-- 子评论列表项布局（紧凑行，无卡片）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"

local colors = AppTheme.colors

local circleShapeBuilder = ShapeAppearanceModel.builder()
circleShapeBuilder.allCornerSizes = RelativeCornerSize(0.5)
local circleShapeModel = circleShapeBuilder.build()

return {
  LinearLayoutCompat,
  layout_width = "match_parent",
  layout_height = "wrap_content",
  orientation = "horizontal",
  paddingTop = "6dp",
  paddingBottom = "6dp",
  id = "card",
  {
    ShapeableImageView,
    id = "avatar",
    layout_width = "28dp",
    layout_height = "28dp",
    shapeAppearanceModel = circleShapeModel,
    layout_marginTop = "2dp",
  },
  {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_marginLeft = "8dp",
    id = "content_container",
    {
      MaterialTextView,
      id = "author_name",
      layout_width = "wrap_content",
      layout_height = "wrap_content",
      textSize = AppTextStyle.titleSmall.size,
      textColor = AppTextStyle.titleSmall.color,
      typeface = AppTextStyle.titleSmall.font,
      maxLines = 1,
      ellipsize = "end",
    },
    {
      MaterialTextView,
      id = "comment_content",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      layout_marginTop = "2dp",
      textSize = AppTextStyle.bodyMedium.size,
      textColor = AppTextStyle.bodyMedium.color,
      typeface = AppTextStyle.bodyMedium.font,
    },
    {
      -- 子评论图片
      ShapeableImageView,
      id = "comment_image",
      layout_width = "wrap_content",
      layout_height = "wrap_content",
      layout_marginTop = "4dp",
      visibility = View.GONE,
      scaleType = "centerCrop",
    },
    {
      LinearLayoutCompat,
      layout_width = "match_parent",
      layout_height = "wrap_content",
      layout_marginTop = "4dp",
      orientation = "horizontal",
      gravity = "center_vertical",
      {
        MaterialTextView,
        id = "comment_bottom",
        layout_width = "wrap_content",
        layout_height = "wrap_content",
        textSize = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface = AppTextStyle.bodySmall.font,
      },
      {
        View,
        layout_width = 0,
        layout_weight = 1,
        layout_height = "1dp",
      },
      {
        LinearLayoutCompat,
        id = "like_layout",
        layout_width = "wrap_content",
        layout_height = "wrap_content",
        gravity = "center_vertical",
        {
          AppCompatImageView,
          id = "like_icon",
          layout_width = "14dp",
          layout_height = "14dp",
          imageBitmap = Helpers.Static.materialIcon("outline_favorite_border"),
          colorFilter = colors.onSurfaceVariant,
        },
        {
          MaterialTextView,
          id = "like_count",
          layout_marginLeft = "2dp",
          text = "0",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
        }
      }
    }
  }
}