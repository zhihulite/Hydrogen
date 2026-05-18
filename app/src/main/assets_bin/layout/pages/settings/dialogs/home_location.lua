-- layout/pages/settings/dialogs/home_location.lua
-- 主页城市设置弹窗

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatEditText"
import "androidx.core.widget.NestedScrollView"
import "com.google.android.material.textview.MaterialTextView"

return {
  LinearLayoutCompat,
  orientation = "vertical",
  focusable = true,
  focusableInTouchMode = true,
  layout_width = "fill",
  layout_height = "wrap",
  {
    AppCompatEditText,
    id = "edit",
    hint = "输入城市名",
    layout_width = "match_parent",
    layout_margin = "16dp",
    textSize  = AppTextStyle.body.size,
  },
  {
    NestedScrollView,
    layout_width = "fill",
    layout_height = "wrap",
    {
      MaterialTextView,
      id = "city_list",
      layout_margin = "16dp",
      textIsSelectable = true,
      textSize  = AppTextStyle.caption.size,
      textColor = AppTextStyle.caption.color,
      typeface  = AppTextStyle.caption.font,
    }
  }
}