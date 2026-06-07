-- layout/pages/answer/main.lua
-- answer 主布局

import "androidx.coordinatorlayout.widget.CoordinatorLayout"
import "com.google.android.material.appbar.AppBarLayout"
import "com.google.android.material.appbar.CollapsingToolbarLayout"
import "com.google.android.material.appbar.MaterialToolbar"
import "androidx.viewpager2.widget.ViewPager2"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.floatingtoolbar.FloatingToolbarLayout"

local colors = AppTheme.colors
local actionBarSize = Helpers.Resources.android.attr.actionBarSize
local toolbarHeight = actionBarSize

local floatingToolbar = {
  FloatingToolbarLayout,
  id = "floating_toolbar",
  layout_width = "match_parent",
  layout_height = "wrap_content",
  layout_gravity = "bottom|center",
  layout_marginBottom = "16dp",
  layout_marginLeft = "8dp",
  layout_marginRight = "8dp",
  layout_behavior = "hide_bottom_view_on_scroll_behavior",
  {
    LinearLayoutCompat,
    orientation = "horizontal",
    layout_width = "match_parent",
    -- FrameLayout 使用 minHeight 时，子布局 layout_height 设置 match_parent 不生效
    layout_height = "56dp",
    gravity = "center",
    {
      LinearLayoutCompat,
      id = "vote_btn",
      layout_width = "wrap_content",
      layout_height = "fill",
      gravity = "center",
      orientation = "horizontal",
      layout_weight = 1,
      {
        AppCompatImageView,
        id = "vote_icon",
        layout_width = "24dp",
        layout_height = "24dp",
        imageBitmap = Helpers.Static.materialIcon("outline_thumb_up"),
        colorFilter = colors.primary,
      },
      {
        MaterialTextView,
        id = "vote_count",
        layout_marginLeft = "4dp",
        text = "0",
        textSize = AppTextStyle.bodySmall.size,
        textColor = colors.onSurfaceVariant,
        typeface = AppTextStyle.bodySmall.font,
      }
    },
    {
      LinearLayoutCompat,
      id = "thank_btn",
      layout_width = "wrap_content",
      layout_height = "fill",
      gravity = "center",
      orientation = "horizontal",
      layout_weight = 1,
      {
        AppCompatImageView,
        id = "thank_icon",
        layout_width = "24dp",
        layout_height = "24dp",
        imageBitmap = Helpers.Static.materialIcon("outline_favorite_border"),
        colorFilter = colors.primary,
      },
      {
        MaterialTextView,
        id = "thank_count",
        layout_marginLeft = "4dp",
        text = "0",
        textSize = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface = AppTextStyle.bodySmall.font,
      }
    },
    {
      LinearLayoutCompat,
      id = "collect_btn",
      layout_width = "wrap_content",
      layout_height = "fill",
      gravity = "center",
      orientation = "horizontal",
      layout_weight = 1,
      {
        AppCompatImageView,
        id = "collect_icon",
        layout_width = "24dp",
        layout_height = "24dp",
        imageBitmap = Helpers.Static.materialIcon("outline_bookmark_border"),
        colorFilter = colors.primary,
      },
      {
        MaterialTextView,
        id = "collect_count",
        layout_marginLeft = "4dp",
        text = "0",
        textSize = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface = AppTextStyle.bodySmall.font,
      }
    },
    {
      MaterialCardView;
      id="comment_card";
      layout_width="wrap",
      layout_height="match",
      radius="28dp";
      elevation=0;
      cardBackgroundColor = colors.SurfaceContainer,
      layout_weight = 1,
      {
        LinearLayoutCompat,
        id = "comment_btn",
        layout_width = "fill",
        layout_height = "fill",
        gravity = "center",
        orientation = "horizontal",
        paddingLeft = "12dp",
        paddingRight = "12dp",
        {
          AppCompatImageView,
          layout_width = "24dp",
          layout_height = "24dp",
          imageBitmap = Helpers.Static.materialIcon("twotone_message"),
          colorFilter = colors.primary,
        },
        {
          MaterialTextView,
          id = "comment_count",
          layout_marginLeft = "4dp",
          text = "0",
          textSize = AppTextStyle.bodySmall.size,
          textColor = AppTextStyle.bodySmall.color,
          typeface = AppTextStyle.bodySmall.font,
        }
      },
    },
  }
}

-- 浮动滚动按钮
local floatScrollButtons = {
  MaterialCardView,
  id = "float_scroll_container",
  layout_width = "wrap_content",
  layout_height = "wrap_content",
  layout_gravity = "end|bottom",
  layout_marginRight = "16dp",
  layout_marginBottom = "100dp",
  radius = "28dp",
  alpha = 0.9,
  cardBackgroundColor = colors.surfaceContainer,
  visibility = View.GONE,
  {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "wrap_content",
    layout_height = "wrap_content",
    gravity = "center",
    {
      AppCompatImageView,
      id = "scroll_up",
      layout_width = "36dp",
      layout_height = "36dp",
      imageBitmap = Helpers.Static.materialIcon("twotone_keyboard_arrow_up"),
      colorFilter = colors.primary,
      padding = "6dp",
    },
    {
      AppCompatImageView,
      id = "scroll_down",
      layout_width = "36dp",
      layout_height = "36dp",
      imageBitmap = Helpers.Static.materialIcon("twotone_keyboard_arrow_down"),
      colorFilter = colors.primary,
      padding = "6dp",
    },
  }
}


return {
  CoordinatorLayout,
  id = "coordinator",
  layout_width = "fill",
  layout_height = "fill",
  id = "main_container",
  backgroundColor = colors.background,
  {
    AppBarLayout,
    id = "appbar",
    layout_width = "fill",
    layout_height = "wrap_content",
    {
      CollapsingToolbarLayout,
      id = "collapsing_toolbar",
      layout_width = "fill",
      layout_height = "wrap_content",
      layout_scrollFlags = "scroll|exitUntilCollapsed",
      scrimVisibleHeightTrigger = 1,
      {
        MaterialToolbar,
        id = "toolbar",
        layout_width = "fill",
        layout_height = toolbarHeight,
        layout_collapseMode = "pin"
      },
    },
  },
  {
    ViewPager2,
    id = "view_pager",
    layout_width = "fill",
    layout_height = "fill",
    layout_behavior = "appbar_scrolling_view_behavior",
  },
  floatingToolbar,
  floatScrollButtons,
}