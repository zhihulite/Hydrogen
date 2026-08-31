-- layout/cards/comment.lua
-- 评论列表项布局（卡片内嵌子评论 RecyclerView）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.imageview.ShapeableImageView"
import "androidx.recyclerview.widget.RecyclerView"
import "android.view.View"

local colors = AppTheme.colors

local L = Helpers.Layout

local circleShapeModel = L.circleShape()
return L.card({ style = "basic", cardBackgroundColor = colors.surface, strokeColor = colors.outline,
  -- 内边距归 parent_comment 自己管：子评论列表与"更多回复"要按 52dp/12dp 绝对缩进对齐，
  -- 外层容器再叠一层 innerPadding 会让缩进整体右移
  inner = { layout_width = "fill", layout_height = "wrap_content",
    paddingLeft = 0, paddingRight = 0, paddingTop = 0, paddingBottom = 0 } },
{
  LinearLayoutCompat,
  id = "parent_comment",
  layout_width = "fill",
  layout_height = "wrap_content",
  paddingLeft = AppCardStyle.basic.innerPaddingLeft,
  paddingRight = AppCardStyle.basic.innerPaddingRight,
  paddingTop = AppCardStyle.basic.innerPaddingTop,
  paddingBottom = AppCardStyle.basic.innerPaddingBottom,
  {
    LinearLayoutCompat,
    orientation = "horizontal",
    layout_width = "fill",
    layout_height = "wrap_content",
    {
      ShapeableImageView,
      id = "avatar",
      layout_width = "36dp",
      layout_height = "36dp",
      shapeAppearanceModel = circleShapeModel,
    },
    {
      LinearLayoutCompat,
      orientation = "vertical",
      id = "content_container",
      layout_width = 0,
      layout_weight = 1,
      layout_height = "wrap_content",
      layout_marginLeft = "10dp",
      L.text("author_name", AppTextStyle.titleSmall, nil, { layout_width = "wrap_content", layout_height = "wrap_content", maxLines = 1, ellipsize = "end" }),
      L.text("comment_content", AppTextStyle.bodyMedium, nil, { layout_width = "fill", layout_height = "wrap_content", layout_marginTop = AppSpacing.sm, textIsSelectable = true }),
      {
        AppCompatImageView,
        id = "comment_image",
        layout_width = "wrap_content",
        layout_height = "wrap_content",
        layout_marginTop = AppSpacing.md,
        adjustViewBounds = true,
        scaleType = "centerCrop",
        visibility = View.GONE,
      },
      {
        LinearLayoutCompat,
        layout_width = "fill",
        layout_height = "wrap_content",
        layout_marginTop = "6dp",
        orientation = "horizontal",
        gravity = "center_vertical",
        L.text("comment_bottom", AppTextStyle.bodySmall, nil, { layout_width = "wrap_content", layout_height = "wrap_content" }),
        {
          View,
          layout_width = 0,
          layout_weight = 1,
          layout_height = "1dp",
        },
        L.metric("like", "outline_favorite_border", {gap = "3dp"}),
        {
          LinearLayoutCompat,
          id = "reply_layout",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
          layout_marginLeft = AppSpacing.xl,
          gravity = "center_vertical",
          {
            AppCompatImageView,
            id = "reply_icon",
            layout_width = "16dp",
            layout_height = "16dp",
            imageBitmap = Helpers.Static.materialIcon("twotone_message"),
            colorFilter = colors.onSurfaceVariant,
          },
          L.text("comment_count", AppTextStyle.bodySmall, "0", { layout_marginLeft = "3dp" })
        }
      }
    }
  },
},
{
  RecyclerView,
  id = "child_recycler",
  layout_width = "fill",
  layout_height = "wrap_content",
  paddingLeft = "52dp",
  paddingRight = "12dp",
  nestedScrollingEnabled = false,
  visibility = View.GONE,
},
-- 字号取 titleSmall、色与字重取 labelSmall（主题色强调的可点行）
L.text("more_replies", AppTextStyle.labelSmall, "", {
  layout_width = "fill",
  layout_height = "wrap_content",
  textSize = AppTextStyle.titleSmall.size,
  paddingLeft = "52dp",
  paddingRight = "12dp",
  paddingTop = "4dp",
  paddingBottom = "12dp",
  visibility = View.GONE,
})
)