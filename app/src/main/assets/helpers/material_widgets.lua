-- helpers/material_widgets.lua
-- 通过 LayoutInflater 加载布局

local M = {}

local LayoutInflater = luajava.bindClass("android.view.LayoutInflater")
local resources = activity.resources
local packageName = activity.packageName

local prefix = "material_widgets_"
-- 布局 id 在组件首次取用时才解析并缓存，模块加载期只分配闭包
local function create(suffix)
  local name = prefix .. suffix
  local id

  return function(ctx)
    if not id then
      id = resources.getIdentifier(name, "layout", packageName)
    end
    if id == 0 then
      error("布局不存在: " .. name)
    end
    return LayoutInflater.from(ctx).inflate(id, nil)
  end
end

local _import = _G["import"]
local function loadclass(classname)
  local shortname = classname:match("[^.]+$") or classname
  return _G[shortname] or (_import(classname) and _G[shortname])
end

-- AppBarLayout
M.AppBarLayout_AppBarWithSearch = create("appbarlayout_appbar_with_search")

-- BottomSheet
M.BottomSheet_Standard = create("bottomsheet_standard")

-- 定义尺寸
local sizes = {
  { Name = "ExtraSmall", File = "extra_small" },
  { Name = "Small", File = "small" },
  { Name = "Medium", File = "medium" },
  { Name = "Large", File = "large" },
  { Name = "ExtraLarge", File = "extra_large" }
}

-- Button 的形状变种
local shapes = {
  { Name = "Round", File = "round" },
  { Name = "Square", File = "square" }
}

-- IconButton 的宽窄变种
local variants = {
  { Name = "Square", File = "square" },
  { Name = "Narrow", File = "narrow" },
  { Name = "Wide", File = "wide" }
}

-- 注册一族组件的「尺寸」与「尺寸 × 第二维」两级组合，M 的 key 与布局名同步派生
local function family(key, file, second)
  for _, size in ipairs(sizes) do
    M[key .. "_" .. size.Name] = create(file .. "_" .. size.File)
    for _, item in ipairs(second) do
      M[key .. "_" .. size.Name .. "_" .. item.Name] = create(file .. "_" .. size.File .. "_" .. item.File)
    end
  end
end

-- Buttons
M.Button_Filled = loadclass("com.google.android.material.button.MaterialButton") -- def res
family("Button_Filled", "button_filled", shapes)

M.Button_Tonal = create("button_tonal")
family("Button_Tonal", "button_tonal", shapes)

M.Button_Outlined = create("button_outlined")
family("Button_Outlined", "button_outlined", shapes)

M.Button_Elevated = create("button_elevated")
family("Button_Elevated", "button_elevated", shapes)

M.Button_Text = create("button_text")
family("Button_Text", "button_text", shapes)

-- ButtonGroup
M.ButtonGroup_Connected_Expressive = create("buttongroup_connected_expressive")

-- Cards
M.Card_Elevated = create("card_elevated")
M.Card_Filled = create("card_filled")

-- Chips
M.Chip_Assist = loadclass("com.google.android.material.chip.Chip") -- def res
M.Chip_Assist_Elevated = create("chip_assist_elevated")
M.Chip_Filter = create("chip_filter")
M.Chip_Filter_Elevated = create("chip_filter_elevated")
M.Chip_Input = create("chip_input")
M.Chip_Suggestion = create("chip_suggestion")
M.Chip_Suggestion_Elevated = create("chip_suggestion_elevated")

-- CircularProgress
M.CircularProgress_ExtraSmall = create("circularprogress_extrasmall")
M.CircularProgress_Medium = create("circularprogress_medium")
M.CircularProgress_Small = create("circularprogress_small")
M.CircularProgress_Wavy = create("circularprogress_wavy")

-- CollapsingToolbar
M.CollapsingToolbar_Large = create("collapsingtoolbar_large")
M.CollapsingToolbar_Medium = create("collapsingtoolbar_medium")

-- Divider
M.Divider_Heavy = create("divider_heavy")

-- DockedToolbar
M.DockedToolbar_Vibrant = create("dockedtoolbar_vibrant")

-- ExtendedFAB
M.ExtendedFAB_Large = create("extendedfab_large")
M.ExtendedFAB_Medium = create("extendedfab_medium")
M.ExtendedFAB_Small = create("extendedfab_small")
M.ExtendedFAB_TextOnly = create("extendedfab_textonly")

-- FAB
local themeOverlays = {
  { Name = "Primary", File = "primary" },
  { Name = "Secondary", File = "secondary" },
  { Name = "Tertiary", File = "tertiary" },
  { Name = "PrimaryContainer", File = "primary_container" },
  { Name = "SecondaryContainer", File = "secondary_container" },
  { Name = "TertiaryContainer", File = "tertiary_container" }
}

-- 动态生成 Fab 及其主题变体
M.Fab = loadclass("com.google.android.material.floatingactionbutton.FloatingActionButton") -- def res
for _, overlay in ipairs(themeOverlays) do
  M["Fab_" .. overlay.Name] = create("fab_" .. overlay.File)
end

-- 动态生成 Fab_Large 及其主题颜色变体
M.Fab_Large = create("fab_large")
for _, overlay in ipairs(themeOverlays) do
  M["Fab_Large_" .. overlay.Name] = create("fab_large_" .. overlay.File)
end

-- 动态生成 Fab_Medium 及其主题颜色变体
M.Fab_Medium = create("fab_medium")
for _, overlay in ipairs(themeOverlays) do
  M["Fab_Medium_" .. overlay.Name] = create("fab_medium_" .. overlay.File)
end

-- FloatingToolbar
M.FloatingToolbar_IconButton = create("floatingtoolbar_iconbutton")
M.FloatingToolbar_IconButton_Vibrant = create("floatingtoolbar_iconbutton_vibrant")
M.FloatingToolbar_Vibrant = create("floatingtoolbar_vibrant")

-- IconButton
M.IconButton = create("iconbutton")
family("IconButton", "iconbutton", variants)

M.IconButton_Filled = create("iconbutton_filled")
family("IconButton_Filled", "iconbutton_filled", variants)

M.IconButton_Outlined = create("iconbutton_outlined")
family("IconButton_Outlined", "iconbutton_outlined", variants)

M.IconButton_Tonal = create("iconbutton_tonal")
family("IconButton_Tonal", "iconbutton_tonal", variants)

-- LinearProgress
M.LinearProgress_Wavy = create("linearprogress_wavy")

-- ListItem
M.ListItem_CardView_Segmented = create("listitem_cardview_segmented")
M.ListItem_Checkbox = create("listitem_checkbox")
M.ListItem_Radiobutton = create("listitem_radiobutton")
M.ListItem_Switch = create("listitem_switch")

-- LoadingIndicator
M.LoadingIndicator_Contained = create("loadingindicator_contained")

-- SearchBar
M.SearchBar_AppBarWithSearch = create("searchbar_appbar_with_search")

-- SideSheet
M.SideSheet_Modal = create("sidesheet_modal")
M.SideSheet_Standard = create("sidesheet_standard")

-- SplitButton
M.SplitButton_Icon_Filled = create("splitbutton_icon_filled")
M.SplitButton_Icon_Tonal = create("splitbutton_icon_tonal")
M.SplitButton_Leading_Filled = create("splitbutton_leading_filled")
M.SplitButton_Leading_Tonal = create("splitbutton_leading_tonal")

-- Tabs
M.Tabs_OnSurface = create("tabs_onsurface")
M.Tabs_Secondary = create("tabs_secondary")

-- TextField
M.TextField_Filled_Dense = create("textfield_filled_dense")
M.TextField_Filled_Dense_Dropdown = create("textfield_filled_dense_dropdown")
M.TextField_Filled_Dropdown = create("textfield_filled_dropdown")
M.TextField_Outlined_Dense_Dropdown = create("textfield_outlined_dense_dropdown")
M.TextField_Outlined_Dropdown = create("textfield_outlined_dropdown")

-- Toolbar
M.Toolbar_OnSurface = create("toolbar_onsurface")
M.Toolbar_Surface = create("toolbar_surface")

local debug = false

-- 统计组件数并过滤出class和function
if debug then
  local count = 0
  local classCount = 0
  local funcCount = 0

  for k, v in pairs(M) do
    count = count + 1
    if type(v) == "userdata" then
      classCount = classCount + 1
     elseif type(v) == "function" then
      funcCount = funcCount + 1
    end
  end

  print("Total components: " .. count)
  print("Classes: " .. classCount .. ", Functions: " .. funcCount)

  -- 完整打印M表结构
  error(dump(M))
end

return M