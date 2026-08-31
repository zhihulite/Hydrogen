-- layout/pages/home/drawer_header.lua
-- 侧滑菜单头部布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.card.MaterialCardView"
import "android.view.View"

local L = Helpers.Layout

local colors = AppTheme.colors

local circleShapeModel = L.circleShape()
return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap_content",
  orientation = "vertical",
  {
    MaterialCardView,
    id = "card",
    layout_width = "fill",
    layout_height = "wrap_content",
    layout_margin = AppSpacing.lg,
    clickable = true,
    {
      LinearLayoutCompat,
      layout_width = "fill",
      orientation = "vertical",
      padding = AppSpacing.content,
      {
        -- 头像与退出按钮行
        LinearLayoutCompat,
        layout_width = "fill",
        orientation = "horizontal",
        gravity = "center_vertical",
        {
          ShapeableImageView,
          id = "avatar",
          layout_width = "48dp",
          layout_height = "48dp",
          shapeAppearanceModel = circleShapeModel,
        },
        {
          LinearLayoutCompat,
          layout_width = 0,
          layout_weight = 1,
          layout_height = "wrap_content",
        },
        {
          AppCompatImageView,
          id = "logout",
          layout_width = "24dp",
          layout_height = "24dp",
          layout_gravity = "end",
          imageBitmap = Helpers.Static.materialIcon("twotone_logout"),
          colorFilter = colors.onSurfaceVariant,
          visibility = View.GONE,
        }
      },
      -- 用户名
      L.text("name", AppTextStyle.titleSmall, "未登录", { layout_marginTop = AppSpacing.lg }),
      -- 个性签名
      L.text("signature", AppTextStyle.bodySmall, "点击登录", { layout_marginTop = AppSpacing.sm })
    }
  }
}