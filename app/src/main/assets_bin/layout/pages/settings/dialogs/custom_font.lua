-- layout/pages/settings/dialogs/custom_font.lua
-- 自定义字体设置弹窗

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.materialswitch.MaterialSwitch"
import "android.view.View"

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "wrap",
  {
    LinearLayoutCompat,
    orientation = "horizontal",
    gravity = "center_vertical",
    layout_width = "fill",
    layout_height = "64dp",
    {
      MaterialTextView,
      text = "开启自定义字体",
      textSize  = AppTextStyle.titleSmall.size,
      textColor = AppTextStyle.titleSmall.color,
      layout_width = 0,
      layout_weight = 1,
      layout_marginLeft = "16dp",
      typeface  = AppTextStyle.titleSmall.font,
    },
    {
      MaterialSwitch,
      id = "font_switch",
      layout_marginRight = "16dp",
    }
  },
  {
    MaterialTextView,
    text = "开启后会将字体文件缓存到软件文件夹，关闭后会自动删除缓存到软件内的字体文件。",
    textSize  = AppTextStyle.bodySmall.size,
    textColor = AppTextStyle.bodySmall.color,
    typeface  = AppTextStyle.bodySmall.font,
    layout_marginLeft = "16dp",
    layout_marginRight = "16dp",
    layout_marginTop = "4dp",
    layout_marginBottom = "8dp",
  },
  {
    LinearLayoutCompat,
    id = "font_container",
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "wrap_content",
    visibility = View.GONE,
    padding = "16dp",
    {
      MaterialButton,
      id = "app_font_btn",
      text = "使用App字体",
      layout_width = "fill",
      layout_height = "48dp",
    },
    {
      MaterialButton,
      id = "choose_file_btn",
      text = "从文件中选择",
      layout_width = "fill",
      layout_height = "48dp",
      layout_marginTop = "8dp",
    },
  }
}