-- layout/pages/topic/detail.lua
-- 话题详情页布局

import "androidx.core.widget.NestedScrollView"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.imageview.ShapeableImageView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

local avatarShapeModel = L.circleShape()
return {
  NestedScrollView,
  layout_width = "fill",
  layout_height = "fill",
  id = "detail_container",
  fillViewport = true,
  {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "fill",
    padding = AppSpacing.content,
    {
      MaterialCardView,
      layout_width = "fill",
      layout_height = "wrap",
      radius = "16dp",
      cardBackgroundColor = colors.surfaceVariant,
      strokeWidth = "1dp",
      strokeColor = colors.outline,
      cardElevation = 0,
      {
        LinearLayoutCompat,
        layout_width = "fill",
        layout_height = "fill",
        orientation = "vertical",
        padding = "24dp",
        gravity = "center",
        {
          ShapeableImageView,
          id = "detail_avatar",
          layout_width = "80dp",
          layout_height = "80dp",
          shapeAppearanceModel = avatarShapeModel,
        },
        L.text("detail_name", AppTextStyle.headlineSmall, nil, { layout_marginTop = AppSpacing.lg, gravity = "center" }),
        L.text("detail_intro", AppTextStyle.bodyMedium, nil, { layout_marginTop = AppSpacing.md, gravity = "center", maxLines = 10, ellipsize = "end" }),
        {
          LinearLayoutCompat,
          layout_width = "fill",
          layout_height = "wrap_content",
          layout_marginTop = "20dp",
          gravity = "center",
          {
            LinearLayoutCompat,
            orientation = "vertical",
            gravity = "center",
            layout_weight = 1,
            L.text("detail_followers", AppTextStyle.titleSmall, "0", { gravity = "center" }),
            L.text(nil, AppTextStyle.bodySmall, "关注者", { layout_marginTop = AppSpacing.xs, gravity = "center" }),
          },
          {
            View,
            layout_width = "1dp",
            layout_height = "fill",
            backgroundColor = colors.outlineVariant,
          },
          {
            LinearLayoutCompat,
            orientation = "vertical",
            gravity = "center",
            layout_weight = 1,
            L.text("detail_questions", AppTextStyle.titleSmall, "0", { gravity = "center" }),
            L.text(nil, AppTextStyle.bodySmall, "问题", { layout_marginTop = AppSpacing.xs, gravity = "center" }),
          },
          {
            View,
            layout_width = "1dp",
            layout_height = "fill",
            backgroundColor = colors.outlineVariant,
          },
          {
            LinearLayoutCompat,
            orientation = "vertical",
            gravity = "center",
            layout_weight = 1,
            L.text("detail_best_answers", AppTextStyle.titleSmall, "0", { gravity = "center" }),
            L.text(nil, AppTextStyle.bodySmall, "精华", { layout_marginTop = AppSpacing.xs, gravity = "center" }),
          },
        },
      }
    }
  }
}