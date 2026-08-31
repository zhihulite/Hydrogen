-- layout/pages/about/items/header.lua
-- 关于页面头部（应用图标、名称与标语）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"

local L = Helpers.Layout

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
    imageDrawable = activity.packageManager.getApplicationIcon(activity.packageName),
    layout_marginBottom = AppSpacing.xl,
  },
  L.text("name", AppTextStyle.titleSmall, AppInfo.name),
  L.text("message", AppTextStyle.bodySmall, "让每次点击都有意义", { layout_marginTop = AppSpacing.md })
}