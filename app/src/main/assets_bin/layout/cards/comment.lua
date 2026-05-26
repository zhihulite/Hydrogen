-- layout/cards/comment.lua
-- 评论列表项布局（卡片内嵌子评论 RecyclerView）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.imageview.ShapeableImageView"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "androidx.recyclerview.widget.RecyclerView"
import "android.view.View"

local colors = AppTheme.colors

local circleShapeBuilder = ShapeAppearanceModel.builder()
circleShapeBuilder.allCornerSizes = RelativeCornerSize(0.5)
local circleShapeModel = circleShapeBuilder.build()

return {
  LinearLayoutCompat,
  layout_width = "match_parent",
  layout_height = "wrap_content",
  orientation = "vertical",
  backgroundColor = colors.background,
  {
    MaterialCardView,
    id = "card",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    layout_marginLeft = "12dp",
    layout_marginRight = "12dp",
    layout_marginTop = "4dp",
    layout_marginBottom = "4dp",
    cardBackgroundColor = colors.surface,
    strokeColor = colors.outline,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      {
        LinearLayoutCompat,
        id = "parent_comment",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "12dp",
        {
          LinearLayoutCompat,
          orientation = "horizontal",
          layout_width = "match_parent",
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
            {
              MaterialTextView,
              id = "author_name",
              layout_width = "wrap_content",
              layout_height = "wrap_content",
              textSize = AppTextStyle.titleSmall.size,
              textColor = AppTextStyle.titleSmall.color,
              typeface = AppTextStyle.titleSmall.font,
              maxLines = 1,
              ellipsize = "end",
            },
            {
              MaterialTextView,
              id = "comment_content",
              layout_width = "match_parent",
              layout_height = "wrap_content",
              layout_marginTop = "4dp",
              textSize = AppTextStyle.bodyMedium.size,
              textColor = AppTextStyle.bodyMedium.color,
              typeface = AppTextStyle.bodyMedium.font,
              textIsSelectable = true,
            },
            {
              AppCompatImageView,
              id = "comment_image",
              layout_width = "wrap_content",
              layout_height = "wrap_content",
              layout_marginTop = "8dp",
              adjustViewBounds = true,
              scaleType = "centerCrop",
              visibility = View.GONE,
            },
            {
              LinearLayoutCompat,
              layout_width = "match_parent",
              layout_height = "wrap_content",
              layout_marginTop = "6dp",
              orientation = "horizontal",
              gravity = "center_vertical",
              {
                MaterialTextView,
                id = "comment_bottom",
                layout_width = "wrap_content",
                layout_height = "wrap_content",
                textSize = AppTextStyle.bodySmall.size,
                textColor = AppTextStyle.bodySmall.color,
                typeface = AppTextStyle.bodySmall.font,
              },
              {
                View,
                layout_width = 0,
                layout_weight = 1,
                layout_height = "1dp",
              },
              {
                LinearLayoutCompat,
                id = "like_layout",
                layout_width = "wrap_content",
                layout_height = "wrap_content",
                gravity = "center_vertical",
                {
                  AppCompatImageView,
                  id = "like_icon",
                  layout_width = "16dp",
                  layout_height = "16dp",
                  imageBitmap = Helpers.Static.materialIcon("outline_favorite_border"),
                  colorFilter = colors.onSurfaceVariant,
                },
                {
                  MaterialTextView,
                  id = "like_count",
                  layout_marginLeft = "3dp",
                  text = "0",
                  textSize = AppTextStyle.bodySmall.size,
                  textColor = AppTextStyle.bodySmall.color,
                  typeface = AppTextStyle.bodySmall.font,
                }
              },
              {
                LinearLayoutCompat,
                id = "reply_layout",
                layout_width = "wrap_content",
                layout_height = "wrap_content",
                layout_marginLeft = "16dp",
                gravity = "center_vertical",
                {
                  AppCompatImageView,
                  id = "reply_icon",
                  layout_width = "16dp",
                  layout_height = "16dp",
                  imageBitmap = Helpers.Static.materialIcon("twotone_message"),
                  colorFilter = colors.onSurfaceVariant,
                },
                {
                  MaterialTextView,
                  id = "comment_count",
                  layout_marginLeft = "3dp",
                  text = "0",
                  textSize = AppTextStyle.bodySmall.size,
                  textColor = AppTextStyle.bodySmall.color,
                  typeface = AppTextStyle.bodySmall.font,
                }
              }
            }
          }
        },
      },
      {
        RecyclerView,
        id = "child_recycler",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        paddingLeft = "52dp",
        paddingRight = "12dp",
        nestedScrollingEnabled = false,
        visibility = View.GONE,
      },
      {
        MaterialTextView,
        id = "more_replies",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        text = "",
        textSize = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.labelSmall.color,
        typeface = AppTextStyle.labelSmall.font,
        paddingLeft = "52dp",
        paddingRight = "12dp",
        paddingTop = "4dp",
        paddingBottom = "12dp",
        visibility = View.GONE,
      }
    }
  }
}