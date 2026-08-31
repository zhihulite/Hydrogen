-- layout/pages/people/main.lua
-- 用户主页布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"
import "androidx.viewpager.widget.ViewPager"
import "com.google.android.material.tabs.TabLayout"
import "com.google.android.material.appbar.AppBarLayout"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.button.MaterialButton"
import "android.view.View"
import "androidx.coordinatorlayout.widget.CoordinatorLayout"

local L = Helpers.Layout

local colors = AppTheme.colors

local circleShapeModel = L.circleShape()
local userInfoCard = {
  MaterialCardView,
  id = "user_card",
  layout_width = "fill",
  layout_height = "wrap_content",
  layout_margin = AppSpacing.xl,
  cardBackgroundColor = colors.surface,
  strokeColor = colors.outline,
  layout_scrollFlags = 1,
  {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "wrap_content",
    padding = AppSpacing.content,
    {
      ShapeableImageView,
      id = "avatar",
      layout_width = "64dp",
      layout_height = "64dp",
      layout_gravity = "center",
      shapeAppearanceModel = circleShapeModel,
    },
    L.text("user_name", AppTextStyle.headlineSmall, "加载中", { layout_width = "wrap", layout_height = "wrap", layout_gravity = "center", layout_marginTop = "10dp" }),
    L.text("user_signature", AppTextStyle.bodyMedium, "", { layout_width = "wrap", layout_height = "wrap", layout_gravity = "center", layout_marginTop = "5dp" }),
    {
      LinearLayoutCompat,
      layout_width = "fill",
      layout_height = "wrap_content",
      layout_marginTop = AppSpacing.md,
      gravity = "center",
      {
        MaterialCardView,
        id = "voteup_card",
        layout_width = "wrap_content",
        layout_height = "wrap_content",
        cardBackgroundColor = colors.surfaceVariant,
        radius = "8dp",
        strokeWidth = 0,
        elevation = 0,
        L.text("voteup_count", AppTextStyle.bodySmall, "0 获赞", { layout_width = "wrap", layout_height = "wrap", padding = "8dp" }),
      },
      {
        View,
        layout_width = "8dp",
        layout_height = "1dp",
      },
      {
        MaterialCardView,
        id = "fans_card",
        layout_width = "wrap_content",
        layout_height = "wrap_content",
        cardBackgroundColor = colors.surfaceVariant,
        radius = "8dp",
        strokeWidth = 0,
        elevation = 0,
        L.text("fans_count", AppTextStyle.bodySmall, "0 粉丝", { layout_width = "wrap", layout_height = "wrap", padding = "8dp" }),
      },
      {
        View,
        layout_width = "8dp",
        layout_height = "1dp",
      },
      {
        MaterialCardView,
        id = "follow_card",
        layout_width = "wrap_content",
        layout_height = "wrap_content",
        cardBackgroundColor = colors.surfaceVariant,
        radius = "8dp",
        strokeWidth = 0,
        elevation = 0,
        L.text("follow_count", AppTextStyle.bodySmall, "0 关注", { layout_width = "wrap", layout_height = "wrap", padding = "8dp" }),
      },
    },
    {
      LinearLayoutCompat,
      id = "action_buttons",
      layout_width = "fill",
      layout_height = "wrap_content",
      layout_marginTop = "10dp",
      gravity = "center",
      visibility = "gone",
      {
        MaterialButton,
        id = "follow_btn",
        layout_width = "wrap_content",
        layout_height = "36dp",
        text = "关注",
        cornerRadius = "18dp",
        textSize = AppTextStyle.labelSmall.size,
        typeface = AppTextStyle.labelSmall.font,
        paddingLeft = "16dp",
        paddingRight = "16dp",
      },
      {
        MaterialButton,
        id = "message_btn",
        layout_width = "wrap_content",
        layout_height = "36dp",
        layout_marginLeft = "10dp",
        text = "私信",
        cornerRadius = "18dp",
        textSize = AppTextStyle.labelSmall.size,
        typeface = AppTextStyle.labelSmall.font,
        paddingLeft = "16dp",
        paddingRight = "16dp",
      },
    },
  },
}

return {
  CoordinatorLayout,
  id = "main_container",
  layout_width = "fill",
  layout_height = "fill",
  backgroundColor = colors.background,
  {
    AppBarLayout,
    id = "appbar",
    layout_width = "fill",
    layout_height = "wrap_content",
    {
      MaterialToolbar,
      id = "toolbar",
      layout_width = "fill",
      layout_height = "wrap",
      layout_scrollFlags="scroll",
    },
    userInfoCard,
    {
      TabLayout,
      id = "tab_layout",
      layout_width = "fill",
      layout_height = "wrap",
      tabMode = TabLayout.MODE_SCROLLABLE,
      tabGravity = TabLayout.GRAVITY_FILL,
      layout_scrollFlags = 0,
    },
  },
  {
    ViewPager,
    id = "view_pager",
    layout_width = "fill",
    layout_height = "fill",
    clipToPadding = false,
    layout_behavior = "@string/appbar_scrolling_view_behavior",
  },
}