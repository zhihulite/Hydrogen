-- layout/pages/collections/header.lua
-- 收藏内容页 RecyclerView 头部布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "com.google.android.material.divider.MaterialDivider"
import "android.view.View"

local colors = AppTheme.colors

local avatarShapeBuilder = ShapeAppearanceModel.builder()
avatarShapeBuilder.allCornerSizes = RelativeCornerSize(0.5)
local avatarShapeModel = avatarShapeBuilder.build()

return {
  LinearLayoutCompat,
  layout_width = "match_parent",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "collection_header",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_margin = "8dp",
    radius = "12dp",
    cardElevation = 0,
    cardBackgroundColor = colors.surface,
    strokeWidth = "1dp",
    strokeColor = colors.outline,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      padding = "16dp",
      {
        MaterialTextView,
        id = "header_title",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        text = "加载中...",
        textSize = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface = AppTextStyle.titleSmall.font,
        layout_marginBottom = "8dp",
      },
      {
        MaterialTextView,
        id = "header_description",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        textSize = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface = AppTextStyle.bodySmall.font,
        maxLines = 5,
        ellipsize = "end",
        visibility = View.GONE,
      },
      {
        LinearLayoutCompat,
        id = "creator_layout",
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "12dp",
        gravity = "center_vertical",
        visibility = View.GONE,
        {
          ShapeableImageView,
          id = "creator_avatar",
          layout_width = "24dp",
          layout_height = "24dp",
          shapeAppearanceModel = avatarShapeModel,
        },
        {
          MaterialTextView,
          id = "creator_name",
          layout_marginLeft = "8dp",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
        },
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "12dp",
        {
          LinearLayoutCompat,
          orientation = "vertical",
          layout_weight = 1,
          gravity = "center",
          {
            MaterialTextView,
            id = "header_item_count",
            text = "0",
            textSize = AppTextStyle.bodyMedium.size,
            textColor = AppTextStyle.bodyMedium.color,
            typeface = AppTextStyle.bodyMedium.font,
            gravity = "center",
          },
          {
            MaterialTextView,
            text = "内容",
            textSize = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface = AppTextStyle.bodySmall.font,
            gravity = "center",
            layout_marginTop = "2dp",
          }
        },
        {
          -- 垂直分隔线（MaterialDivider 不支持垂直方向，此处使用 View，颜色与 Divider 对齐）
          View,
          layout_width = "1dp",
          layout_height = "match_parent",
          backgroundColor = colors.outlineVariant,
        },
        {
          LinearLayoutCompat,
          orientation = "vertical",
          layout_weight = 1,
          gravity = "center",
          {
            MaterialTextView,
            id = "header_follower_count",
            text = "0",
            textSize = AppTextStyle.bodyMedium.size,
            textColor = AppTextStyle.bodyMedium.color,
            typeface = AppTextStyle.bodyMedium.font,
            gravity = "center",
          },
          {
            MaterialTextView,
            text = "关注者",
            textSize = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface = AppTextStyle.bodySmall.font,
            gravity = "center",
            layout_marginTop = "2dp",
          }
        },
      },
      {
        LinearLayoutCompat,
        id = "follow_btn_container",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginTop = "12dp",
        gravity = "center",
        {
          MaterialButton,
          id = "follow_btn",
          layout_width = "wrap_content",
          layout_height = "36dp",
          text = "关注",
          cornerRadius = "18dp",
          typeface = AppTextStyle.bodySmall.font,
          paddingLeft = "24dp",
          paddingRight = "24dp",
        }
      }
    }
  }
}