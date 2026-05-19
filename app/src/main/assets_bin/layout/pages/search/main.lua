-- layout/pages/search/main.lua
-- 搜索页面布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.appbar.MaterialToolbar"
import "androidx.appcompat.widget.SearchView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.core.widget.NestedScrollView"
import "androidx.recyclerview.widget.RecyclerView"
import "androidx.recyclerview.widget.GridLayoutManager"
import "androidx.recyclerview.widget.LinearLayoutManager"
import "com.google.android.material.chip.ChipGroup"
import "android.view.View"

local colors = AppTheme.getColors()

local hotGridLayoutManager = GridLayoutManager(activity, 2)
local suggestLayoutManager = LinearLayoutManager(activity, RecyclerView.VERTICAL, false)

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  id = "main_container",
  backgroundColor = colors.background,
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "fill",
    layout_height = "wrap",
  },
  {
    SearchView,
    id = "search_view",
    layout_width = "fill",
    layout_height = "wrap_content",
    queryHint = "搜索知乎内容",
  },
  {
    NestedScrollView,
    id = "main_content",
    layout_width = "fill",
    layout_height = "fill",
    fillViewport = true,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap_content",
      {
        MaterialTextView,
        text = "热门搜索",
        textSize = AppTextStyle.label.size,
        textColor = AppTextStyle.label.color,
        typeface = AppTextStyle.label.font,
        layout_marginLeft = "20dp",
        layout_marginTop = "16dp",
        layout_marginBottom = "8dp",
      },
      {
        RecyclerView,
        id = "hot_grid",
        layout_width = "fill",
        layout_height = "wrap_content",
        layout_marginLeft = "12dp",
        layout_marginRight = "12dp",
        layoutManager = hotGridLayoutManager,
        nestedScrollingEnabled = false,
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "wrap_content",
        layout_marginLeft = "20dp",
        layout_marginRight = "20dp",
        layout_marginTop = "16dp",
        gravity = "center_vertical",
        {
          MaterialTextView,
          text = "历史记录",
          textSize = AppTextStyle.label.size,
          textColor = AppTextStyle.label.color,
          typeface = AppTextStyle.label.font,
          layout_weight = 1,
        },
        {
          MaterialTextView,
          id = "clear_btn",
          text = "清空",
          textSize = AppTextStyle.label.size,
          textColor = AppTextStyle.label.color,
          typeface = AppTextStyle.label.font,
          clickable = true,
        }
      },
      {
        ChipGroup,
        id = "chip_group",
        layout_width = "fill",
        layout_height = "wrap_content",
        layout_margin = "12dp",
      }
    }
  },
  {
    RecyclerView,
    id = "suggest_list",
    layout_width = "fill",
    layout_height = "fill",
    visibility = View.GONE,
    layoutManager = suggestLayoutManager,
  }
}