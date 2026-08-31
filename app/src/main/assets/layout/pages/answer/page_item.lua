-- layout/pages/answer/page_item.lua
-- answer viewpager2 单页布局

import "org.luajvm.android.widget.NestedLuaWebView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.progressindicator.LinearProgressIndicator"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "android.view.View"
import "android.widget.FrameLayout"

local L = Helpers.Layout

local colors = AppTheme.colors

local circleShapeModel = L.circleShape()
local authorCardLayout =
{
  LinearLayoutCompat,
  id = "user_card_wrapper",
  layout_width = "fill",
  layout_height = "wrap_content",
  {
    MaterialCardView,
    id = "user_card",
    layout_width = "fill",
    layout_height = "wrap_content",
    layout_margin = AppSpacing.xl,
    layout_marginTop = 0,
    layout_marginBottom = 0,
    {
      LinearLayoutCompat,
      id = "userinfo",
      layout_width = "fill",
      layout_height = "wrap_content",
      orientation = "horizontal",
      gravity = "center_vertical",
      padding = AppSpacing.content,
      {
        ShapeableImageView,
        id = "user_avatar",
        layout_width = "48dp",
        layout_height = "48dp",
        shapeAppearanceModel = circleShapeModel,
      },
      {
        LinearLayoutCompat,
        layout_width = 0,
        layout_weight = 1,
        layout_height = "wrap_content",
        orientation = "vertical",
        layout_marginLeft = AppSpacing.lg,
        L.text("user_name", AppTextStyle.titleSmall, nil, { layout_width = "wrap", maxLines = 1, ellipsize = "end" }),
        L.text("user_headline", AppTextStyle.bodySmall, nil, { layout_width = "wrap", maxLines = 1, ellipsize = "end", layout_marginTop = AppSpacing.xs }),
      },
    },
  },
}

return {
  FrameLayout,
  id = "root",
  layout_width = "fill",
  layout_height = "fill",
  backgroundColor = colors.background,
  {
    NestedLuaWebView,
    id = "webview",
    layout_width = "fill",
    layout_height = "fill",
    visibility = View.GONE,
  },
  authorCardLayout,
  {
    LinearProgressIndicator,
    id = "progress",
    layout_width = "fill",
    layout_height = "2dp",
    visibility = View.GONE,
  },
}