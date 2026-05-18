-- layout/pages/people/main.lua
-- 用户主页布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"
import "androidx.viewpager.widget.ViewPager"
import "com.google.android.material.tabs.TabLayout"
import "com.google.android.material.appbar.AppBarLayout"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"
import "androidx.coordinatorlayout.widget.CoordinatorLayout"

local colors = AppTheme.getColors()

local circleShape = ShapeAppearanceModel.builder()
.setAllCornerSizes(RelativeCornerSize(0.5))
.build()

local userInfoCard = {
  MaterialCardView,
  id = "user_card",
  layout_width = "fill",
  layout_height = "wrap_content",
  layout_margin = "16dp",
  cardBackgroundColor = colors.surface,
  strokeColor = colors.outline,
  layout_scrollFlags = 1,
  {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "fill",
    layout_height = "wrap_content",
    padding = "16dp",
    {
      ShapeableImageView,
      id = "avatar",
      layout_width = "64dp",
      layout_height = "64dp",
      layout_gravity = "center",
      shapeAppearanceModel = circleShape,
    },
    {
      MaterialTextView,
      id = "user_name",
      layout_width = "wrap",
      layout_height = "wrap",
      layout_gravity = "center",
      text = "加载中",
      textSize = AppTextStyle.headline.size,
      textColor = AppTextStyle.headline.color,
      typeface = AppTextStyle.headline.font,
      layout_marginTop = "10dp",
    },
    {
      MaterialTextView,
      id = "user_signature",
      layout_width = "wrap",
      layout_height = "wrap",
      layout_gravity = "center",
      text = "",
      textSize = AppTextStyle.body.size,
      textColor = AppTextStyle.body.color,
      typeface = AppTextStyle.body.font,
      layout_marginTop = "5dp",
    },
    {
      LinearLayoutCompat,
      layout_width = "fill",
      layout_height = "wrap_content",
      layout_marginTop = "8dp",
      gravity = "center",
      {
        MaterialCardView,
        id = "voteup_card",
        layout_width = "wrap_content",
        layout_height = "wrap_content",
        cardBackgroundColor = colors.surfaceVariant,
        radius = "8dp",
        strokeWidth = "0dp",
        elevation = "0dp",
        {
          MaterialTextView,
          id = "voteup_count",
          layout_width = "wrap",
          layout_height = "wrap",
          padding = "8dp",
          text = "0 获赞",
          textSize = AppTextStyle.caption.size,
          textColor = AppTextStyle.caption.color,
          typeface = AppTextStyle.caption.font,
        },
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
        strokeWidth = "0dp",
        elevation = "0dp",
        {
          MaterialTextView,
          id = "fans_count",
          layout_width = "wrap",
          layout_height = "wrap",
          padding = "8dp",
          text = "0 粉丝",
          textSize = AppTextStyle.caption.size,
          textColor = AppTextStyle.caption.color,
          typeface = AppTextStyle.caption.font,
        },
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
        strokeWidth = "0dp",
        elevation = "0dp",
        {
          MaterialTextView,
          id = "follow_count",
          layout_width = "wrap",
          layout_height = "wrap",
          padding = "8dp",
          text = "0 关注",
          textSize = AppTextStyle.caption.size,
          textColor = AppTextStyle.caption.color,
          typeface = AppTextStyle.caption.font,
        },
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
        textSize = AppTextStyle.label.size,
        typeface = AppTextStyle.label.font,
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
        textSize = AppTextStyle.label.size,
        typeface = AppTextStyle.label.font,
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
    layout_behavior = "appbar_scrolling_view_behavior",
  },
}