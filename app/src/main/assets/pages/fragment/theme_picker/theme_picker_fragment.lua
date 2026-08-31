-- pages/fragment/theme_picker/theme_picker_fragment.lua
-- 主题选择器 Fragment

local BaseFragment = require("pages.base.base_fragment")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
local SafeLinearLayoutManager = luajava.bindClass("com.hydrogen.SafeLinearLayoutManager")

local ThemePickerFragment = Extensions.Class(BaseFragment)

-- 所有主题 ID 列表
local allThemeIds = {
  "Default",
  "Monet",
  "Teal",
  "Orange",
  "Pink",
  "Red",
}

local resources = activity.resources
local packageName = activity.packageName

-- colorPrimary 属性 ID 惰性缓存，多主题循环内只解析一次
local colorPrimaryAttrId

-- 动态获取主题 primary 颜色
local function getThemePrimaryColor(themeId)

  -- 获取主题资源 ID
  local themeResId = resources.getIdentifier("Theme." .. themeId, "style", packageName)
  if themeResId == 0 then
    return 0
  end

  -- 获取 colorPrimary 属性 ID
  colorPrimaryAttrId = colorPrimaryAttrId or resources.getIdentifier("colorPrimary", "attr", packageName)
  if colorPrimaryAttrId == 0 then
    return 0
  end

  -- 通过主题资源 ID 获取该主题下的 colorPrimary 颜色值
  local typedArray = activity.obtainStyledAttributes(themeResId, { colorPrimaryAttrId })
  local color = typedArray.getColor(0, 0)
  typedArray.recycle()

  return color
end

function ThemePickerFragment:ctor()
  self.adapter = nil
  self.items = {}
  self.currentTheme = nil
end

function ThemePickerFragment:onCreate(params)
  self.currentTheme = Extensions.Config.getString(Constants.SharedDataKeys.THEME_SETTING)
  self:buildThemeData()
end

function ThemePickerFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.theme_picker.main, self.views)
end

function ThemePickerFragment:initViews()
  local views = self.views

  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = { views.recycler_view },
  })

  if views.toolbar then
    Helpers.UI.setupToolbar(views.toolbar, { title = "主题设置" })
  end

  self:initListView()
end

function ThemePickerFragment:buildThemeData()
  self.items = {}
  for _, themeId in ipairs(allThemeIds) do
    -- 获取主题 primary 颜色
    local primaryColor = getThemePrimaryColor(themeId)

    table.insert(self.items, {
      name = themeId,
      primary = primaryColor,
      isCurrent = (self.currentTheme == themeId),
    })
  end
end

function ThemePickerFragment:initListView()
  local views = self.views
  if not views.recycler_view then return end

  self.adapter = SimpleRecyclerAdapter.new({
    items = self.items,
    getItemViewType = function(position, item)
      return 0
    end,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.pages.theme_picker.item)
    end,
    onBind = function(views, item, position, holder)
      if views.title then
        views.title.text = item.name
      end

      if views.color_preview then
        views.color_preview.cardBackgroundColor = item.primary
      end

      if views.radio then
        views.radio.checked = item.isCurrent or false
      end

      if views.card then
        views.card.onClick = function()
          self:onThemeSelect(item)
        end
      end
    end
  })

  views.recycler_view.adapter = self.adapter
  views.recycler_view.layoutManager = SafeLinearLayoutManager(activity)
end

function ThemePickerFragment:onThemeSelect(item)
  if item.isCurrent then
    tip("已是当前主题")
    return
  end

  -- 保存主题
  AppTheme.setThemeConfig(item.name)
  self.currentTheme = item.name
  for _, it in ipairs(self.items) do
    it.isCurrent = (it == item)
  end
  if self.adapter then
    self.adapter.notifyDataSetChanged()
  end

  tip("主题已切换，重启生效，即将重启")

  -- 延迟重启，回调执行前校验页面存活
  Helpers.UI.runDelayed(1000, self:runIfAlive(function()
    activity.recreate()
  end))
end

function ThemePickerFragment:onDestroy()
  if self.adapter then
    self.adapter = nil
  end
end

return ThemePickerFragment