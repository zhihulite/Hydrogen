-- layout/dialogs/comment_sheet.lua
-- 评论底部弹出面板布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.card.MaterialCardView"
import "android.view.View"
import "com.google.android.material.chip.Chip"

local colors = AppTheme.getColors()

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
    LinearLayoutCompat,
    id = "sort_row",
    orientation = "horizontal",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    padding = "12dp",
    gravity = "center_vertical",
    {
      Chip,
      id = "chip_score",
      layout_width = "wrap_content",
      layout_height = "wrap",
      text = "默认",
      chipStartPadding = "8dp",
      chipEndPadding = "8dp",
    },
    {
      Chip,
      id = "chip_ts",
      layout_width = "wrap_content",
      layout_height = "wrap",
      text = "最新",
      chipStartPadding = "8dp",
      chipEndPadding = "8dp",
      layout_marginLeft = "8dp",
    },
    {
      View,
      layout_width = "0dp",
      layout_weight = 1,
      layout_height = "1dp",
    },
    {
      MaterialTextView,
      id = "comment_count",
      text = "",
      textSize = AppTextStyle.bodySmall.size,
      textColor = AppTextStyle.bodySmall.color,
      typeface = AppTextStyle.bodySmall.font,
    },
  },
  {
    RecyclerView,
    id = "recycler_view",
    layout_width = "match_parent",
    layout_height = "0dp",
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
        ImageBitmap = Helpers.Static.materialIcon("twotone_edit"),
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
        ImageBitmap = Helpers.Static.materialIcon("twotone_add_circle"),
        colorFilter = colors.onSurfaceVariant,
      },
    },
  },
}