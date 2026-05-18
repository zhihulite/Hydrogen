-- layout/pages/main/main.lua
-- MainActivity 布局

import "android.animation.LayoutTransition"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "android.widget.FrameLayout"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.CornerFamily"

local colors = AppTheme.getColors()

local appR = luajava.bindClass("com.zhihu.hydrogen.x.R")
local welcomeDrawable = activity.getDrawable(appR.drawable.welcome)

local circleShape = ShapeAppearanceModel.builder()
.setAllCorners(CornerFamily.ROUNDED, 9999)
.build()

return {
  LinearLayoutCompat,
  layout_height = "fill",
  layout_width = "fill",
  {
    LinearLayoutCompat,
    layoutTransition = LayoutTransition().enableTransitionType(LayoutTransition.CHANGING),
    layout_width = "fill",
    layout_height = "fill",
    {
      FrameLayout,
      id = "leftContainer",
      layout_width = "fill",
      layout_height = "fill",
      {
        LinearLayoutCompat,
        gravity = "center",
        layout_width = "fill",
        layout_height = "fill",
        orientation = "vertical",
        {
          ShapeableImageView,
          id = "ivLeftPlaceholder",
          layout_gravity = "center",
          layout_width = "64dp",
          layout_height = "64dp",
          shapeAppearanceModel = circleShape,
          imageDrawable = welcomeDrawable,
        },
        {
          MaterialTextView,
          id = "tvLeftPlaceholder",
          layout_marginTop = "6dp",
          layout_gravity = "center",
          text = "Hydrogen，让每次点击都有意义",
          textColor = colors.onSurface,
        }
      }
    },
    {
      FrameLayout,
      id = "rightContainer",
      layout_width = "fill",
      layout_height = "fill",
      {
        LinearLayoutCompat,
        gravity = "center",
        layout_width = "fill",
        layout_height = "fill",
        orientation = "vertical",
        {
          ShapeableImageView,
          id = "ivRightPlaceholder",
          layout_gravity = "center",
          layout_width = "64dp",
          layout_height = "64dp",
          shapeAppearanceModel = circleShape,
          imageDrawable = welcomeDrawable,
        },
        {
          MaterialTextView,
          id = "tvRightPlaceholder",
          layout_marginTop = "6dp",
          layout_gravity = "center",
          text = "Hydrogen，让每次点击都有意义",
          textColor = colors.onSurface,
        }
      }
    }
  }
}