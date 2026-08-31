-- layout/cards/follow_group.lua
-- 关注流分组卡片（可展开/收起）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.imageview.ShapeableImageView"
import "androidx.recyclerview.widget.RecyclerView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

local circleShapeModel = L.circleShape()
return L.card({ style = "basic", inner = { layout_width = "fill"} },
{
  LinearLayoutCompat,
  orientation = "horizontal",
  layout_width = "fill",
  gravity = "center_vertical",
  {
    ShapeableImageView,
    id = "avatar",
    layout_width = "28dp",
    layout_height = "28dp",
    shapeAppearanceModel = circleShapeModel,
  },
  L.text("action_text", AppTextStyle.bodySmall, nil, { layout_marginLeft = "10dp", layout_weight = 1, maxLines = 1, ellipsize = "end", layout_gravity = "center" })
},
{
  LinearLayoutCompat,
  id = "sub_container",
  orientation = "vertical",
  layout_width = "fill",
  layout_marginTop = AppSpacing.md,
  visibility = View.GONE,
  {
    RecyclerView,
    id = "sub_list",
    layout_width = "fill",
    layout_height = "wrap_content",
    nestedScrollingEnabled = false,
  }
},
{
  LinearLayoutCompat,
  id = "expand_btn_layout",
  orientation = "horizontal",
  layout_width = "fill",
  layout_marginTop = AppSpacing.md,
  gravity = "center",
  visibility = View.VISIBLE,
  L.text("expand_text", AppTextStyle.labelSmall, "展开"),
  {
    AppCompatImageView,
    id = "expand_icon",
    layout_width = "20dp",
    layout_height = "20dp",
    layout_marginLeft = AppSpacing.sm,
    colorFilter = colors.onSurfaceVariant,
  },
}
)