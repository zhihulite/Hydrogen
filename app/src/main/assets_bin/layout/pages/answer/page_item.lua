-- layout/pages/answer/page_item.lua
-- answer viewpager2 单页布局

import "com.hydrogen.view.NestedLuaWebView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "com.google.android.material.progressindicator.LinearProgressIndicator"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.card.MaterialCardView"
import "android.view.View"

local colors = AppTheme.getColors()

local circleShape = ShapeAppearanceModel.builder()
.setAllCornerSizes(RelativeCornerSize(0.5))
.build()

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
    layout_margin = "16dp",
    layout_marginTop = "0dp",
    layout_marginBottom = "0dp",
    {
      LinearLayoutCompat,
      id = "userinfo",
      layout_width = "fill",
      layout_height = "wrap_content",
      orientation = "horizontal",
      gravity = "center_vertical",
      padding = "16dp",
      {
        ShapeableImageView,
        id = "user_avatar",
        layout_width = "48dp",
        layout_height = "48dp",
        shapeAppearanceModel = circleShape,
      },
      {
        LinearLayoutCompat,
        layout_width = "0dp",
        layout_weight = 1,
        layout_height = "wrap_content",
        orientation = "vertical",
        layout_marginLeft = "12dp",
        {
          MaterialTextView,
          id = "user_name",
          layout_width = "wrap",
          textColor = AppTextStyle.titleSmall.color,
          textSize = AppTextStyle.titleSmall.size,
          typeface = AppTextStyle.titleSmall.font,
          maxLines = 1,
          ellipsize = "end",
        },
        {
          MaterialTextView,
          id = "user_headline",
          layout_width = "wrap",
          maxLines = 1,
          ellipsize = "end",
          textColor = AppTextStyle.bodySmall.color,
          textSize = AppTextStyle.bodySmall.size,
          typeface = AppTextStyle.bodySmall.font,
          layout_marginTop = "2dp",
        },
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
    layout_width = "match_parent",
    layout_height = "match_parent",
    visibility = View.GONE,
  },
  authorCardLayout,
  {
    LinearProgressIndicator,
    id = "progress",
    layout_width = "fill",
    layout_height = "2dp",
    visibility = View.GONE,
    indeterminate = true,
  },
}