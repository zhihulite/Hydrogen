-- helpers/layout.lua
-- 布局脚手架：把页面里反复出现的结构（卡片外壳、图标计数行、空状态页、列表页骨架）
-- 收敛成可组合的构造器。
-- 样式一律在调用时从 Lua 运行时全局取（AppTheme.colors / AppCardStyle / AppTextStyle），
-- 不引用编译期 res —— 主题/间距/字号保持脚本可控，布局文件只声明结构。
--
-- 用法：
--   local L = Helpers.Layout
--   return L.listPage({ toolbar = "toolbar", recyclerId = "recycler_view" })
--   return L.card({}, L.text("title", AppTextStyle.titleSmall), L.metricRow{ L.metric("like", "twotone_thumb_up") })

import "android.view.View"
import "android.widget.HorizontalScrollView"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "androidx.appcompat.widget.AppCompatEditText"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.appbar.MaterialToolbar"
import "com.google.android.material.tabs.TabLayout"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "com.hydrogen.view.CustomSwipeRefresh"
import "com.hydrogen.view.CustomViewPager"

local M = {}

-- M.card 的控制键：只影响脚手架自身的组装，不作为 MaterialCardView 属性透传
local CARD_CONTROL_KEYS = {
  style = true, paddingStyle = true, noMargin = true, horizontal = true, inner = true,
}

local circleShapeCache

--- 圆形（胶囊）ShapeAppearanceModel，进程内单例
--- @return any ShapeAppearanceModel
function M.circleShape()
  if not circleShapeCache then
    local builder = ShapeAppearanceModel.builder()
    builder.allCornerSizes = RelativeCornerSize(0.5)
    circleShapeCache = builder.build()
  end
  return circleShapeCache
end

-- ============================================
-- 文本行：MaterialTextView + 样式三件套
-- ============================================

--- 单个文本视图
--- @param id string|nil 视图 id（nil 时省略）
--- @param style table AppTextStyle 项（size/color/font）
--- @param text string|nil 初始文本
--- @param extra table|nil 附加属性（layout_marginTop 等）
--- @return table
function M.text(id, style, text, extra)
  local t = {
    MaterialTextView,
    text = text or "",
    textSize = style.size,
    textColor = style.color,
    typeface = style.font,
  }
  if id then t.id = id end
  if extra then
    for k, v in pairs(extra) do t[k] = v end
  end
  return t
end

--- 单行/多行输入框，样式三件套与 L.text 同源
--- @param id string|nil 视图 id（nil 时省略）
--- @param style table AppTextStyle 项（size/color/font）
--- @param hint string|nil 占位文案
--- @param extra table|nil 附加属性（maxLines / layout_margin / gravity 等）
--- @return table
function M.edit(id, style, hint, extra)
  local t = {
    AppCompatEditText,
    layout_width = "fill",
    hint = hint or "",
    textSize = style.size,
    textColor = style.color,
    typeface = style.font,
  }
  if id then t.id = id end
  if extra then
    for k, v in pairs(extra) do t[k] = v end
  end
  return t
end

--- 图标 + 文本横排行（空状态页/列表空行常用）
--- @param icon any Drawable
--- @param text string
--- @param iconTint number 颜色值
--- @return table
function M.iconTextRow(icon, text, iconTint)
  return {
    LinearLayoutCompat,
    layout_width = "wrap",
    layout_height = "wrap",
    orientation = "horizontal",
    gravity = "center",
    {
      AppCompatImageView,
      layout_width = "24dp",
      layout_height = "24dp",
      imageBitmap = icon,
      colorFilter = iconTint,
    },
    M.text(nil, AppTextStyle.bodyMedium, text, { layout_marginLeft = "8dp" }),
  }
end

--- 标题 + 副标题的空状态块
--- @param opts table { id, icon, iconTint, title, subtitle }
---   id 缺省 "empty_view"，页面经 views.empty_view 控制显隐
--- @return table
function M.emptyState(opts)
  return {
    LinearLayoutCompat,
    id = opts.id or "empty_view",
    layout_width = "fill",
    layout_height = "fill",
    gravity = "center",
    orientation = "vertical",
    visibility = View.GONE,
    {
      AppCompatImageView,
      layout_width = "80dp",
      layout_height = "80dp",
      layout_marginBottom = "16dp",
      imageBitmap = opts.icon,
      colorFilter = opts.iconTint,
    },
    M.text("empty_title", AppTextStyle.titleSmall, opts.title),
    M.text("empty_subtitle", AppTextStyle.bodySmall, opts.subtitle,
    { layout_marginTop = "8dp" }),
  }
end

-- ============================================
-- 卡片
-- ============================================

--- 标准卡片外壳：外层 wrapper + MaterialCardView + 内层纵向 LinearLayout。
--- 子元素依次排在 ... 里。
--- @param opts table|nil
---   style = "basic"|"child"|"setting"（AppCardStyle 键，边距与内边距来源）
---   paddingStyle = "basic"|"child"|"setting"（内边距来源，缺省同 style；
---     用于 child 边距 + basic 内边距的组合）
---   noMargin = true 卡片不留外边距（全宽贴边，设置页分组卡片形态）
---   horizontal = true 内层容器改横向
---   inner = { ... } 内层容器的覆盖属性（如 layout_width = "fill"）
---   其余键（cardBackgroundColor / clickable / id / strokeColor / strokeWidth /
---     radius / cardElevation 等）与 MaterialCardView 属性同名，原样透传
--- @param ... table 子元素
--- @return table
function M.card(opts, ...)
  opts = opts or {}
  local style = AppCardStyle[opts.style or "basic"]
  local padStyle = AppCardStyle[opts.paddingStyle or opts.style or "basic"]

  local inner = {
    LinearLayoutCompat,
    orientation = opts.horizontal and "horizontal" or "vertical",
    paddingLeft = padStyle.innerPaddingLeft,
    paddingRight = padStyle.innerPaddingRight,
    paddingTop = padStyle.innerPaddingTop,
    paddingBottom = padStyle.innerPaddingBottom,
  }
  if opts.inner then
    for k, v in pairs(opts.inner) do inner[k] = v end
  end
  for i = 1, select("#", ...) do
    inner[#inner + 1] = select(i, ...)
  end

  local card = {
    MaterialCardView,
    id = opts.id or "card",
    layout_width = "fill",
    layout_height = "wrap",
    layout_marginLeft = opts.noMargin and 0 or style.marginLeft,
    layout_marginRight = opts.noMargin and 0 or style.marginRight,
    layout_marginTop = opts.noMargin and 0 or style.marginTop,
    layout_marginBottom = opts.noMargin and 0 or style.marginBottom,
    cardBackgroundColor = opts.cardBackgroundColor or AppTheme.colors.surface,
    clickable = opts.clickable ~= false,
    inner,
  }
  -- 脚手架自身的控制键不进 View 属性，其余键按同名属性透传给 MaterialCardView
  for k, v in pairs(opts) do
    if not CARD_CONTROL_KEYS[k] then card[k] = v end
  end

  return {
    LinearLayoutCompat,
    layout_width = "fill",
    layout_height = "wrap",
    card,
  }
end

-- ============================================
-- 计量行（图标 + 数字）
-- ============================================

--- 单个计量组：图标 + 计数（点赞/评论/收藏等）
--- @param idPrefix string 如 "like"，生成 like_layout / like_icon / like_count
--- @param iconName string material 图标名（twotone_ 前缀自动补）
--- @param opts table|nil { iconSize, gap, padding, marginLeft }
--- @return table
function M.metric(idPrefix, iconName, opts)
  opts = opts or {}
  local size = opts.iconSize or "16dp"
  local t = {
    LinearLayoutCompat,
    id = idPrefix .. "_layout",
    gravity = "center",
    padding = opts.padding or 0,
    {
      AppCompatImageView,
      id = idPrefix .. "_icon",
      layout_width = size,
      layout_height = size,
      imageBitmap = Helpers.Static.materialIcon(iconName),
      colorFilter = AppTheme.colors.onSurfaceVariant,
    },
    {
      MaterialTextView,
      id = idPrefix .. "_count",
      text = "0",
      textSize = AppTextStyle.bodySmall.size,
      textColor = AppTextStyle.bodySmall.color,
      typeface = AppTextStyle.bodySmall.font,
      layout_marginLeft = opts.gap or "4dp",
    },
  }
  if opts.marginLeft then t.layout_marginLeft = opts.marginLeft end
  return t
end

--- 横向计量行：包一层水平 LinearLayout，常用于卡片底部（点赞/评论/收藏）
--- @param metrics table M.metric 的返回值列表
--- @param opts table|nil { marginTop }
--- @return table
function M.metricRow(metrics, opts)
  opts = opts or {}
  local t = {
    LinearLayoutCompat,
    orientation = "horizontal",
    layout_marginTop = opts.marginTop or "8dp",
  }
  for _, m in ipairs(metrics) do
    t[#t + 1] = m
  end
  return t
end

-- ============================================
-- 页面骨架
-- ============================================

--- 标准列表页骨架：toolbar +（可选 tab 条）+ 下拉刷新列表 + 空状态
--- @param opts table { toolbar, tabsId, recyclerId, refreshId, empty }
---   toolbar     toolbar 的 id（必填）
---   recyclerId  RecyclerView 的 id（必填）
---   refreshId   CustomSwipeRefresh 的 id（不传则 RecyclerView 直接作为页面主体，不包刷新层）
---   tabsId      tab 容器（HorizontalScrollView 内的 LinearLayout）的 id
---   empty       M.emptyState(opts) 的返回值
--- @return table
function M.listPage(opts)
  local page = {
    LinearLayoutCompat,
    layout_width = "fill",
    layout_height = "fill",
    orientation = "vertical",
    id = "main_container",
    backgroundColor = AppTheme.colors.background,
    {
      MaterialToolbar,
      id = opts.toolbar,
      layout_width = "fill",
      layout_height = "wrap",
    },
  }

  if opts.tabsId then
    table.insert(page, {
      HorizontalScrollView,
      layout_width = "fill",
      layout_height = "48dp",
      {
        LinearLayoutCompat,
        id = opts.tabsId,
        layout_width = "wrap",
        layout_height = "fill",
        orientation = "horizontal",
      },
    })
  end

  local list = {
    RecyclerView,
    id = opts.recyclerId,
    layout_width = "fill",
    layout_height = "fill",
    clipToPadding = false,
  }
  if opts.refreshId then
    list = {
      CustomSwipeRefresh,
      id = opts.refreshId,
      layout_width = "fill",
      layout_height = "fill",
      list,
    }
  end
  table.insert(page, list)

  if opts.empty then table.insert(page, opts.empty) end
  return page
end

--- 下拉刷新列表骨架：LinearLayoutCompat + CustomSwipeRefresh + RecyclerView
--- @param opts table { refreshId, recyclerId, padding, orientation }
---   refreshId   CustomSwipeRefresh 的 id，缺省 "swipe_refresh"
---   recyclerId  RecyclerView 的 id，缺省 "recycler_view"
---   padding     外层容器的 padding
---   orientation 外层容器的 orientation（缺省不设置）
--- @return table
function M.refreshList(opts)
  local container = {
    LinearLayoutCompat,
    layout_width = "fill",
    layout_height = "fill",
  }
  if opts.padding then container.padding = opts.padding end
  if opts.orientation then container.orientation = opts.orientation end
  container[#container + 1] = {
    CustomSwipeRefresh,
    id = opts.refreshId or "swipe_refresh",
    layout_width = "fill",
    layout_height = "fill",
    {
      RecyclerView,
      id = opts.recyclerId or "recycler_view",
      layout_width = "fill",
      layout_height = "fill",
      nestedScrollingEnabled = true,
    },
  }
  return container
end

--- Tab 页骨架：LinearLayoutCompat + TabLayout + CustomViewPager
--- @param opts table { tabId, pagerId, tabMode, tabHeight, elevation, padding }
---   tabId     TabLayout 的 id，缺省 "tab_layout"
---   pagerId   CustomViewPager 的 id，缺省 "view_pager"
---   tabMode   TabLayout 的 tabMode，缺省 TabLayout.MODE_SCROLLABLE
---   tabHeight TabLayout 的 layout_height，缺省 "wrap"
---   elevation TabLayout 的 elevation
---   padding   外层容器的 padding
--- @return table
function M.pagerPage(opts)
  local page = {
    LinearLayoutCompat,
    layout_width = "fill",
    layout_height = "fill",
    orientation = "vertical",
  }
  if opts.padding then page.padding = opts.padding end
  local tab = {
    TabLayout,
    id = opts.tabId or "tab_layout",
    layout_width = "fill",
    layout_height = opts.tabHeight or "wrap",
    tabMode = opts.tabMode or TabLayout.MODE_SCROLLABLE,
    tabGravity = TabLayout.GRAVITY_FILL,
  }
  if opts.elevation then tab.elevation = opts.elevation end
  page[#page + 1] = tab
  page[#page + 1] = {
    CustomViewPager,
    id = opts.pagerId or "view_pager",
    layout_width = "fill",
    layout_height = "fill",
    nestedScrollingEnabled = true,
  }
  return page
end

return M