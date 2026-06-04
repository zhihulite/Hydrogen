-- layout/dialogs/comment_sheet.lua
-- 评论底部弹出面板布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.card.MaterialCardView"
import "android.view.View"
import "com.google.android.material.chip.Chip"

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "match_parent",
  layout_height = "match_parent",
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "match_parent",
    layout_height = "wrap",
    title = "评论",
  },
  {
    RecyclerView,
    id = "recycler_view",
    layout_width = "match_parent",
    layout_height = 0,
    layout_weight = 1,
    clipToPadding = false,
    paddingTop = "4dp",
    paddingBottom = "4dp",
  },
  {
    MaterialCardView,
    id = "bottom_card",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_margin = "12dp",
    clickable = true,
    focusable = true,
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      padding = "12dp",
      gravity = "center_vertical",
      {
        AppCompatImageView,
        layout_width = "24dp",
        layout_height = "24dp",
        layout_marginRight = "12dp",
        imageBitmap = Helpers.Static.materialIcon("twotone_edit"),
        colorFilter = colors.onSurfaceVariant,
      },
      {
        MaterialTextView,
        text = "写评论...",
        textSize = AppTextStyle.bodyMedium.size,
        textColor = colors.onSurfaceVariant,
        typeface = AppTextStyle.bodyMedium.font,
        layout_weight = 1,
      },
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