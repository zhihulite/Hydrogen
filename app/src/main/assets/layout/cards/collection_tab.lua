-- layout/cards/collection_tab.lua
-- 收藏 Tab 卡片

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

return L.card({ style = "basic", cardBackgroundColor = colors.surface, strokeColor = colors.outline, inner = { orientation = "horizontal" } },
{
  LinearLayoutCompat,
  orientation = "vertical",
  layout_weight = 1,
  {
    LinearLayoutCompat,
    orientation = "horizontal",
    gravity = "center_vertical",
    L.text("title", AppTextStyle.titleSmall, nil, { maxLines = 1, ellipsize = "end", layout_weight = 1 }),
    {
      AppCompatImageView,
      id = "lock_icon",
      layout_width = "16dp",
      layout_height = "16dp",
      layout_marginLeft = AppSpacing.md,
      imageBitmap = Helpers.Static.materialIcon("twotone_lock"),
      colorFilter = colors.onSurfaceVariant,
      visibility = View.GONE,
    }
  },
  L.text("preview", AppTextStyle.bodyMedium, nil, { layout_marginTop = AppSpacing.sm, maxLines = 2, ellipsize = "end" }),
  {
    LinearLayoutCompat,
    orientation = "horizontal",
    layout_marginTop = AppSpacing.md,
    L.text("item_count", AppTextStyle.bodySmall, nil),
    L.text("follower_count", AppTextStyle.bodySmall, nil, { layout_marginLeft = AppSpacing.xl }),
    L.text("creator_name", AppTextStyle.bodySmall, nil, { layout_marginLeft = AppSpacing.xl })
  }
}
)