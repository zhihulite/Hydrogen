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
import "com.google.android.material.behavior.HideBottomViewOnScrollBehavior"

local colors = AppTheme.getColors()
local actionBarSize = Helpers.Resources.android.attr.actionBarSize
local toolbarHeight = actionBarSize

local floatingToolbar = {
  FloatingToolbarLayout,
  id = "floating_toolbar",
  layout_width = "wrap_content",
  layout_height = "wrap_content",
  layout_gravity = "bottom|center",
  layout_marginBottom = "16dp",
  layout_behavior = "hide_bottom_view_on_scroll_behavior",
  {
    LinearLayoutCompat,
    orientation = "horizontal",
    layout_width = "wrap_content",
    layout_height = "56dp",
    gravity = "center",
    paddingLeft = "8dp",
    paddingRight = "8dp",
    {
      LinearLayoutCompat,
      id = "vote_btn",
      layout_width = "wrap_content",
      layout_height = "fill",
      gravity = "center",
      orientation = "horizontal",
      paddingLeft = "12dp",
      paddingRight = "12dp",
      {
        AppCompatImageView,
        id = "vote_icon",
        layout_width = "24dp",
        layout_height = "24dp",
        ImageBitmap = Helpers.Static.materialIcon("outline_thumb_up"),
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
      paddingLeft = "12dp",
      paddingRight = "12dp",
      {
        AppCompatImageView,
        id = "thank_icon",
        layout_width = "24dp",
        layout_height = "24dp",
        ImageBitmap = Helpers.Static.materialIcon("outline_favorite_border"),
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
      paddingLeft = "12dp",
      paddingRight = "12dp",
      {
        AppCompatImageView,
        id = "collect_icon",
        layout_width = "24dp",
        layout_height = "24dp",
        ImageBitmap = Helpers.Static.materialIcon("outline_bookmark_border"),
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
      {
        LinearLayoutCompat,
        id = "comment_btn",
        layout_width = "wrap_content",
        layout_height = "fill",
        gravity = "center",
        orientation = "horizontal",
        paddingLeft = "12dp",
        paddingRight = "12dp",
        {
          AppCompatImageView,
          layout_width = "24dp",
          layout_height = "24dp",
          ImageBitmap = Helpers.Static.materialIcon("twotone_message"),
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
  layout_gravity = "bottom|end",
  layout_marginRight = "16dp",
  layout_marginBottom = "80dp",
  radius = "28dp",
  cardElevation = "0dp",
  cardBackgroundColor = colors.surface,
  alpha = 0.9,
  Visibility = 8,
  {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "wrap_content",
    layout_height = "wrap_content",
    gravity = "center",
    {
      AppCompatImageView,
      id = "scroll_up",
      layout_width = "40dp",
      layout_height = "40dp",
      ImageBitmap = Helpers.Static.materialIcon("twotone_arrow_drop_up"),
      colorFilter = colors.primary,
      padding = "8dp",
    },
    {
      AppCompatImageView,
      id = "scroll_down",
      layout_width = "40dp",
      layout_height = "40dp",
      ImageBitmap = Helpers.Static.materialIcon("twotone_arrow_drop_down"),
      colorFilter = colors.primary,
      padding = "8dp",
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