-- core/app_text_style.lua
-- 字体、MD3 文字样式表与卡片样式

import "android.graphics.Typeface"

-- 屏幕信息：__index 时实时读 displayMetrics，旋转或分屏后仍取到当前值
_G.Screen = setmetatable({}, {
  __index = function(_, k)
    local m = activity.resources.displayMetrics
    if k == "width" then
      return m.widthPixels
     elseif k == "height" then
      return m.heightPixels
     elseif k == "density" then
      return m.density
     elseif k == "isTablet" then
      return m.widthPixels / m.density >= 600
    end
  end
})

-- 字体
if Extensions.Config.getBool(Constants.SharedDataKeys.USE_SYSTEM_FONT) then
  _G.Fonts = {
    regular = Typeface.create("sans-serif", Typeface.NORMAL),
    medium = Typeface.create("sans-serif-medium", Typeface.NORMAL),
    bold = Typeface.create("sans-serif", Typeface.BOLD),
  }
 else
  _G.Fonts = {
    regular = Helpers.Static.font("product"),
    medium = Helpers.Static.font("product-Medium"),
    bold = Helpers.Static.font("product-Bold"),
  }
end

local colors = AppTheme.colors
-- 参考 https://github.com/material-components/material-components-android/blob/master/docs/theming/Typography.md
_G.AppTextStyle = {
  -- ========== Display 超大展示文字 ==========
  -- 用于：空状态页、欢迎页、大数字展示（如倒计时、计数器）
  -- 对应 MD3: textAppearanceDisplayLarge
  displayLarge = {
    size = 57,
    lineHeight = 64,
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceDisplayMedium
  displayMedium = {
    size = 45,
    lineHeight = 52,
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceDisplaySmall
  displaySmall = {
    size = 36,
    lineHeight = 44,
    font = Fonts.regular,
    color = colors.onSurface
  },

  -- ========== Headline 页面级大标题 ==========
  -- 用于：详情页标题、文章标题、主要区块标题
  -- 对应 MD3: textAppearanceHeadlineLarge
  headlineLarge = {
    size = 32,
    lineHeight = 40,
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceHeadlineMedium
  headlineMedium = {
    size = 28,
    lineHeight = 36,
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceHeadlineSmall
  headlineSmall = {
    size = 24,
    lineHeight = 32,
    font = Fonts.regular,
    color = colors.onSurface
  },

  -- ========== Title 中等重要性标题 ==========
  -- 用于：卡片标题、对话框标题、列表项主文字、次级页面标题
  -- 对应 MD3: textAppearanceTitleLarge
  titleLarge = {
    size = 22,
    lineHeight = 28,
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceTitleMedium
  titleMedium = {
    size = 16,
    lineHeight = 24,
    font = Fonts.medium,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceTitleSmall
  titleSmall = {
    size = 14,
    lineHeight = 20,
    font = Fonts.medium,
    color = colors.onSurface
  },

  -- ========== Body 正文/描述文字 ==========
  -- 用于：长文本正文、卡片描述、列表项副文字
  -- 对应 MD3: textAppearanceBodyLarge
  bodyLarge = {
    size = 16,
    lineHeight = 24,
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceBodyMedium
  bodyMedium = {
    size = 14,
    lineHeight = 20,
    font = Fonts.regular,
    color = colors.onSurfaceVariant
  },
  -- 对应 MD3: textAppearanceBodySmall
  bodySmall = {
    size = 12,
    lineHeight = 16,
    font = Fonts.regular,
    color = colors.onSurfaceVariant
  },

  -- ========== Label 标签/辅助文字 ==========
  -- 用于：按钮文字、Tab标签、设置页分段标题、表单字段标签、提示文字
  -- 对应 MD3: textAppearanceLabelLarge
  labelLarge = {
    size = 14,
    lineHeight = 20,
    font = Fonts.medium,
    color = colors.primary
  },
  -- 对应 MD3: textAppearanceLabelMedium
  labelMedium = {
    size = 12,
    lineHeight = 16,
    font = Fonts.medium,
    color = colors.onSurfaceVariant
  },
  -- 对应 MD3: textAppearanceLabelSmall
  labelSmall = {
    size = 11,
    lineHeight = 16,
    font = Fonts.medium,
    color = colors.primary
  }
}

-- 卡片样式：运行时 dp2px 计算，脚本可随时覆写（如紧凑模式全局调边距）
_G.AppCardStyle = {
  -- 基础卡片样式
  basic = {
    marginLeft = dp2px(12),
    marginRight = dp2px(12),
    marginTop = dp2px(6),
    marginBottom = dp2px(0),

    innerPaddingLeft = dp2px(12),
    innerPaddingRight = dp2px(12),
    innerPaddingTop = dp2px(12),
    innerPaddingBottom = dp2px(12),
  },
  -- 子卡片样式（嵌套卡片）
  child = {
    marginLeft = dp2px(8),
    marginRight = dp2px(8),
    marginTop = dp2px(8),
    marginBottom = dp2px(0),
  },
  -- 设置/关于项目卡片样式
  setting = {
    marginLeft = dp2px(12),
    marginRight = dp2px(12),
    marginTop = dp2px(4),
    marginBottom = dp2px(0),

    innerPaddingLeft = dp2px(16),
    innerPaddingRight = dp2px(16),
    innerPaddingTop = dp2px(2),
    innerPaddingBottom = dp2px(2),
  }
}

-- 通用间距：运行时 dp2px 计算，脚本可随时覆写
_G.AppSpacing = {
  content = dp2px(16), -- 弹窗/表单/页面头部的内容边距
  list = dp2px(8),     -- 列表容器的贴边间距
  xs = dp2px(2),       -- 相邻元素的微间距（计数与图标之间）
  sm = dp2px(4),       -- 同组内元素的紧密间距
  md = dp2px(8),       -- 组内元素的常规间距
  lg = dp2px(12),      -- 跨组元素的间距
  xl = dp2px(16),      -- 区块级间距
}
