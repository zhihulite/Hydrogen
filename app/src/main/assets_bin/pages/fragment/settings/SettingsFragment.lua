-- pages/fragment/settings/SettingsFragment.lua
-- 设置页面 Fragment

import "androidx.recyclerview.widget.LinearLayoutManager"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"

local BaseFragment = require("pages.base.BaseFragment")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

local SettingsFragment = Extensions.Class(BaseFragment, { "SettingsFragment" })
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

-- 设置项布局引用
local LAYOUTS = {
  tab_header = Layouts.pages.settings.items.home_tab_header,
  tab_item = Layouts.pages.settings.items.home_tab_item
}

-- 弹窗布局引用
local DIALOGS = {
  search_engine = Layouts.pages.settings.dialogs.search_engine,
  block_words = Layouts.pages.settings.dialogs.block_words,
  custom_font = Layouts.pages.settings.dialogs.custom_font,
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
  { type = "title", title = "浏览设置" },
  { type = "item", title = "搜索设置", key = "search_engine", arrow = true },
  { type = "switch", title = "自动打开剪贴板链接", key = SharedDataKeys.AUTO_OPEN_CLIPBOARD },
  { type = "switch", title = "夜间模式追随系统", key = SharedDataKeys.AUTO_NIGHT_MODE },
  { type = "switch", title = "夜间模式", key = SharedDataKeys.NIGHT_MODE },
  { type = "switch", title = "OLED纯黑模式", key = SharedDataKeys.OLED_MODE },
  { type = "switch", title = "无图模式", key = SharedDataKeys.NO_IMAGE },
  { type = "switch", title = "智能无图模式", key = SharedDataKeys.SMART_NO_IMAGE },
  { type = "slider", title = "左右滑动倍数阈值", key = SharedDataKeys.SCROLL_SENSE, from = 0.5, to = 5, unit = "倍", step = 0.1 },
  { type = "slider", title = "字体大小", key = SharedDataKeys.FONT_SIZE, from = 12, to = 30, unit = "sp", step = 1 },
  { type = "slider", title = "推荐缓存数量", key = SharedDataKeys.FEED_CACHE, from = 0, to = 200, unit = "条", step = 1 },
  { type = "switch", title = "回答单页模式", key = SharedDataKeys.ANSWER_SINGLE_PAGE },
  { type = "switch", title = "关闭热门搜索", key = SharedDataKeys.CLOSE_HOT_SEARCH },
  { type = "switch", title = "代码块自动换行", key = SharedDataKeys.CODE_WRAP },
  { type = "switch", title = "切换WebView", key = SharedDataKeys.SWITCH_WEBVIEW },
  { type = "switch", title = "使用系统字体", key = SharedDataKeys.USE_SYSTEM_FONT },
  { type = "item", title = "自定义网页字体（beta）", key = "custom_web_font", arrow = true },
  { type = "item", title = "屏蔽词设置", key = "block_words", arrow = true },

  { type = "title", title = "主页设置" },
  { type = "switch", title = "热榜关闭图片", key = SharedDataKeys.HOT_CLOSE_IMAGE },
  { type = "switch", title = "热榜关闭热度", key = SharedDataKeys.HOT_CLOSE_HOTNESS },
  { type = "switch", title = "关闭推荐全站", key = SharedDataKeys.CLOSE_RECOMMEND_ALL_SECTION },
  { type = "item", title = "修改主页推荐地点Tab", key = "home_location", arrow = true },
  { type = "item", title = "关注默认选中", key = "follow_default_tab", arrow = true },
  { type = "item", title = "主页Tab排序", key = "home_layout", arrow = true },

  { type = "title", title = "缓存设置" },
  { type = "switch", title = "自动清理缓存", key = SharedDataKeys.AUTO_CLEAN_CACHE },
  { type = "item", title = "清理软件缓存", key = "clear_cache", arrow = true },

  { type = "title", title = "页面设置" },
  { type = "item", title = "主题设置", key = "theme_setting", arrow = true },
  { type = "switch", title = "平行世界", key = SharedDataKeys.PARALLEL_WORLD },
  { type = "switch", title = "预见性返回手势", key = SharedDataKeys.PREDICTIVE_BACK },
  { type = "switch", title = "简洁动画", key = SharedDataKeys.USE_SIMPLE_ANIMATION },

  { type = "title", title = "其他" },
  { type = "item", title = "关于", key = "about", arrow = true },
  { type = "item", title = "管理/android/data存储", key = "manage_storage", arrow = true },
  { type = "switch", title = "音量键切换Tab", key = SharedDataKeys.VOLUME_SWITCH_TAB },
  { type = "switch", title = "显示虚拟滑动按键", key = SharedDataKeys.SHOW_VIRTUAL_SCROLL },
  { type = "switch", title = "调试模式", key = SharedDataKeys.DEBUG_MODE },
  { type = "switch", title = "允许加载代码", key = SharedDataKeys.ALLOW_LOAD_CODE },
  { type = "switch", title = "启用内部WebView eruda调试", key = SharedDataKeys.ERUDA },
  { type = "switch", title = "自动检测更新", key = SharedDataKeys.AUTO_CHECK_UPDATE },
}

function SettingsFragment:ctor()
  self.adapter = nil
  self.items = {}
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

  Helpers.UI.setupToolbar(views.toolbar, { title = "设置" })
  self:initListView()
end

-- 边界检查函数
local function clampValue(value, minVal, maxVal)
  if value < minVal then return minVal end
  if value > maxVal then return maxVal end
  return value
end

function SettingsFragment:buildSettingsData()
  self.items = {}
  for _, config in ipairs(settingsConfig) do
    local item = { type = config.type }
    if config.type == "title" then
      item.title = config.title
     elseif config.type == "item" then
      item.title = config.title
      item.key = config.key
      item.arrow = config.arrow
     elseif config.type == "switch" then
      item.title = config.title
      item.key = config.key
      item.checked = Extensions.Config.getBool(config.key)
     elseif config.type == "slider" then
      item.title = config.title
      item.key = config.key
      item.from = config.from
      item.to = config.to
      item.unit = config.unit
      item.step = config.step
      -- 读取并限制范围
      local rawValue = Extensions.Config.getNumber(config.key)
      item.value = clampValue(rawValue, config.from, config.to)
    end
    table.insert(self.items, item)
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
        print(dump(item))
      end
      if item.title then
        views.title.text = item.title or ""
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

        views.value.text = formatValue(views.slider.value)
        views.slider.addOnChangeListener(luajava.createProxy("com.google.android.material.slider.Slider$OnChangeListener", {
          onValueChange = function(slider, value, fromUser)
            if fromUser then
              local saveValue = item.step and tonumber(string.format("%.1f", value)) or math.floor(value + 0.5)
              views.value.text = formatValue(saveValue)
              self:onSliderChanged(item.key, saveValue)
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
  views.recycler_view.layoutManager = LinearLayoutManager(activity)
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
  if key == SharedDataKeys.FONT_SIZE then
    tip("字体大小已设置为 " .. math.floor(value) .. "sp，重启生效")
   elseif key == SharedDataKeys.FEED_CACHE then
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
    custom_web_font = function() self:showCustomFontDialog() end,
    home_layout = function() self:showHomeLayoutDialog() end,
    follow_default_tab = function() self:showStartFollowDialog() end,
    home_location = function() self:showHomeLocationDialog() end,
    clear_cache = function() self:clearCache() end,
    theme_setting = function() Router.go("theme_picker") end,
    about = function() Router.go("about") end,
    manage_storage = function() self:manageStorage() end,
  }
  local handler = handlers[key]
  if handler then handler() end
end

function SettingsFragment:manageStorage()
  import "android.content.Intent"
  import "android.net.Uri"
  import "android.content.ComponentName"
  import "android.content.pm.PackageManager"

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
  local current = Extensions.Config.getString(Constants.SharedDataKeys.SEARCH_URL_TEMPLATE, "https://www.bing.com/search?q=site%3Azhihu.com%20")
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

function SettingsFragment:showHomeLayoutDialog()
  local config = Extensions.Config.getString(SharedDataKeys.HOME_TAB_ORDER)
  local enabledTabs = {}
  for tab in config:gmatch('[^,]+') do
    table.insert(enabledTabs, tab)
  end
  local HomeTab = table.remove(enabledTabs)
  local allTabs = { ["推荐"] = true, ["想法"] = true, ["热榜"] = true, ["关注"] = true }
  for _, item in ipairs(enabledTabs) do
    allTabs[item] = nil
  end

  local pageData = {}
  table.insert(pageData, { header = "当前" })
  for _, item in ipairs(enabledTabs) do
    table.insert(pageData, { title = item, isHome = (item == HomeTab) })
  end
  table.insert(pageData, { header = "其他" })
  for k in pairs(allTabs) do
    table.insert(pageData, { title = k, isHome = false })
  end

  local dialogViews = {}
  MaterialAlertDialogBuilder(activity)
  .setTitle("主页Tab排序")
  .setView(loadlayout(Layouts.pages.settings.dialogs.home_tab_order, dialogViews))
  .setPositiveButton("确定", {
    onClick = function()
      local selected, conf = nil, {}
      for _, v in ipairs(pageData) do
        if v.title then
          table.insert(conf, v.title)
          if v.isHome then selected = v.title end
         elseif v.header == "其他" then break
        end
      end
      if #conf < 2 or not selected then
        tip("需至少开启两页且选一个主页")
        return
      end
      table.insert(conf, selected)
      Extensions.Config.set(SharedDataKeys.HOME_TAB_ORDER, table.concat(conf, ","))
      tip("保存成功，下次启动生效")
    end
  })
  .setNegativeButton("取消", nil)
  .show()


  local adapter
  adapter = SimpleRecyclerAdapter.new({
    items = pageData,
    getItemViewType = function(pos, item)
      return item.header and 1 or 0
    end,
    onCreateView = function(viewType)
      if viewType == 1 then
        return SimpleRecyclerAdapter.inflate(LAYOUTS.tab_header)
       else
        return SimpleRecyclerAdapter.inflate(LAYOUTS.tab_item)
      end
    end,
    onBind = function(views, item, position, holder)
      if item.header then
        views.header.text = item.header
       else
        views.title.text = item.title
        views.radio.checked = item.isHome
        views.itemRoot.onClick = function()
          local currentPos = holder.getAdapterPosition()
          if currentPos == -1 then return end -- 无效位置

          -- 找到当前选中的项
          local currentHomeIndex = nil
          for i, v in ipairs(pageData) do
            if v.title and v.isHome then
              currentHomeIndex = i
              break
            end
          end

          -- 如果点击的就是当前选中的项，不做任何操作
          if currentHomeIndex == currentPos + 1 then return end

          -- 取消之前的选中
          if currentHomeIndex then
            pageData[currentHomeIndex].isHome = false
            adapter.notifyItemChanged(currentHomeIndex - 1)
          end

          -- 设置新的选中
          item.isHome = true
          adapter.notifyItemChanged(currentPos)
        end
      end
    end,
  })

  -- 拖拽回调
  local ItemTouchHelper = luajava.bindClass("androidx.recyclerview.widget.ItemTouchHelper")
  local dragCallback = luajava.override(ItemTouchHelper.Callback, {
    getMovementFlags = function()
      return int(ItemTouchHelper.Callback.makeMovementFlags(ItemTouchHelper.UP | ItemTouchHelper.DOWN, 0))
    end,
    canDropOver = function(_, _, current, target)
      return target.adapterPosition > 0
    end,
    onMove = function(_, _, vh, target)
      local from = vh.adapterPosition + 1
      local to = target.adapterPosition + 1
      pageData[from], pageData[to] = pageData[to], pageData[from]
      adapter.notifyItemMoved(from - 1, to - 1)
      return true
    end,
  })

  ItemTouchHelper(dragCallback).attachToRecyclerView(dialogViews.recycler)

  dialogViews.recycler.layoutManager = LinearLayoutManager(activity)
  dialogViews.recycler.adapter = adapter
end

function SettingsFragment:showStartFollowDialog()
  local tabConfigs = {
    { key = "recommend", name = "精选" },
    { key = "timeline", name = "最新" },
    { key = "pin", name = "想法" },
  }

  local currentKey = Extensions.Config.getString(SharedDataKeys.FOLLOW_DEFAULT_TAB, tabConfigs[1].name)
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


function SettingsFragment:showCustomFontDialog()
  local currentPath = Extensions.Config.getString(SharedDataKeys.CUSTOM_WEB_FONT, "")
  local views = {}

  local dialog = MaterialAlertDialogBuilder(activity)
  .setTitle("自定义网页字体")
  .setView(loadlayout(DIALOGS.custom_font, views))
  .setPositiveButton("关闭", nil)
  .show()

  local hasFont = currentPath ~= ""
  views.font_switch.checked = hasFont
  views.font_container.visibility = hasFont and View.VISIBLE or View.GONE

  views.font_switch.setOnCheckedChangeListener(luajava.createProxy("android.widget.CompoundButton$OnCheckedChangeListener", {
    onCheckedChanged = function(switchView, isChecked)
      views.font_container.visibility = isChecked and View.VISIBLE or View.GONE
      if not isChecked then
        local fontDir = Extensions.File.getAppDir("fonts")
        if Extensions.File.exists(fontDir) then
          Extensions.File.delete(fontDir)
        end
        Extensions.Config.delete(SharedDataKeys.CUSTOM_WEB_FONT)
        tip("已关闭自定义字体，重启生效")
      end
  end}))

  -- 使用 App 字体
  views.app_font_btn.onClick = function()
    local oldPath = Extensions.Config.getString(SharedDataKeys.CUSTOM_WEB_FONT, "")
    Extensions.Config.set(SharedDataKeys.CUSTOM_WEB_FONT, "appfont")
    tip("已使用软件默认字体，重启生效")
  end

  -- 选择文件
  views.choose_file_btn.onClick = function()
    Extensions.File.pickFile("font/ttf", function(uri, name)
      if uri then
        local destDir = Extensions.File.getAppDir("fonts")
        Extensions.File.mkdir(destDir)
        local destPath = destDir .. "/" .. name

        if Extensions.File.copyFromUri(uri, destPath) then
          Extensions.Config.set(SharedDataKeys.CUSTOM_WEB_FONT, destPath)
          tip("字体已选择，重启生效")
         else
          tip("保存失败")
        end
      end
    end)
  end
end

function SettingsFragment:showHomeLocationDialog()
  local headers = Headers["defaultHead"] or {}
  NetWork.get("https://api.zhihu.com/feed-root/sections/cityList", headers, function(code, content)
    if code ~= 200 then
      tip("获取城市列表失败")
      return
    end

    local data = json.decode(content)
    local infos = data.result_info
    local cities = {}
    for _, v in ipairs(infos) do
      local names = {}
      for _, city in ipairs(v.city_info_list) do
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
      if not showContent:find(city) then
        tip("不支持的城市")
        return
      end
      local postHeaders = Headers["defaultHead"] or {}
      postHeaders["content-type"] = "application/json"
      local postData = '{"city":"' .. city .. '"}'
      NetWork.post("https://api.zhihu.com/feed-root/sections/saveUserCity", postData, postHeaders, function(code)
        if code == 200 then
          tip("修改成功，重启生效")
          dialog.dismiss()
         else
          tip("修改失败")
        end
      end)
    end
  end)
end

function SettingsFragment:clearCache()
  MaterialAlertDialogBuilder(activity)
  .setTitle("清理缓存")
  .setMessage("确定清理所有缓存吗？")
  .setPositiveButton("确定", {
    onClick = function()
      local msg = Helpers.UI.clearAppCache()
      if msg then
        tip(msg)
       else
        tip("没有可清理的缓存")
      end
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