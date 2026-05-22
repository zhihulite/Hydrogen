-- layout/pages/main/main.lua
-- MainActivity 布局

import "android.animation.LayoutTransition"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "android.widget.FrameLayout"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"

local colors = AppTheme.getColors()

local iconDrawable = activity.getPackageManager().getApplicationIcon(activity.getPackageName())

return {
  LinearLayoutCompat,
  layout_height = "fill",
  layout_width = "fill",
  {
    LinearLayoutCompat,
    id = "mainRowLayout",
    layoutTransition = LayoutTransition().enableTransitionType(LayoutTransition.CHANGING),
    layout_width = "fill",
    layout_height = "fill",
    orientation = "horizontal",
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
          imageDrawable = iconDrawable,
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
      layout_width = 0,
      layout_height = "fill",
      visibility = 8,
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
          imageDrawable = iconDrawable,
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