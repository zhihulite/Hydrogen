-- layout/pages/search/main.lua
-- 搜索页面布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.appbar.MaterialToolbar"
import "androidx.appcompat.widget.SearchView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.core.widget.NestedScrollView"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.chip.ChipGroup"
import "androidx.appcompat.widget.AppCompatImageView"
import "android.view.View"
import "android.content.res.ColorStateList"

local colors = AppTheme.colors
local marginLeft = AppCardStyle.basic.marginLeft
local marginRight = AppCardStyle.basic.marginRight

return {
  LinearLayoutCompat,
  id = "main_container",
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
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
    layout_height = "wrap",
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
      layout_height = "wrap",
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "wrap",
        layout_marginLeft = marginLeft,
        layout_marginRight = marginRight,
        layout_marginTop = "16dp",
        layout_marginBottom = "8dp",
        gravity = "center_vertical",
        {
          MaterialTextView,
          id = "hot_title",
          text = "热门搜索",
          textSize = AppTextStyle.labelLarge.size,
          textColor = AppTextStyle.labelLarge.color,
          typeface = AppTextStyle.labelLarge.font,
          layout_weight = 1,
        },
        {
          Helpers.MaterialWidgets.IconButton_ExtraSmall,
          id = "refresh_btn",
          layout_width = "wrap",
          layout_height = "wrap",
          icon = Helpers.Static.materialDrawable("twotone_refresh", 24, true),
          iconTint = ColorStateList.valueOf(AppTextStyle.labelLarge.color),
          clickable = true,
        }
      },
      {
        RecyclerView,
        id = "hot_grid",
        layout_width = "fill",
        layout_height = "wrap",
        nestedScrollingEnabled = false,
      },
      {
        LinearLayoutCompat,
        id = "history_header",
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "wrap",
        layout_marginLeft = marginLeft,
        layout_marginRight = marginRight,
        layout_marginTop = "16dp",
        gravity = "center_vertical",
        {
          MaterialTextView,
          text = "历史记录",
          textSize = AppTextStyle.labelLarge.size,
          textColor = AppTextStyle.labelLarge.color,
          typeface = AppTextStyle.labelLarge.font,
          layout_weight = 1,
        },
        {
          Helpers.MaterialWidgets.IconButton_ExtraSmall,
          id = "clear_btn",
          layout_width = "wrap",
          layout_height = "wrap",
          icon = Helpers.Static.materialDrawable("twotone_delete", 24, true),
          iconTint = ColorStateList.valueOf(AppTextStyle.labelLarge.color),
          clickable = true,
        }
      },
      {
        ChipGroup,
        id = "chip_group",
        layout_width = "fill",
        layout_height = "wrap",
        layout_marginLeft = marginLeft,
        layout_marginRight = marginRight,
        layout_marginTop = "12dp",
        layout_marginBottom = "16dp",
      }
    }
  },
  {
    RecyclerView,
    id = "suggest_list",
    layout_width = "fill",
    layout_height = "fill",
    visibility = View.GONE,
  }
}