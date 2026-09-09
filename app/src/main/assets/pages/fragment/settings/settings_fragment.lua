-- pages/fragment/settings/settings_fragment.lua
-- 设置页面 Fragment

import "com.google.android.material.dialog.MaterialAlertDialogBuilder"
import "com.google.android.material.slider.Slider"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "android.view.View"
import "android.content.Context"
import "android.content.Intent"
import "android.content.ComponentName"
import "android.content.pm.PackageManager"
import "android.net.Uri"

local BaseFragment = require("pages.base.base_fragment")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
local HomeTabOrderDialog = require("components.dialog.home_tab_order_dialog")
local CustomWebFontDialog = require("components.dialog.custom_web_font_dialog")
local SafeLinearLayoutManager = luajava.bindClass("com.hydrogen.SafeLinearLayoutManager")
local TextWatcher = luajava.bindClass("android.text.TextWatcher")
local InputMethodManager = luajava.bindClass("android.view.inputmethod.InputMethodManager")

local SettingsFragment = Extensions.Class(BaseFragment, { "settings" })
local SharedDataKeys = Constants.SharedDataKeys

-- 直接获取主题中的 ShapeAppearanceModel
local function getShapeModelFromAttr(attrName)
  local resourceId = Helpers.Resources.app.attr[attrName]
  if resourceId and resourceId ~= 0 then
    return ShapeAppearanceModel.builder(activity, resourceId, 0).build()
  end
  return nil
end

-- 用于手动设置，默认 ListItemCardView 不够灵活。
local shapeModels = {
  top = getShapeModelFromAttr("listItemShapeAppearanceFirst"),
  middle = getShapeModelFromAttr("listItemShapeAppearanceMiddle"),
  bottom = getShapeModelFromAttr("listItemShapeAppearanceLast"),
  single = getShapeModelFromAttr("listItemShapeAppearanceSingle"),
}

-- 弹窗布局引用
local DIALOGS = {
  search_engine = Layouts.pages.settings.dialogs.search_engine,
  block_words = Layouts.pages.settings.dialogs.block_words,
  home_location = Layouts.pages.settings.dialogs.home_location,
}

local ITEM_LAYOUTS = {
  Layouts.pages.settings.items.title,
  Layouts.pages.settings.items.item_card,
  Layouts.pages.settings.items.switch_card,
  Layouts.pages.settings.items.slider_card,
}

-- 设置项配置
local settingsConfig = {
  { type = "title", title = "外观与主题" },
  { type = "item", title = "主题色", summary = "更换应用强调色", key = "theme_setting", arrow = true },
  { type = "item", title = "页面布局", summary = "字号、页边距与卡片间距，可实时预览", key = "page_layout", arrow = true },
  { type = "switch", title = "夜间模式", summary = "手动切换深色界面", key = SharedDataKeys.NIGHT_MODE },
  { type = "switch", title = "跟随系统深色模式", summary = "深浅色与系统设置保持一致", key = SharedDataKeys.AUTO_NIGHT_MODE },
  { type = "switch", title = "OLED 纯黑", summary = "深色界面下背景改为纯黑", key = SharedDataKeys.OLED_MODE },
  { type = "switch", title = "使用系统字体", summary = "关闭时使用应用自带字体", key = SharedDataKeys.USE_SYSTEM_FONT },
  { type = "item", title = "自定义网页字体", summary = "网页内使用本地 ttf 字体", key = "custom_web_font", arrow = true },

  { type = "title", title = "浏览与内容" },
  { type = "switch", title = "无图模式", summary = "列表与文章不加载网络图片", key = SharedDataKeys.NO_IMAGE },
  { type = "switch", title = "智能无图", summary = "移动网络下提醒切换无图", key = SharedDataKeys.SMART_NO_IMAGE },
  { type = "item", title = "屏蔽词", summary = "过滤含关键词的列表内容", key = "block_words", arrow = true },
  { type = "item", title = "搜索引擎", summary = "设置搜索跳转的 URL 模板", key = "search_engine", arrow = true },
  { type = "switch", title = "关闭热门搜索", summary = "搜索页不展示热门词", key = SharedDataKeys.CLOSE_HOT_SEARCH },

  { type = "title", title = "回答页" },
  { type = "switch", title = "回答单页", summary = "关闭左右滑切换，一次只看一条回答", key = SharedDataKeys.ANSWER_SINGLE_PAGE },
  { type = "switch", title = "代码块自动换行", summary = "过长时换行显示，关闭则横向滑动查看", key = SharedDataKeys.CODE_WRAP },
  { type = "slider", title = "滑动翻页灵敏度", summary = "左右滑切换回答的触发倍数", key = SharedDataKeys.SCROLL_SENSE, from = 0.5, to = 5, unit = "倍", step = 0.1 },
  { type = "switch", title = "音量键切换回答", summary = "用音量键代替左右滑", key = SharedDataKeys.VOLUME_SWITCH_TAB },
  { type = "switch", title = "悬浮滚动按钮", summary = "回答页显示上下滚动按钮", key = SharedDataKeys.SHOW_VIRTUAL_SCROLL },

  { type = "title", title = "界面与手势" },
  { type = "switch", title = "平行世界", summary = "平板双栏布局，重启生效", key = SharedDataKeys.PARALLEL_WORLD },
  { type = "switch", title = "预见性返回", summary = "返回手势中预览上一个页面", key = SharedDataKeys.PREDICTIVE_BACK },
  { type = "switch", title = "简洁动画", summary = "关闭页面共享元素转场", key = SharedDataKeys.USE_SIMPLE_ANIMATION },

  { type = "title", title = "数据与存储" },
  { type = "slider", title = "推荐去重窗口", summary = "记住已读推荐用于去重，0 为关闭", key = SharedDataKeys.FEED_CACHE, from = 0, to = 200, unit = "条", step = 1 },
  { type = "switch", title = "自动清理缓存", summary = "启动时清理过期缓存", key = SharedDataKeys.AUTO_CLEAN_CACHE },
  { type = "item", title = "清理缓存", summary = "立即清除缓存文件", key = "clear_cache", arrow = true },
  { type = "item", title = "管理应用存储", summary = "用系统文件管理器打开数据目录", key = "manage_storage", arrow = true },
  { type = "switch", title = "自动打开剪贴板链接", summary = "检测到知乎链接时询问是否打开", key = SharedDataKeys.AUTO_OPEN_CLIPBOARD },

  { type = "title", title = "主页" },
  { type = "switch", title = "热榜不显示封面", summary = "热榜条目只保留文字", key = SharedDataKeys.HOT_CLOSE_IMAGE },
  { type = "switch", title = "热榜不显示热度", summary = "隐藏热榜的热度数值", key = SharedDataKeys.HOT_CLOSE_HOTNESS },
  { type = "switch", title = "隐藏推荐「全站」", summary = "推荐流去掉全站分区", key = SharedDataKeys.CLOSE_RECOMMEND_ALL_SECTION },
  { type = "item", title = "推荐地点", summary = "修改推荐流对应的城市", key = "home_location", arrow = true },
  { type = "item", title = "关注默认栏", summary = "打开关注时默认精选、最新或想法", key = "follow_default_tab", arrow = true },
  { type = "item", title = "主页栏目顺序", summary = "调整主页顶部栏目的排列", key = "home_layout", arrow = true },

  { type = "title", title = "开发者" },
  { type = "switch", title = "调试模式", summary = "输出额外日志，重启生效", key = SharedDataKeys.DEBUG_MODE },
  { type = "switch", title = "允许加载代码", summary = "页面菜单里显示执行代码入口", key = SharedDataKeys.ALLOW_LOAD_CODE },
  { type = "switch", title = "Eruda 调试", summary = "网页内嵌控制台", key = SharedDataKeys.ERUDA },
  { type = "switch", title = "切换 WebView", summary = "改用谷歌浏览器内核，兼容旧设备", key = SharedDataKeys.SWITCH_WEBVIEW },

  { type = "title", title = "关于" },
  { type = "item", title = "关于", summary = "版本、开源许可与反馈", key = "about", arrow = true },
  { type = "switch", title = "自动检测更新", summary = "启动时检查新版本", key = SharedDataKeys.AUTO_CHECK_UPDATE },
}

function SettingsFragment:ctor()
  self.adapter = nil
  -- 适配器闭包持有 self.items 的引用，过滤时原地更新这张表
  self.items = {}
  -- 全量配置数据，过滤在它的副本上进行
  self.allItems = {}
end

function SettingsFragment:onCreate(params)
  self:buildSettingsData()
end

function SettingsFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.settings.main, self.views)
end

function SettingsFragment:initViews()
  local views = self.views
  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = { views.recycler_view },
  })

  Helpers.UI.setupToolbar(views.toolbar, {
    title = "设置",
    menu = {
      {
        id = "search_settings",
        title = "搜索",
        icon = Helpers.Static.materialDrawable("twotone_search", 24),
        asAction = "always",
        click = function() self:toggleSearchRow() end,
      },
    },
  })

  if views.search_input then
    views.search_input.addTextChangedListener(luajava.createProxy(TextWatcher, {
      beforeTextChanged = function() end,
      onTextChanged = function() end,
      afterTextChanged = function(s)
        self:applySearchFilter(tostring(s))
      end,
    }))
  end
  if views.search_clear_btn then
    views.search_clear_btn.onClick = function()
      if views.search_input then views.search_input.text = "" end
    end
  end

  self:initListView()
end

-- 边界检查函数
local function clampValue(value, minVal, maxVal)
  if value < minVal then return minVal end
  if value > maxVal then return maxVal end
  return value
end

--- 条目是否命中关键词：标题与副标题都参与匹配
--- @param item table 设置项
--- @param keyword string 已转小写的关键词
--- @return boolean
local function itemMatches(item, keyword)
  if item.title and item.title:lower():find(keyword, 1, true) then return true end
  if item.summary and item.summary:lower():find(keyword, 1, true) then return true end
  return false
end

-- 搜索过滤：条目按标题与副标题匹配；分组标题命中时整组保留，
-- 否则仅保留命中的条目及其所属分组标题
local function filterSettings(all, keyword)
  local result = {}
  local i = 1
  while i <= #all do
    if all[i].type == "title" then
      local j = i + 1
      while j <= #all and all[j].type ~= "title" do
        j = j + 1
      end
      local titleHit = all[i].title:lower():find(keyword, 1, true) ~= nil
      local anyHit = titleHit
      if not anyHit then
        for k = i + 1, j - 1 do
          if itemMatches(all[k], keyword) then
            anyHit = true
            break
          end
        end
      end
      if anyHit then
        result[#result + 1] = all[i]
        for k = i + 1, j - 1 do
          local hit = titleHit or itemMatches(all[k], keyword)
          if hit then
            result[#result + 1] = all[k]
          end
        end
      end
      i = j
     else
      i = i + 1
    end
  end
  return result
end

function SettingsFragment:buildSettingsData()
  local list = {}
  for _, config in ipairs(settingsConfig) do
    local item = { type = config.type }
    if config.type == "title" then
      item.title = config.title
     elseif config.type == "item" then
      item.title = config.title
      item.summary = config.summary
      item.key = config.key
      item.arrow = config.arrow
      -- 主题色条目动态显示当前主题；主题切换 recreate 后随重建刷新
      if config.key == Constants.SharedDataKeys.THEME_SETTING then
        item.summary = "当前：" .. AppTheme.getThemeDisplayName()
      end
     elseif config.type == "switch" then
      item.title = config.title
      item.summary = config.summary
      item.key = config.key
      item.checked = Extensions.Config.getBool(config.key)
     elseif config.type == "slider" then
      item.title = config.title
      item.summary = config.summary
      item.key = config.key
      item.from = config.from
      item.to = config.to
      item.unit = config.unit
      item.step = config.step
      -- 读取并限制范围
      local rawValue = Extensions.Config.getNumber(config.key)
      item.value = clampValue(rawValue, config.from, config.to)
    end
    table.insert(list, item)
  end
  self.allItems = list
  self:showItems(list)
end

--- 原地更新适配器持有的 items 表并刷新
--- @param list table 要展示的条目列表
function SettingsFragment:showItems(list)
  for i = #self.items, 1, -1 do
    self.items[i] = nil
  end
  for _, it in ipairs(list) do
    self.items[#self.items + 1] = it
  end
  if self.adapter then
    self.adapter.notifyDataSetChanged()
  end
end

--- 按关键词过滤设置项，空关键词恢复全量
--- @param keyword string|nil 搜索框文本
function SettingsFragment:applySearchFilter(keyword)
  keyword = tostring(keyword or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
  if keyword == "" then
    self:showItems(self.allItems)
   else
    self:showItems(filterSettings(self.allItems, keyword))
  end
end

--- 切换搜索行显隐：展开时聚焦弹键盘，收起时清空并恢复全量
function SettingsFragment:toggleSearchRow()
  local views = self.views
  if not views.search_container then return end
  if views.search_container.visibility == View.VISIBLE then
    views.search_container.visibility = View.GONE
    if views.search_input then views.search_input.text = "" end
   else
    views.search_container.visibility = View.VISIBLE
    if views.search_input then
      views.search_input.requestFocus()
      Helpers.UI.runDelayed(100, self:runIfAlive(function()
        local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
        imm.toggleSoftInput(InputMethodManager.SHOW_IMPLICIT, InputMethodManager.HIDE_NOT_ALWAYS)
      end))
    end
  end
end

function SettingsFragment:initListView()
  local views = self.views
  if not views.recycler_view then return end

  self.adapter = SimpleRecyclerAdapter.new({
    items = self.items,
    getItemViewType = function(position, item)
      if item.type == "title" then return 0
       elseif item.type == "item" then return 1
       elseif item.type == "switch" then return 2
       elseif item.type == "slider" then return 3
      end
      return 1
    end,
    onCreateView = function(viewType)
      return SimpleRecyclerAdapter.inflate(ITEM_LAYOUTS[viewType + 1])
    end,
    onBind = function(views, item, position, holder)
      if not views then
        print(table.dump(item))
      end
      if item.title then
        views.title.text = item.title or ""
      end

      -- 副标题：卡片布局里默认 GONE，有值时填充并显示
      if views.summary then
        if item.summary then
          views.summary.text = item.summary
          views.summary.visibility = View.VISIBLE
         else
          views.summary.visibility = View.GONE
        end
      end

      local card = views.card
      if card then
        local prevItem = self.items[position]
        local nextItem = self.items[position + 2]
        local isTitlePrev = prevItem and prevItem.type == "title"
        local isTitleNext = nextItem and nextItem.type == "title"
        local isLast = (position + 2) > #self.items -- 判断是否是最后一项

        if isTitlePrev and isTitleNext then
          card.shapeAppearanceModel = shapeModels.single
         elseif isTitlePrev then
          card.shapeAppearanceModel = shapeModels.top
         elseif isTitleNext then
          card.shapeAppearanceModel = shapeModels.bottom
         elseif isLast then
          card.shapeAppearanceModel = shapeModels.bottom -- 最后一项用底部圆角
         else
          card.shapeAppearanceModel = shapeModels.middle
        end
      end

      if item.type == "item" then
        views.arrow.visibility = item.arrow and View.VISIBLE or View.GONE
      end

      if item.type == "switch" then
        views.switch_btn.checked = item.checked or false
      end

      if item.type == "slider" then
        views.slider.clearOnChangeListeners()
        views.slider.clearOnSliderTouchListeners()
        views.slider.valueFrom = item.from
        views.slider.valueTo = item.to
        views.slider.value = item.value or item.from
        if item.step then views.slider.stepSize = item.step end

        local function formatValue(val)
          if item.step then
            return string.format("%.1f", val):gsub("%.0$", "") .. (item.unit or "")
           else
            return string.format("%.0f", val) .. (item.unit or "")
          end
        end

        -- 拖动中只刷 UI，抬手时才写配置与提示
        local dragging = false
        local pendingValue = nil

        views.value.text = formatValue(views.slider.value)
        views.slider.addOnChangeListener(luajava.createProxy(Slider.OnChangeListener, {
          onValueChange = function(slider, value, fromUser)
            if fromUser then
              local saveValue = item.step and tonumber(string.format("%.1f", value)) or math.floor(value + 0.5)
              item.value = saveValue
              views.value.text = formatValue(saveValue)
              if dragging then
                pendingValue = saveValue
               else
                -- 无障碍与按键改值不走触摸回调，当场写入
                self:onSliderChanged(item.key, saveValue)
              end
            end
          end
        }))
        views.slider.addOnSliderTouchListener(luajava.createProxy(Slider.OnSliderTouchListener, {
          onStartTrackingTouch = function()
            dragging = true
            pendingValue = nil
          end,
          onStopTrackingTouch = function()
            dragging = false
            if pendingValue then
              self:onSliderChanged(item.key, pendingValue)
              pendingValue = nil
            end
          end
        }))
      end

      if card then
        card.onClick = function()
          if item.type == "item" then
            self:onItemClick(item.key)
           elseif item.type == "switch" then
            local newState = not views.switch_btn.isChecked()
            views.switch_btn.checked = newState
            self:onSwitchChanged(item.key, newState)
          end
        end
      end
    end
  })

  views.recycler_view.adapter = self.adapter
  views.recycler_view.layoutManager = SafeLinearLayoutManager(activity)
end

-- 更新 items 中的开关状态（单个）
function SettingsFragment:updateItemChecked(key, value)
  self:updateMultipleItems({ [key] = value })
end

-- 批量更新多个开关项的 UI 状态
function SettingsFragment:updateMultipleItems(updates)
  if not self.adapter then return end

  for key, value in pairs(updates) do
    for i, item in ipairs(self.items) do
      if item.key == key then
        item.checked = value
        self.adapter.notifyItemChanged(i - 1)
        break
      end
    end
  end
end

function SettingsFragment:onSwitchChanged(key, value)
  -- 互斥逻辑：夜间模式和自动跟随系统互斥
  if key == SharedDataKeys.NIGHT_MODE then
    if value and Extensions.Config.getBool(SharedDataKeys.AUTO_NIGHT_MODE) then
      Extensions.Config.set(SharedDataKeys.AUTO_NIGHT_MODE, false)
      self:updateMultipleItems({ [SharedDataKeys.AUTO_NIGHT_MODE] = false })
      tip("已自动关闭「自动跟随系统」")
    end
    Extensions.Config.set(key, value)
    self:updateItemChecked(key, value)
    Helpers.BottomDialog.confirm("更改夜间模式可能需要重启才能完全生效，是否立即应用？", function()
      AppTheme.applyNightMode()
    end)
   elseif key == SharedDataKeys.AUTO_NIGHT_MODE then
    if value and Extensions.Config.getBool(SharedDataKeys.NIGHT_MODE) then
      Extensions.Config.set(SharedDataKeys.NIGHT_MODE, false)
      self:updateMultipleItems({ [SharedDataKeys.NIGHT_MODE] = false })
      tip("已自动关闭「夜间模式」")
    end
    Extensions.Config.set(key, value)
    self:updateItemChecked(key, value)
    Helpers.BottomDialog.confirm("更改自动夜间模式可能需要重启才能完全生效，是否立即应用？", function()
      AppTheme.applyNightMode()
    end)
   elseif key == SharedDataKeys.OLED_MODE then
    Extensions.Config.set(SharedDataKeys.OLED_MODE, value)
    self:updateItemChecked(key, value)
    if value then
      tip("OLED纯黑模式仅在夜间模式下生效，如若无效果请先开启夜间模式。")
    end
    Helpers.BottomDialog.confirm("更改OLED模式需要重启应用才能完全生效，是否立即重启？", function()
      activity.recreate()
    end)

   elseif key == SharedDataKeys.SWITCH_WEBVIEW then
    if value then
      local pkg = "com.android.chrome"
      local pm = activity.packageManager
      local installed = pcall(function() return pm.getPackageInfo(pkg, 0) end)
      if not installed then
        Extensions.Config.set(key, false)
        self:updateItemChecked(key, false)
        tip("请先安装谷歌浏览器")
        return
      end
      MaterialAlertDialogBuilder(activity)
      .setTitle("提示")
      .setMessage("切换后将使用谷歌浏览器WebView，请手动下载\n该功能仅提供给无法升级WebView使用")
      .setPositiveButton("我知道了", nil)
      .setCancelable(false)
      .show()
      tip("重启App后生效")
      Extensions.Config.set(key, value)
      self:updateItemChecked(key, value)
     else
      Extensions.Config.set(key, false)
      self:updateItemChecked(key, false)
    end

   else
    Extensions.Config.set(key, value)
    self:updateItemChecked(key, value)
    -- 其他 tip 提示
    if key == SharedDataKeys.PARALLEL_WORLD then
      tip(value and "平行世界已开启，重启生效" or "平行世界已关闭，重启生效")
     elseif key == SharedDataKeys.PREDICTIVE_BACK then
      tip(value and "预测性返回已开启，重启生效" or "预测性返回已关闭，重启生效")
     elseif key == SharedDataKeys.DEBUG_MODE then
      tip(value and "调试模式已开启，重启生效" or "调试模式已关闭，重启生效")
     elseif key == SharedDataKeys.NO_IMAGE then
      tip(value and "无图模式已开启，下次刷新生效" or "无图模式已关闭，下次刷新生效")
     elseif key == SharedDataKeys.AUTO_OPEN_CLIPBOARD then
      tip(value and "自动打开剪贴板链接已开启，重启生效" or "自动打开剪贴板链接已关闭，重启生效")
    end
  end
end

function SettingsFragment:onSliderChanged(key, value)
  Extensions.Config.set(key, value)
  if key == SharedDataKeys.FEED_CACHE then
    if not self.cacheTipShown then
      self.cacheTipShown = true
      Extensions.Config.set(SharedDataKeys.FEED_CACHE_TIP, false)
      MaterialAlertDialogBuilder(activity)
      .setTitle("提示")
      .setMessage("是否开启重复内容去重提示？本提示仅在每次进入设置页时显示一次")
      .setCancelable(false)
      .setPositiveButton("保持关闭", nil)
      .setNeutralButton("开启", {
        onClick = function()
          Extensions.Config.set(SharedDataKeys.FEED_CACHE_TIP, true)
          tip("已开启")
        end
      })
      .show()
    end
    tip("设置为0即关闭缓存推荐以实现去重，知乎仅对重度使用用户推荐流添加重复数据\nEMMC设备推荐关闭该选项以使加载更流畅")
   elseif key == SharedDataKeys.SCROLL_SENSE then
    tip("左右滑动倍数阈值已设置为 " .. string.format("%.1f", value) .. " 倍")
  end
end

function SettingsFragment:onItemClick(key)
  local handlers = {
    search_engine = function() self:showSearchEngineDialog() end,
    block_words = function() self:showBlockWordsDialog() end,
    custom_web_font = function() CustomWebFontDialog.show() end,
    home_layout = function() HomeTabOrderDialog.show() end,
    follow_default_tab = function() self:showStartFollowDialog() end,
    home_location = function() self:showHomeLocationDialog() end,
    clear_cache = function() self:clearCache() end,
    theme_setting = function() Router.go("theme_picker") end,
    page_layout = function() Router.go("page_layout") end,
    about = function() Router.go("about") end,
    manage_storage = function() self:manageStorage() end,
  }
  local handler = handlers[key]
  if handler then handler() end
end

function SettingsFragment:manageStorage()
  local resolveIntent = Intent(Intent.ACTION_GET_CONTENT)
  resolveIntent.type = "text/plain"
  resolveIntent.addCategory(Intent.CATEGORY_OPENABLE)
  local info = activity.packageManager.resolveActivity(resolveIntent, PackageManager.MATCH_DEFAULT_ONLY)

  if not info or not info.activityInfo then
    tip("无法找到系统文件管理器，请手动管理存储空间")
    return
  end

  local packageName = info.activityInfo.packageName
  local targetIntent = Intent()
  targetIntent.type = "*/*"
  local uri = Uri.parse("content://com.android.externalstorage.documents/document/primary%3AAndroid%2Fdata%2F" .. activity.packageName .. "%2Ffiles")
  targetIntent.data = uri
  targetIntent.action = Intent.ACTION_VIEW
  local componentName = ComponentName(packageName, "com.android.documentsui.files.FilesActivity")
  targetIntent.component = componentName

  local success, err = pcall(function() activity.startActivity(targetIntent) end)
  if success then
    tip("已跳转，请自行管理")
   else
    tip("启动失败：" .. tostring(err))
  end
end

function SettingsFragment:showSearchEngineDialog()
  local current = Extensions.Config.getString(Constants.SharedDataKeys.SEARCH_URL_TEMPLATE)
  local views = {}
  MaterialAlertDialogBuilder(activity)
  .setTitle("设置搜索引擎")
  .setView(loadlayout(DIALOGS.search_engine, views))
  .setPositiveButton("确定", {
    onClick = function()
      local editText = views.edit
      if not editText then return end
      local url = editText.text
      if url:gsub(" ", "") == "" then
        tip("请输入搜索引擎地址")
        return
      end
      Extensions.Config.set(Constants.SharedDataKeys.SEARCH_URL_TEMPLATE, url)
      tip("设置成功")
    end
  })
  .setNegativeButton("取消", nil)
  .show()
  views.edit.text = current
end

function SettingsFragment:showBlockWordsDialog()
  local current = Extensions.Config.getString(SharedDataKeys.BLOCK_WORDS)
  local views = {}
  MaterialAlertDialogBuilder(activity)
  .setTitle("屏蔽词设置")
  .setView(loadlayout(DIALOGS.block_words, views))
  .setPositiveButton("保存", {
    onClick = function()
      local text = views.edit.text
      Extensions.Config.set(SharedDataKeys.BLOCK_WORDS, text)
      tip("已保存")
    end
  })
  .setNegativeButton("取消", nil)
  .show()
  views.edit.text = current or ""
end

function SettingsFragment:showStartFollowDialog()
  local tabConfigs = {
    { key = "recommend", name = "精选" },
    { key = "timeline", name = "最新" },
    { key = "pin", name = "想法" },
  }

  local currentKey = Extensions.Config.getString(SharedDataKeys.FOLLOW_DEFAULT_TAB, tabConfigs[1].key)
  local selected = 0
  for i, tab in ipairs(tabConfigs) do
    if tab.key == currentKey then
      selected = i - 1
      break
    end
  end

  local names = {}
  for _, tab in ipairs(tabConfigs) do
    table.insert(names, tab.name)
  end

  MaterialAlertDialogBuilder(activity)
  .setTitle("关注默认选中")
  .setSingleChoiceItems(names, selected, { onClick = function(dialog, which) selected = which end })
  .setPositiveButton("确定", {
    onClick = function()
      local selectedKey = tabConfigs[selected + 1].key
      Extensions.Config.set(SharedDataKeys.FOLLOW_DEFAULT_TAB, selectedKey)
      tip("已设置，重启生效")
    end
  })
  .setNegativeButton("取消", nil)
  .show()
end

function SettingsFragment:showHomeLocationDialog()
  local headers = Headers["defaultHead"] or {}
  NetWork.get("https://api.zhihu.com/feed-root/sections/cityList", headers, self:runIfAlive(function(code, content)
    if code ~= 200 then
      tip("获取城市列表失败")
      return
    end

    local ok, data = pcall(json.decode, content)
    local infos = ok and type(data) == "table" and data.result_info
    if not infos then
      tip("城市列表解析失败")
      return
    end
    local cities = {}
    for _, v in ipairs(infos) do
      local names = {}
      for _, city in ipairs(v.city_info_list or {}) do
        table.insert(names, city.city_name)
      end
      table.insert(cities, v.city_key .. "\n" .. table.concat(names, " "))
    end
    local showContent = table.concat(cities, "\n\n")
    local views = {}

    local dialog = MaterialAlertDialogBuilder(activity)
    .setTitle("修改城市")
    .setView(loadlayout(DIALOGS.home_location, views))
    .setPositiveButton("确定", nil)
    .setNegativeButton("取消", nil)
    .show()

    views.city_list.text = showContent

    local edit = views.edit
    dialog.getButton(dialog.BUTTON_POSITIVE).onClick = function()
      local city = edit.text:gsub("%s+", "")
      if city == "" then
        tip("请输入城市名")
        return
      end
      if not showContent:find(city, 1, true) then
        tip("不支持的城市")
        return
      end
      local postData = '{"city":"' .. city .. '"}'
      NetWork.post("https://api.zhihu.com/feed-root/sections/saveUserCity", postData, Headers.post, function(code)
        if code == 200 then
          tip("修改成功，重启生效")
          dialog.dismiss()
         else
          tip("修改失败")
        end
      end)
    end
  end))
end

function SettingsFragment:clearCache()
  MaterialAlertDialogBuilder(activity)
  .setTitle("清理缓存")
  .setMessage("确定清理所有缓存吗？")
  .setPositiveButton("确定", {
    onClick = function()
      Helpers.UI.clearAppCache()
    end
  })
  .setNegativeButton("取消", nil)
  .show()
end

function SettingsFragment:onDestroy()
  if self.adapter then
    self.adapter = nil
  end
end

return SettingsFragment
