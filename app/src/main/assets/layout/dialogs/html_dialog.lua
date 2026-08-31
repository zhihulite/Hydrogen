-- layout/dialogs/html_dialog.lua
-- HTML 内容弹窗（协议、隐私政策等）

import "android.widget.ScrollView"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "android.text.method.LinkMovementMethod"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "fill",
  {
    ScrollView,
    layout_width = "fill",
    layout_height = "fill",
    L.text("content", AppTextStyle.bodyMedium, nil, { layout_width = "fill", layout_height = "fill", padding = "24dp", textIsSelectable = true, movementMethod = LinkMovementMethod.instance })
  }
}