-- layout/pages/collections/header.lua
-- 收藏内容页 RecyclerView 头部布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.imageview.ShapeableImageView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

local avatarShapeModel = L.circleShape()
return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "collection_header",
    layout_width = "fill",
    layout_height = "wrap_content",
    layout_margin = AppSpacing.md,
    radius = "12dp",
    cardElevation = 0,
    cardBackgroundColor = colors.surface,
    strokeWidth = "1dp",
    strokeColor = colors.outline,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap_content",
      padding = AppSpacing.content,
      L.text("header_title", AppTextStyle.titleSmall, "加载中...", { layout_width = "fill", layout_height = "wrap_content", layout_marginBottom = AppSpacing.md }),
      L.text("header_description", AppTextStyle.bodySmall, nil, { layout_width = "fill", layout_height = "wrap_content", maxLines = 5, ellipsize = "end", visibility = View.GONE }),
      {
        LinearLayoutCompat,
        id = "creator_layout",
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "wrap_content",
        layout_marginTop = AppSpacing.lg,
        gravity = "center_vertical",
        visibility = View.GONE,
        {
          ShapeableImageView,
          id = "creator_avatar",
          layout_width = "24dp",
          layout_height = "24dp",
          shapeAppearanceModel = avatarShapeModel,
        },
        L.text("creator_name", AppTextStyle.bodySmall, nil, { layout_marginLeft = AppSpacing.md }),
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "wrap_content",
        layout_marginTop = AppSpacing.lg,
        {
          LinearLayoutCompat,
          orientation = "vertical",
          layout_width = 0,
          layout_weight = 1,
          gravity = "center",
          L.text("header_item_count", AppTextStyle.bodyMedium, "0", { gravity = "center" }),
          L.text(nil, AppTextStyle.bodySmall, "内容", { gravity = "center", layout_marginTop = AppSpacing.xs })
        },
        {
          -- 垂直分隔线：1dp 宽 View，颜色取 outlineVariant，与横向 Divider 同色
          View,
          layout_width = "1dp",
          layout_height = "fill",
          backgroundColor = colors.outlineVariant,
        },
        {
          LinearLayoutCompat,
          orientation = "vertical",
          layout_width = 0,
          layout_weight = 1,
          gravity = "center",
          L.text("header_follower_count", AppTextStyle.bodyMedium, "0", { gravity = "center" }),
          L.text(nil, AppTextStyle.bodySmall, "关注者", { gravity = "center", layout_marginTop = AppSpacing.xs })
        },
      },
      {
        LinearLayoutCompat,
        id = "follow_btn_container",
        layout_width = "fill",
        layout_height = "wrap_content",
        layout_marginTop = AppSpacing.lg,
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