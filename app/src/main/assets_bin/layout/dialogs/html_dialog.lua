-- layout/dialogs/html_dialog.lua
-- HTML 内容弹窗（协议、隐私政策等）

import "android.widget.ScrollView"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "android.text.method.LinkMovementMethod"

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "fill",
  {
    ScrollView,
    layout_width = "fill",
    layout_height = "fill",
    {
      MaterialTextView,
      id = "content",
      layout_width = "fill",
      layout_height = "fill",
      padding = "24dp",
      textIsSelectable = true,
      textSize  = AppTextStyle.body.size,
      textColor = AppTextStyle.body.color,
      typeface  = AppTextStyle.body.font,
      movementMethod = LinkMovementMethod.getInstance(),
    }
  }
}