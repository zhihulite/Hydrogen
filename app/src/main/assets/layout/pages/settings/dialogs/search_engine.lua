-- layout/pages/settings/dialogs/search_engine.lua
-- 搜索引擎设置弹窗

import "androidx.appcompat.widget.LinearLayoutCompat"

local L = Helpers.Layout

return {
  LinearLayoutCompat,
  orientation = "vertical",
  padding = AppSpacing.content,
  L.text(nil, AppTextStyle.bodySmall, "请使用 ?q= 类似物为结尾，如下：", { textIsSelectable = true, layout_marginBottom = AppSpacing.lg }),
  L.text(nil, AppTextStyle.bodySmall, "知乎搜索：https://www.zhihu.com/search?type=content&q=", { textIsSelectable = true, layout_marginBottom = AppSpacing.md }),
  L.text(nil, AppTextStyle.bodySmall, "必应搜索：https://www.bing.com/search?q=site%3Azhihu.com%20", { textIsSelectable = true, layout_marginBottom = AppSpacing.lg }),
  L.edit("edit", AppTextStyle.bodyMedium, "请输入搜索引擎地址")
}