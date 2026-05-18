-- layout/pages/about/items/header.lua
-- 关于页面头部（应用图标、名称与标语）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "wrap",
  gravity = "center",
  orientation = "vertical",
  padding = "32dp",
  {
    ShapeableImageView,
    id = "icon",
    layout_width = "80dp",
    layout_height = "80dp",
    imageDrawable = activity.getPackageManager().getApplicationIcon(activity.getPackageName()),
    layout_marginBottom = "16dp",
    shapeAppearanceModel = ShapeAppearanceModel.builder().setAllCornerSizes(40).build(),
  },
  {
    MaterialTextView,
    id = "name",
    text = AppInfo.getName(),
    textSize  = AppTextStyle.title.size,
    textColor = AppTextStyle.title.color,
    typeface  = AppTextStyle.title.font,
  },
  {
    MaterialTextView,
    id = "message",
    text = "让每次点击都有意义",
    textSize  = AppTextStyle.caption.size,
    textColor = AppTextStyle.caption.color,
    typeface  = AppTextStyle.caption.font,
    layout_marginTop = "8dp",
  }
}