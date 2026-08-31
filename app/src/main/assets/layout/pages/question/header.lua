-- layout/pages/question/header.lua
-- 问题详情页头部布局

import "android.widget.HorizontalScrollView"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.imageview.ShapeableImageView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

local circleShapeModel = L.circleShape()
return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "question_header",
    layout_width = "fill",
    layout_height = "wrap_content",
    layout_margin = AppSpacing.lg,
    layout_marginBottom = AppSpacing.md,
    cardBackgroundColor = colors.surface,
    strokeColor = colors.outline,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap_content",
      padding = AppSpacing.content,
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "wrap_content",
        gravity = "center_vertical",
        layout_marginBottom = AppSpacing.md,
        {
          ShapeableImageView,
          id = "author_avatar",
          layout_width = "32dp",
          layout_height = "32dp",
          shapeAppearanceModel = circleShapeModel,
          visibility = View.GONE,
        },
        L.text("author_name", AppTextStyle.bodySmall, nil, { layout_width = 0, layout_weight = 1, layout_marginLeft = AppSpacing.md, visibility = View.GONE }),
      },
      L.text("question_title", AppTextStyle.titleLarge, nil, { layout_width = "fill", layout_height = "wrap_content", layout_marginBottom = AppSpacing.md }),
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "wrap_content",
        layout_marginTop = AppSpacing.md,
        L.text("answer_count", AppTextStyle.bodySmall, nil),
        L.text("follower_count", AppTextStyle.bodySmall, nil, { layout_marginLeft = AppSpacing.xl }),
      },
      {
        HorizontalScrollView,
        id = "topics_scroll",
        layout_width = "fill",
        layout_height = "wrap_content",
        layout_marginTop = AppSpacing.lg,
        {
          LinearLayoutCompat,
          id = "topics_container",
          orientation = "horizontal",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
        }
      },
      L.text("excerpt", AppTextStyle.bodyMedium, nil, { layout_width = "fill", layout_height = "wrap_content", layout_marginTop = AppSpacing.md, textColor = colors.primary, maxLines = 3, ellipsize = "end", visibility = View.GONE })
    }
  }
}