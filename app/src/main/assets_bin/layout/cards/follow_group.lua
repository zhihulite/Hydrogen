-- layout/cards/follow_group.lua
-- 关注流分组卡片（可展开/收起）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "androidx.recyclerview.widget.RecyclerView"
import "android.view.View"

local colors = AppTheme.colors

local circleShapeBuilder = ShapeAppearanceModel.builder()
circleShapeBuilder.allCornerSizes = RelativeCornerSize(0.5)
local circleShapeModel = circleShapeBuilder.build()

return {
  LinearLayoutCompat,
  layout_width = "match_parent",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "card",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_marginLeft = AppCardStyle.basic.marginLeft,
    layout_marginRight = AppCardStyle.basic.marginRight,
    layout_marginTop = AppCardStyle.basic.marginTop,
    layout_marginBottom = AppCardStyle.basic.marginBottom,
    clickable = true,
    {
      LinearLayoutCompat,
      layout_width = "match_parent",
      orientation = "vertical",
      padding = "12dp",
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        gravity = "center_vertical",
        {
          ShapeableImageView,
          id = "avatar",
          layout_width = "28dp",
          layout_height = "28dp",
          shapeAppearanceModel = circleShapeModel,
        },
        {
          MaterialTextView,
          id = "action_text",
          layout_marginLeft = "10dp",
          layout_weight = 1,
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
          maxLines = 1,
          ellipsize = "end",
          layout_gravity = "center",
        }
      },
      {
        LinearLayoutCompat,
        id = "sub_container",
        orientation = "vertical",
        layout_width = "match_parent",
        layout_marginTop = "8dp",
        visibility = View.GONE,
        {
          RecyclerView,
          id = "sub_list",
          layout_width = "match_parent",
          layout_height = "wrap_content",
          nestedScrollingEnabled = false,
        }
      },
      {
        LinearLayoutCompat,
        id = "expand_btn_layout",
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_marginTop = "8dp",
        gravity = "center",
        visibility = View.VISIBLE,
        {
          MaterialTextView,
          id = "expand_text",
          text = "展开",
          textSize = AppTextStyle.labelSmall.size,
          textColor = AppTextStyle.labelSmall.color,
          typeface = AppTextStyle.labelSmall.font,
        },
        {
          AppCompatImageView,
          id = "expand_icon",
          layout_width = "20dp",
          layout_height = "20dp",
          layout_marginLeft = "4dp",
          colorFilter = colors.onSurfaceVariant,
        },
      }
    }
  }
}