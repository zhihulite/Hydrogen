-- layout/dialogs/comment_sheet.lua
-- 评论底部弹出面板布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.card.MaterialCardView"
import "android.view.View"
import "com.google.android.material.chip.Chip"

local L = Helpers.Layout

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "fill",
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "fill",
    layout_height = "wrap",
    title = "评论",
  },
  {
    RecyclerView,
    id = "recycler_view",
    layout_width = "fill",
    layout_height = 0,
    layout_weight = 1,
    clipToPadding = false,
    paddingTop = "4dp",
    paddingBottom = "4dp",
  },
  {
    MaterialCardView,
    id = "bottom_card",
    layout_width = "fill",
    layout_height = "wrap_content",
    layout_margin = AppSpacing.lg,
    clickable = true,
    focusable = true,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "fill",
      layout_height = "wrap_content",
      padding = "12dp",
      gravity = "center_vertical",
      {
        AppCompatImageView,
        layout_width = "24dp",
        layout_height = "24dp",
        layout_marginRight = AppSpacing.lg,
        imageBitmap = Helpers.Static.materialIcon("twotone_edit"),
        colorFilter = colors.onSurfaceVariant,
      },
      L.text(nil, AppTextStyle.bodyMedium, "写评论...", {
        textColor = colors.onSurfaceVariant,
        layout_weight = 1,
      }),
      {
        AppCompatImageView,
        layout_width = "24dp",
        layout_height = "24dp",
        imageBitmap = Helpers.Static.materialIcon("twotone_add_circle"),
        colorFilter = colors.onSurfaceVariant,
      },
    },
  },
}