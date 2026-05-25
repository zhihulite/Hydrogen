-- layout/pages/home/drawer_header.lua
-- 侧滑菜单头部布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "com.google.android.material.card.MaterialCardView"
import "android.view.View"

local colors = AppTheme.getColors()

local circleShape = ShapeAppearanceModel.builder()
.setAllCornerSizes(RelativeCornerSize(0.5))
.build()

return {
  LinearLayoutCompat,
  layout_width = "match_parent",
  layout_height = "wrap_content",
  orientation = "vertical",
  {
    MaterialCardView,
    id = "card",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_margin = "12dp",
    clickable = true,
    {
      LinearLayoutCompat,
      layout_width = "match_parent",
      orientation = "vertical",
      padding = "16dp",
      {
        -- 头像与退出按钮行
        LinearLayoutCompat,
        layout_width = "match_parent",
        orientation = "horizontal",
        gravity = "center_vertical",
        {
          ShapeableImageView,
          id = "avatar",
          layout_width = "48dp",
          layout_height = "48dp",
          shapeAppearanceModel = circleShape,
        },
        {
          LinearLayoutCompat,
          layout_width = "0dp",
          layout_weight = 1,
          layout_height = "wrap_content",
        },
        {
          AppCompatImageView,
          id = "logout",
          layout_width = "24dp",
          layout_height = "24dp",
          layout_gravity = "end",
          ImageBitmap = Helpers.Static.materialIcon("twotone_logout"),
          colorFilter = colors.onSurfaceVariant,
          visibility = View.GONE,
        }
      },
      {
        -- 用户名
        MaterialTextView,
        id = "name",
        layout_marginTop = "12dp",
        text = "未登录",
        textSize = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface = AppTextStyle.titleSmall.font,
      },
      {
        -- 个性签名
        MaterialTextView,
        id = "signature",
        layout_marginTop = "4dp",
        text = "点击登录",
        textSize = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface = AppTextStyle.bodySmall.font,
      }
    }
  }
}