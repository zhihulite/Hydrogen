-- pages/fragment/theme_picker/theme_picker_fragment.lua
-- 主题选择器 Fragment：选择只更新选中态与预览，底部「应用主题」按钮统一提交（重启生效）

import "android.content.Intent"
import "android.content.DialogInterface"
import "android.net.Uri"
import "android.graphics.BitmapFactory"
import "android.widget.FrameLayout"
import "android.view.View"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatImageView"
import "androidx.appcompat.widget.AppCompatEditText"
import "android.text.InputType"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.chip.Chip"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

local BaseFragment = require("pages.base.base_fragment")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
local SafeLinearLayoutManager = luajava.bindClass("com.hydrogen.SafeLinearLayoutManager")
local String = luajava.bindClass("java.lang.String")
local ThemeColors = luajava.bindClass("com.hydrogen.theme.ThemeColors")

local ThemePickerFragment = Extensions.Class(BaseFragment)

-- 预设静态主题 ID 列表
local allThemeIds = {
  "Default",
  "Monet",
  "Teal",
  "Orange",
  "Pink",
  "Red",
}

-- 预设种子色板：跨色相的常用取色，hex 与存储格式一致
local seedColors = {
  { name = "红", hex = "#B3261E" },
  { name = "玫红", hex = "#B3235C" },
  { name = "紫", hex = "#7D3FBF" },
  { name = "靛蓝", hex = "#3F51B5" },
  { name = "蓝", hex = "#1565C0" },
  { name = "青", hex = "#00838F" },
  { name = "绿", hex = "#2E7D32" },
  { name = "黄绿", hex = "#689F38" },
  { name = "琥珀", hex = "#B26A00" },
  { name = "棕", hex = "#795548" },
  { name = "石墨", hex = "#546E7A" },
}

-- 配色方案名直接用原名：key 与 Java 侧 ThemeColors.variantNames 一致
local variantNames = {
  { key = "Content" },
  { key = "Vibrant" },
  { key = "Expressive" },
  { key = "Fidelity" },
  { key = "FruitSalad" },
  { key = "Neutral" },
  { key = "Monochrome" },
  { key = "Rainbow" },
  { key = "TonalSpot" },
}

-- 对比度等级：与 Scheme 构造的 contrastLevel 对应
local contrastLevels = {
  { value = -1, title = "降低" },
  { value = 0, title = "标准" },
  { value = 1, title = "提高" },
}

local resources = activity.resources
local packageName = activity.packageName

-- 主题角色色属性 ID（primary/onPrimary/secondary/tertiary），惰性解析缓存
local roleAttrIds

-- 取某静态主题的角色色，用于预设主题的即时预览
local function getThemeRoleColors(themeId)
  local resId = resources.getIdentifier("Theme." .. themeId, "style", packageName)
  if resId == 0 then return nil end
  if not roleAttrIds then
    roleAttrIds = {
      resources.getIdentifier("colorPrimary", "attr", packageName),
      resources.getIdentifier("colorOnPrimary", "attr", packageName),
      resources.getIdentifier("colorSecondary", "attr", packageName),
      resources.getIdentifier("colorTertiary", "attr", packageName),
      resources.getIdentifier("colorSurface", "attr", packageName),
      resources.getIdentifier("colorOnSurface", "attr", packageName),
      resources.getIdentifier("colorOnSurfaceVariant", "attr", packageName),
    }
  end
  local ta = activity.obtainStyledAttributes(resId, roleAttrIds)
  local c = { ta.getColor(0, 0), ta.getColor(1, 0), ta.getColor(2, 0), ta.getColor(3, 0), ta.getColor(4, 0), ta.getColor(5, 0), ta.getColor(6, 0) }
  ta.recycle()
  return c
end

-- 静态主题的 primary，用于主题色块填充色
local function getThemePrimaryColor(themeId)
  local c = getThemeRoleColors(themeId)
  return c and c[1] or 0
end

-- 种子色 hex 转 ARGB int
local function hexToColor(hex)
  local rgb = hex:match("^#(%x%x%x%x%x%x)$")
  if not rgb then return 0 end
  return 0xFF000000 | tonumber(rgb, 16)
end

function ThemePickerFragment:ctor()
  self.adapter = nil
  self.items = {}
end

function ThemePickerFragment:onCreate(params)
  -- 已应用的配置（快照，用于判断是否有改动）
  self.appliedTheme = Extensions.Config.getString(Constants.SharedDataKeys.THEME_SETTING) or "Default"
  self.appliedSeed = Extensions.Config.getString(Constants.SharedDataKeys.CUSTOM_SEED_COLOR)
  self.appliedVariant = Extensions.Config.getString(Constants.SharedDataKeys.CUSTOM_COLOR_VARIANT) or "Content"
  self.appliedContrast = tonumber(Extensions.Config.get(Constants.SharedDataKeys.CUSTOM_COLOR_CONTRAST)) or 0

  -- 待应用（pending）：选择只改这些，点「应用主题」才写回配置并重启
  self.pendingTheme = self.appliedTheme
  self.pendingSeed = self.appliedSeed
  self.pendingVariant = self.appliedVariant
  self.pendingContrast = self.appliedContrast

  self:buildThemeData()
end

function ThemePickerFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.theme_picker.main, self.views)
end

function ThemePickerFragment:initViews()
  local views = self.views

  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = { views.apply_bar },
  })

  if views.toolbar then
    Helpers.UI.setupToolbar(views.toolbar, {
      title = "主题设置",
      menu = {
        { id = "restore_default", title = "恢复默认", click = function() self:onRestoreDefault() end },
      },
    })
  end

  if views.apply_btn then
    views.apply_btn.onClick = function() self:onApply() end
  end

  self:initListView()
  self:updateApplyBar()
end

function ThemePickerFragment:buildThemeData()
  self.items = {}

  -- 主题色：预设 + 动态取色统一为大圆色块，选中加描边环
  local themeSwatches = {}
  for _, themeId in ipairs(allThemeIds) do
    themeSwatches[#themeSwatches + 1] = {
      value = themeId,
      color = getThemePrimaryColor(themeId),
      caption = themeId,
    }
  end
  if AppTheme.isDynamicColorAvailable() then
    themeSwatches[#themeSwatches + 1] = {
      value = "Dynamic",
      color = self:getDynamicPreviewColor(),
      caption = "Dynamic",
    }
  end
  table.insert(self.items, {
    type = "swatches",
    title = "主题色",
    key = "theme",
    entries = themeSwatches,
  })

  -- 预览行：反映当前 pending 选择（应用前所见即所得）
  table.insert(self.items, { type = "preview" })

  -- 种子色：大圆色块 + 输入/图片取色动作圆（走 Java 侧 Scheme 计算，不依赖动态取色门）
  local seedSwatches = {}
  for _, seed in ipairs(seedColors) do
    seedSwatches[#seedSwatches + 1] = {
      value = seed.hex,
      color = hexToColor(seed.hex),
    }
  end
  seedSwatches[#seedSwatches + 1] = { action = "input" }
  seedSwatches[#seedSwatches + 1] = { action = "image" }
  table.insert(self.items, {
    type = "swatches",
    title = "种子色",
    key = "seed",
    entries = seedSwatches,
  })

  -- 说明：配色方案/对比度基于 Scheme 计算，仅对自定义种子色生效（预设主题色不受影响）
  table.insert(self.items, { type = "note", text = "配色方案与对比度仅对自定义种子色生效" })

  -- 配色方案：9 项 chip 单选组
  table.insert(self.items, {
    type = "chips",
    title = "配色方案",
    key = "variant",
    entries = variantNames,
  })

  -- 对比度：仅 3 项，直接平铺 chip
  table.insert(self.items, {
    type = "chips",
    title = "对比度",
    key = "contrast",
    entries = contrastLevels,
  })
end

-- 动态取色色块的预览色：已处于动态模式时取当前实际 primary，否则取系统 accent 预览色
function ThemePickerFragment:getDynamicPreviewColor()
  if self.appliedTheme == "Dynamic" then
    return AppTheme.colors.primary
  end
  local colorId = resources.getIdentifier("dynamic_primary", "color", packageName)
  if colorId == 0 then return 0 end
  return resources.getColor(colorId, nil)
end

function ThemePickerFragment:initListView()
  local views = self.views
  if not views.recycler_view then return end

  self.adapter = SimpleRecyclerAdapter.new({
    items = self.items,
    getItemViewType = function(position, item)
      if item.type == "title" then return 1 end
      if item.type == "chips" or item.type == "swatches" then return 2 end
      if item.type == "preview" then return 3 end
      if item.type == "note" then return 4 end
      return 0
    end,
    onCreateView = function(viewType)
      if viewType == 1 then
        return SimpleRecyclerAdapter.inflate(Layouts.pages.theme_picker.title)
       elseif viewType == 2 then
        return SimpleRecyclerAdapter.inflate(Layouts.pages.theme_picker.chips)
       elseif viewType == 3 then
        return SimpleRecyclerAdapter.inflate(Layouts.pages.theme_picker.preview)
       elseif viewType == 4 then
        return SimpleRecyclerAdapter.inflate(Layouts.pages.theme_picker.note)
       else
        return SimpleRecyclerAdapter.inflate(Layouts.pages.theme_picker.item)
      end
    end,
    onBind = function(views, item, position, holder)
      if item.type == "title" then
        if views.title then views.title.text = item.title end
        return
      end

      if item.type == "swatches" then
        self:bindSwatches(views, item)
        return
      end

      if item.type == "chips" then
        self:bindChips(views, item)
        return
      end

      if item.type == "preview" then
        self:updatePreview(views)
        return
      end

      if item.type == "note" then
        if views.note then views.note.text = item.text end
        return
      end
    end
  })

  views.recycler_view.adapter = self.adapter
  views.recycler_view.layoutManager = SafeLinearLayoutManager(activity)
end

-- pending 改变后：刷新列表选中态与预览、切换应用栏显隐
function ThemePickerFragment:onPendingChanged()
  if self.adapter then self.adapter.notifyDataSetChanged() end
  self:updateApplyBar()
end

function ThemePickerFragment:isChanged()
  if self.pendingTheme ~= self.appliedTheme then return true end
  if self.pendingTheme == "Custom" then
    return self.pendingSeed ~= self.appliedSeed
      or self.pendingVariant ~= self.appliedVariant
      or self.pendingContrast ~= self.appliedContrast
  end
  return false
end

function ThemePickerFragment:updateApplyBar()
  if self.views.apply_bar then
    self.views.apply_bar.visibility = self:isChanged() and View.VISIBLE or View.GONE
  end
end

-- 应用：写回配置并重启生效（唯一一次 recreate）
function ThemePickerFragment:onApply()
  if not self:isChanged() then
    tip("未更改")
    return
  end
  if self.pendingTheme == "Custom" and not self.pendingSeed then
    tip("请先选择种子色")
    return
  end
  if self.pendingTheme == "Custom" then
    Extensions.Config.set(Constants.SharedDataKeys.CUSTOM_SEED_COLOR, self.pendingSeed)
    Extensions.Config.set(Constants.SharedDataKeys.CUSTOM_COLOR_VARIANT, self.pendingVariant)
    Extensions.Config.set(Constants.SharedDataKeys.CUSTOM_COLOR_CONTRAST, self.pendingContrast)
  end
  AppTheme.setThemeConfig(self.pendingTheme)
  tip("应用中，即将重启")
  Helpers.UI.runDelayed(500, self:runIfAlive(function()
    activity.recreate()
  end))
end

function ThemePickerFragment:onSeedInputClick()
  local views = {}
  local dialog = MaterialAlertDialogBuilder(activity)
  .setTitle("输入颜色值")
  .setMessage("十六进制颜色，格式 #RRGGBB")
  .setView(loadlayout({
    LinearLayoutCompat,
    orientation = "vertical",
    padding = "24dp",
    {
      AppCompatEditText,
      id = "edit",
      layout_width = "fill",
      hint = "#0066CC",
      inputType = InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS,
    }
  }, views))
  .setPositiveButton("确定", nil)
  .setNegativeButton("取消", nil)
  .show()
  local edit = views.edit
  if self.pendingSeed then edit.text = self.pendingSeed end
  dialog.getButton(dialog.BUTTON_POSITIVE).onClick = function()
    local hex = tostring(edit.text):match("^%s*(#%x%x%x%x%x%x)%s*$")
    if not hex then
      tip("格式错误，应为 #RRGGBB")
      return
    end
    dialog.dismiss()
    self:setPendingSeed(hex)
  end
end

--- SAF 选图（无权限）：launcher 在启动期经 Extensions.File.init 注册，此处仅 launch
function ThemePickerFragment:onSeedImageClick()
  Extensions.File.pickImage(self:runIfAlive(function(uri)
    if uri then self:applySeedFromImage(uri) end
  end))
end

function ThemePickerFragment:applySeedFromImage(uri)
  if not uri then return end
  task(function()
    local BitmapFactoryOptions = luajava.bindClass("android.graphics.BitmapFactory$Options")
    -- 采样解码：限制到约 112x112 像素，提取主色足够且省内存
    local opts = BitmapFactoryOptions()
    opts.inJustDecodeBounds = true
    local resolver = activity.getContentResolver()
    local stream = resolver.openInputStream(uri)
    BitmapFactory.decodeStream(stream, nil, opts)
    stream.close()

    local sample = 1
    while opts.outWidth / (sample * 2) >= 112 and opts.outHeight / (sample * 2) >= 112 do
      sample = sample * 2
    end

    local decodeOpts = BitmapFactoryOptions()
    decodeOpts.inSampleSize = sample
    stream = resolver.openInputStream(uri)
    local bitmap = BitmapFactory.decodeStream(stream, nil, decodeOpts)
    stream.close()
    if not bitmap then return nil end

    local w = bitmap.getWidth()
    local h = bitmap.getHeight()
    local pixels = luajava.newArray(int, w * h)
    bitmap.getPixels(pixels, 0, w, 0, 0, w, h)
    bitmap.recycle()

    local seed = ThemeColors.seedColorFromPixels(pixels)
    if seed == 0 then return nil end
    return string.format("#%06X", seed & 0xFFFFFF)
    end, function(hex)
    if not hex or hex == "" then
      tip("取色失败，换张图片试试")
      return
    end
    self:setPendingSeed(hex)
  end)
end

--- 选定种子色（输入/图片/色块共用）：切到自定义并刷新预览，不重启
function ThemePickerFragment:setPendingSeed(hex)
  self.pendingSeed = hex
  self.pendingTheme = "Custom"
  self:onPendingChanged()
end

--- 预览行刷新：反映 pending 选择。自定义走 Scheme 计算，预设读该主题角色色
function ThemePickerFragment:updatePreview(views)
  local colors = AppTheme.colors
  local primary, onPrimary, secondary, tertiary, surface, onSurface, onSurfaceVariant
  local prefix, hex

  if self.pendingTheme == "Custom" and self.pendingSeed then
    local ok, r = pcall(ThemeColors.previewColors, hexToColor(self.pendingSeed),
      self.pendingVariant, self.pendingContrast, AppTheme.isAppNight())
    if ok and r then
      primary, onPrimary, secondary, tertiary, surface, onSurface, onSurfaceVariant = r[0], r[1], r[2], r[3], r[4], r[5], r[6]
    end
    prefix = self.pendingVariant
    hex = self.pendingSeed
   elseif self.pendingTheme == "Dynamic" then
    primary = self:getDynamicPreviewColor()
    prefix = "Dynamic"
   elseif self.pendingTheme and self.pendingTheme ~= "Custom" then
    local c = getThemeRoleColors(self.pendingTheme)
    if c then
      primary, onPrimary, secondary, tertiary, surface, onSurface, onSurfaceVariant = c[1], c[2], c[3], c[4], c[5], c[6], c[7]
    end
    prefix = self.pendingTheme
  end

  primary = primary or colors.primary
  onPrimary = onPrimary or colors.onPrimary
  secondary = secondary or colors.secondary
  tertiary = tertiary or colors.tertiary
  surface = surface or colors.surface
  onSurface = onSurface or colors.onSurface
  onSurfaceVariant = onSurfaceVariant or colors.onSurfaceVariant
  hex = hex or string.format("#%06X", primary & 0xFFFFFF)

  if views.preview_card then views.preview_card.cardBackgroundColor = surface end
  if views.preview_title then views.preview_title.textColor = onSurface end
  if views.preview_body then views.preview_body.textColor = onSurfaceVariant end
  if views.preview_secondary then views.preview_secondary.cardBackgroundColor = secondary end
  if views.preview_tertiary then views.preview_tertiary.cardBackgroundColor = tertiary end
  if views.preview_btn then views.preview_btn.cardBackgroundColor = primary end
  if views.preview_btn_label then views.preview_btn_label.textColor = onPrimary end
  if views.preview_hex then
    views.preview_hex.text = (prefix and (prefix .. " · ") or "") .. hex
  end
end

--- 色块流绑定：色板/种子色为圆色块，输入/图片为动作圆
function ThemePickerFragment:bindSwatches(views, item)
  if views.label then views.label.text = item.title end
  local group = views.chip_group
  if not group then return end
  group.removeAllViews()
  for _, entry in ipairs(item.entries) do
    local view
    if entry.action then
      view = self:buildActionView(entry)
     else
      local selected
      if item.key == "theme" then
        selected = tostring(entry.value) == tostring(self.pendingTheme)
       else
        selected = self.pendingTheme == "Custom" and tostring(entry.value) == tostring(self.pendingSeed)
      end
      view = self:buildSwatchView(entry.color, selected, entry.caption)
      view.onClick = function()
        self:onSwatchSelect(item, tostring(entry.value))
      end
    end
    group.addView(view)
  end
end

--- 单个圆色块：34dp 实心圆 + 选中时 48dp 描边环（环落在色块与背景的间隙带，对比稳定）
function ThemePickerFragment:buildSwatchView(fillColor, selected, caption)
  local colors = AppTheme.colors
  local col = {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "wrap",
    layout_height = "wrap",
    gravity = "center_horizontal",
    {
      FrameLayout,
      layout_width = "48dp",
      layout_height = "48dp",
      {
        MaterialCardView,
        layout_width = "34dp",
        layout_height = "34dp",
        layout_gravity = "center",
        radius = "17dp",
        cardElevation = 0,
        strokeWidth = 0,
        cardBackgroundColor = fillColor or 0,
      },
      {
        MaterialCardView,
        layout_width = "48dp",
        layout_height = "48dp",
        layout_gravity = "center",
        radius = "24dp",
        cardElevation = 0,
        cardBackgroundColor = 0,
        strokeWidth = selected and dp2px(3) or 0,
        strokeColor = colors.primary,
      },
    },
  }
  if caption then
    col[#col + 1] = Helpers.Layout.text(nil, AppTextStyle.labelSmall, caption,
      { layout_marginTop = dp2px(2), gravity = "center", maxLines = 1, textColor = colors.onSurfaceVariant })
  end
  return loadlayout(col, {})
end

--- 动作圆：轮廓圆底 + 图标（输入颜色值 / 从图片取色）
function ThemePickerFragment:buildActionView(entry)
  local colors = AppTheme.colors
  local iconName = entry.action == "input" and "twotone_edit" or "twotone_image"
  local caption = entry.action == "input" and "输入" or "图片"
  local iconViews = {}
  local col = loadlayout({
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "wrap",
    layout_height = "wrap",
    gravity = "center_horizontal",
    {
      FrameLayout,
      layout_width = "48dp",
      layout_height = "48dp",
      {
        MaterialCardView,
        layout_width = "40dp",
        layout_height = "40dp",
        layout_gravity = "center",
        radius = "20dp",
        cardElevation = 0,
        strokeWidth = dp2px(1),
        strokeColor = colors.outline,
        cardBackgroundColor = colors.surfaceContainerHighest,
        {
          AppCompatImageView,
          id = "icon",
          layout_width = "22dp",
          layout_height = "22dp",
          layout_gravity = "center",
        },
      },
    },
    Helpers.Layout.text(nil, AppTextStyle.labelSmall, caption, { layout_marginTop = dp2px(2), gravity = "center", textColor = colors.onSurfaceVariant }),
  }, iconViews)
  local icon = Helpers.Static.materialDrawable(iconName, 22)
  if iconViews.icon and icon then
    iconViews.icon.setImageDrawable(icon)
    iconViews.icon.setColorFilter(colors.onSurfaceVariant)
  end
  col.onClick = function()
    if entry.action == "input" then
      self:onSeedInputClick()
     else
      self:onSeedImageClick()
    end
  end
  return col
end

--- 色块单选：主题色（含动态）设为 pending；种子色设为 pending 并切自定义
function ThemePickerFragment:onSwatchSelect(item, value)
  if item.key == "theme" then
    self.pendingTheme = value
    self:onPendingChanged()
    return
  end
  self:setPendingSeed(value)
end

--- chips 单选组绑定（配色方案 / 对比度）：每个选项一个 Chip，当前值 checked
function ThemePickerFragment:bindChips(views, item)
  if views.label then views.label.text = item.title end
  local group = views.chip_group
  if not group then return end
  group.removeAllViews()
  for _, entry in ipairs(item.entries) do
    local value = tostring(entry.value ~= nil and entry.value or entry.key)
    local label = entry.label or entry.title or value
    local chip = Chip(activity)
    chip.text = label
    chip.typeface = Fonts.regular
    chip.checkable = true
    chip.ensureMinTouchTargetSize = false
    local current = item.key == "variant" and self.pendingVariant or tostring(self.pendingContrast)
    chip.checked = (value == current)
    chip.onClick = function()
      if item.key == "variant" then
        self.pendingVariant = value
       else
        self.pendingContrast = tonumber(value) or 0
      end
      self:onPendingChanged()
    end
    group.addView(chip)
  end
end

function ThemePickerFragment:onDestroy()
  if self.adapter then
    self.adapter = nil
  end
end

--- 恢复默认：清掉自定义色相关配置、切回默认主题并重启（已是默认则不重启）
function ThemePickerFragment:onRestoreDefault()
  if self.appliedTheme == "Default"
      and self.appliedVariant == "Content"
      and self.appliedContrast == 0 then
    tip("已是默认主题")
    return
  end
  Extensions.Config.delete(Constants.SharedDataKeys.CUSTOM_SEED_COLOR)
  Extensions.Config.set(Constants.SharedDataKeys.CUSTOM_COLOR_VARIANT, "Content")
  Extensions.Config.set(Constants.SharedDataKeys.CUSTOM_COLOR_CONTRAST, 0)
  AppTheme.setThemeConfig("Default")
  tip("已恢复默认，即将重启")
  Helpers.UI.runDelayed(500, self:runIfAlive(function()
    activity.recreate()
  end))
end

return ThemePickerFragment
