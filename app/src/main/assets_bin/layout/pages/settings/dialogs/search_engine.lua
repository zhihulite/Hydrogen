-- layout/pages/settings/dialogs/search_engine.lua
-- 搜索引擎设置弹窗

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatEditText"
import "com.google.android.material.textview.MaterialTextView"

return {
  LinearLayoutCompat,
  orientation = "vertical",
  padding = "16dp",
  {
    MaterialTextView,
    text = "请使用 ?q= 类似物为结尾，如下：",
    textIsSelectable = true,
    textSize  = AppTextStyle.caption.size,
    textColor = AppTextStyle.caption.color,
    typeface  = AppTextStyle.caption.font,
    layout_marginBottom = "12dp",
  },
  {
    MaterialTextView,
    text = "知乎搜索：https://www.zhihu.com/search?type=content&q=",
    textIsSelectable = true,
    textSize  = AppTextStyle.caption.size,
    textColor = AppTextStyle.caption.color,
    typeface  = AppTextStyle.caption.font,
    layout_marginBottom = "8dp",
  },
  {
    MaterialTextView,
    text = "必应搜索：https://www.bing.com/search?q=site%3Azhihu.com%20",
    textIsSelectable = true,
    textSize  = AppTextStyle.caption.size,
    textColor = AppTextStyle.caption.color,
    typeface  = AppTextStyle.caption.font,
    layout_marginBottom = "12dp",
  },
  {
    AppCompatEditText,
    id = "edit",
    hint = "请输入搜索引擎地址",
    layout_width = "match_parent",
    textSize  = AppTextStyle.body.size,
    typeface  = AppTextStyle.body.font,
  }
}