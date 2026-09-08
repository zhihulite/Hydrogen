-- layout/pages/theme_picker/preview.lua
-- 主题预览：用当前配色渲染一张迷你样例卡（标题/正文/按钮/强调点）

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.card.MaterialCardView"

local L = Helpers.Layout

local colors = AppTheme.colors

return {
  LinearLayoutCompat,
  orientation = "vertical",
  layout_width = "fill",
  layout_height = "wrap",
  paddingLeft = AppSpacing.xl,
  paddingRight = AppSpacing.xl,
  paddingTop = "2dp",
  paddingBottom = "10dp",
  L.text(nil, AppTextStyle.labelMedium, "预览", { textColor = colors.onSurfaceVariant, layout_marginBottom = "6dp" }),
  {
    MaterialCardView,
    id = "preview_card",
    layout_width = "300dp",
    layout_height = "wrap",
    radius = "16dp",
    cardElevation = 0,
    strokeWidth = dp2px(1),
    strokeColor = colors.outlineVariant,
    cardBackgroundColor = colors.surface,
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "fill",
      layout_height = "wrap",
      paddingLeft = "16dp",
      paddingRight = "16dp",
      paddingTop = "14dp",
      paddingBottom = "14dp",
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "fill",
        layout_height = "wrap",
        gravity = "center_vertical",
        L.text("preview_title", AppTextStyle.titleSmall, "示例文本", { layout_width = 0, layout_weight = 1 }),
        { MaterialCardView, id = "preview_secondary", layout_width = "16dp", layout_height = "16dp", radius = "8dp", cardElevation = 0, strokeWidth = 0 },
        { MaterialCardView, id = "preview_tertiary", layout_width = "16dp", layout_height = "16dp", layout_marginLeft = "6dp", radius = "8dp", cardElevation = 0, strokeWidth = 0 },
      },
      L.text("preview_body", AppTextStyle.bodySmall, "预览当前主题的文字与按钮效果", { layout_marginTop = "6dp" }),
      {
        MaterialCardView,
        id = "preview_btn",
        layout_width = "wrap",
        layout_height = "wrap",
        layout_marginTop = "12dp",
        radius = "18dp",
        cardElevation = 0,
        strokeWidth = 0,
        {
          LinearLayoutCompat,
          layout_width = "wrap",
          layout_height = "wrap",
          paddingLeft = "20dp",
          paddingRight = "20dp",
          paddingTop = "8dp",
          paddingBottom = "8dp",
          L.text("preview_btn_label", AppTextStyle.labelLarge, "主要按钮"),
        }
      },
    }
  },
  L.text("preview_hex", AppTextStyle.bodySmall, "", { layout_marginTop = "6dp", textColor = colors.onSurfaceVariant }),
}
