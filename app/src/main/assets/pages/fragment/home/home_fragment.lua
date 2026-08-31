-- pages/fragment/home/home_fragment.lua

import "android.view.Gravity"
import "androidx.core.view.ViewCompat"
import "android.view.GestureDetector"
import "androidx.viewpager.widget.ViewPager"
import "java.lang.Runnable"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

local LuaPagerAdapter = luajava.bindClass("org.luajvm.android.widget.LuaPagerAdapter")
local FrameLayout = luajava.bindClass("android.widget.FrameLayout")
local LayoutParams = luajava.bindClass("android.view.ViewGroup$LayoutParams")
local Objects = luajava.bindClass("java.util.Objects")

local BaseFragment = require("pages.base.base_fragment")
local RecommendModel = require("models.feed.recommend_model")
local ThinkModel = require("models.feed.think_model")
local HotModel = require("models.feed.hot_model")
local FollowModel = require("models.feed.follow_model")
local DailyModel = require("models.feed.daily_model")
local CollectionTabModel = require("models.collection.collection_tab_model")
local FollowContentModel = require("models.feed.follow_content_model")
local UserModel = require("models.user.user_model")

local HomeFragment = Extensions.Class(BaseFragment, {"home"})

local homeTabs = {
  { name = "推荐", modelClass = RecommendModel, needLogin = false, icon = "twotone_home" },
  { name = "想法", modelClass = ThinkModel, needLogin = false, icon = "twotone_bubble_chart" },
  { name = "热榜", modelClass = HotModel, needLogin = false, icon = "twotone_fire" },
  { name = "关注", modelClass = FollowModel, needLogin = true, icon = "twotone_group" },
}

local drawerPages = {
  { name = "主页", type = "home", modelKey = "home", icon = "twotone_home", needLogin = false },
  { name = "收藏", type = "collections", modelKey = "collections", icon = "twotone_book", needLogin = true },
  { name = "日报", type = "daily", modelKey = "daily", icon = "twotone_work", needLogin = false },
  { name = "关注", type = "follow_content", modelKey = "follow_content", icon = "twotone_list_alt", needLogin = true },
  { name = "通知", type = "notification", icon = "twotone_notifications", needLogin = true, isSpecial = true },
  { name = "更多", type = "more", icon = "twotone_menu", needLogin = true, isSpecial = true },
  { name = "本地", type = "offline", icon = "twotone_inbox", needLogin = false, isSpecial = true },
  { name = "历史", type = "history", icon = "twotone_history", needLogin = false, isSpecial = true },
  { name = "设置", type = "settings", icon = "twotone_settings", needLogin = false, isSpecial = true },
}

function HomeFragment:ctor()
  self.homeConfig = { items = {}, startItem = nil }
  self.pageModels = {}
  self.pageViews = {}
  self.homeTabStates = {}
  self.homePagerAdapter = nil
  self.displayTabs = {}
  self.homePageViews = nil
  self.currentPage = nil
  self.drawerHeader = nil
  self.lastLoginState = nil
  self.loginReady = false
end

function HomeFragment:onCreate(params)
  self:initConfig()
end

function HomeFragment:onResume()
  local currentUserId = Extensions.Config.get(Constants.SharedDataKeys.USER_ID)
  -- 首次加载或登录状态改变时才重新加载
  if self.lastLoginState ~= currentUserId then
    self.lastLoginState = currentUserId
    self:loadUserInfo()
  end
end

function HomeFragment:onDestroy()
  for _, model in ipairs(self:getAllModels()) do
    model:destroy()
  end
  self.pageModels = {}
end

function HomeFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.home.main, self.views)
end

--- 获取当前显示的 Model（主页内 Tab 或侧边栏页面）
--- @return table|nil
function HomeFragment:_getCurrentModel()
  if self.currentPage == "主页" and self.homePageViews then
    local homeModels = self.pageModels.home
    if homeModels then
      local viewPager = self.homePageViews.view_pager
      if viewPager then
        local pos = viewPager.currentItem
        local tab = self.displayTabs[pos + 1]
        if tab then
          return homeModels[tab.name]
        end
      end
    end
   else
    for _, item in ipairs(drawerPages) do
      if item.name == self.currentPage and item.modelKey then
        return self.pageModels[item.modelKey]
      end
    end
  end
  return nil
end

--- 双击标题栏，滚动当前页面到顶部
function HomeFragment:_scrollCurrentPageToTop()
  local model = self:_getCurrentModel()
  if model and model.getCurrentRecyclerView then
    local rv = model:getCurrentRecyclerView()
    if rv then
      rv.smoothScrollToPosition(0)
    end
  end
end

function HomeFragment:initViews()
  -- 冷启动只创建当前可见的主页；收藏、日报、关注等抽屉页首次打开时再创建。
  self:initAllPages()
  self:initDrawer()
  self:switchToPage("主页")

  local views = self.views

  -- 移除 BottomNavigationView 默认的窗口 insets 适配
  -- 原因：BasePage 已统一处理左右刘海适配，此控件自动叠加会导致双重 padding
  local bottomNav = self.homePageViews.bottom_nav
  ViewCompat.setOnApplyWindowInsetsListener(bottomNav, nil)

  -- 使用 EdgeToEdge
  -- 各 Model 的 RecyclerView 已由 registerModelBottomViews 在创建时注册进 EdgeToEdgeUtils，
  -- 此处只需注册底部导航栏
  self:setupEdgeToEdge({
    top = { views.main_container, views.nav_view },
    bottom = { bottomNav }
  })

  -- 双击标题栏返回顶部
  local detector = GestureDetector(activity, {
    onDown = function(e) return true end
  })
  detector.onDoubleTap = function(e)
    self:_scrollCurrentPageToTop()
    return true
  end
  views.toolbar.onTouch = function(v, event)
    return detector.onTouchEvent(event)
  end
end

local function findDrawerPage(pageName)
  for _, item in ipairs(drawerPages) do
    if item.name == pageName then return item end
  end
  return nil
end

function HomeFragment:registerModelBottomViews(model)
  if not model or not model.getAllRecyclerViews then return end
  for _, rv in ipairs(self:collectModelBottomViews(model)) do
    self:addEdgeToEdgeView(rv, "bottom")
  end
  if ViewCompat then
    ViewCompat.requestApplyInsets(activity.window.decorView)
  end
end

function HomeFragment:initConfig()
  local cof = Extensions.Config.getString(Constants.SharedDataKeys.HOME_TAB_ORDER)
  local items = {}
  for item in cof:gmatch('[^,]+') do
    table.insert(items, item)
  end
  self.homeConfig.startItem = table.remove(items)
  self.homeConfig.items = items

  for _, tabName in ipairs(items) do
    for _, tab in ipairs(homeTabs) do
      if tab.name == tabName then
        table.insert(self.displayTabs, tab)
        break
      end
    end
  end

end

function HomeFragment:initAllPages()
  self:ensurePageInitialized("主页")
end

function HomeFragment:ensurePageInitialized(pageName)
  local existing = self.pageViews[pageName]
  if existing then return existing end

  local pageInfo = findDrawerPage(pageName)
  if not pageInfo or pageInfo.isSpecial then return nil end

  local pageContainer = self.views.page_container
  local pageView, views = self:createPageView(pageInfo.type)
  if not pageView then return nil end

  local page = { view = pageView, views = views, type = pageInfo.type }
  self.pageViews[pageInfo.name] = page
  pageContainer.addView(pageView)
  pageView.visibility = View.GONE

  if pageInfo.type == "home" then
    self.homePageViews = views
    self:initHomePage(views)
   else
    self:initPageWithModel(pageInfo.type, views)
    if pageInfo.modelKey then
      self:registerModelBottomViews(self.pageModels[pageInfo.modelKey])
    end
  end

  return page
end

function HomeFragment:createPageView(pageType)
  local layoutMap = {
    home = Layouts.pages.home.page_home,
    collections = Layouts.pages.home.page_collections,
    daily = Layouts.pages.home.page_daily,
    follow_content = Layouts.pages.home.page_follow,
  }
  local layoutPath = layoutMap[pageType]
  if not layoutPath then return nil, nil end
  local views = {}
  return loadlayout(layoutPath, views), views
end

function HomeFragment:getAllModels()
  local allModels = {}
  for key, model in pairs(self.pageModels) do
    if key == "home" then
      for _, subModel in pairs(model) do
        table.insert(allModels, subModel)
      end
     else
      table.insert(allModels, model)
    end
  end
  return allModels
end

function HomeFragment:initHomePage(views)
  if not views then return end
  local viewPager = views.view_pager
  local bottomNav = views.bottom_nav

  if not viewPager or not bottomNav then return end

  local displayTabs = self.displayTabs
  local adapter = LuaPagerAdapter()
  self.homePagerAdapter = adapter
  self.pageModels.home = {}
  self.homeTabStates = {}

  local loggedIn = Extensions.Config.has(Constants.SharedDataKeys.USER_ID)
  local startIndex
  for i, tab in ipairs(displayTabs) do
    if tab.name == self.homeConfig.startItem and (not tab.needLogin or loggedIn) then
      startIndex = i - 1
      break
    end
  end
  -- 起始项需要登录却未登录时，落回第一个无需登录的 Tab，避免冷启动就创建需要登录的 Model
  if not startIndex then
    for i, tab in ipairs(displayTabs) do
      if not tab.needLogin then startIndex = i - 1 break end
    end
  end
  startIndex = startIndex or 0

  for i, tab in ipairs(displayTabs) do
    local placeholder = FrameLayout(activity)
    placeholder.layoutParams = LayoutParams(-1, -1)
    adapter.add(placeholder)
    self.homeTabStates[i] = {
      tab = tab,
      placeholder = placeholder,
      initialized = false,
    }
  end

  viewPager.adapter = adapter
  viewPager.offscreenPageLimit = 1

  local menu = bottomNav.menu
  menu.clear()
  local config = {}
  for i, tab in ipairs(displayTabs) do
    table.insert(config, { id = "tab_" .. i, title = tab.name, icon = Helpers.Static.materialDrawable(tab.icon, 24), order = i, checkable = true })
  end
  local bottomNavItems = loadmenu(menu, config)

  bottomNav.setOnNavigationItemSelectedListener({
    onNavigationItemSelected = function(item)
      for i = 1, #displayTabs do
        if item == bottomNavItems["tab_" .. i] then
          local tab = displayTabs[i]
          -- 返回 false 阻止 BottomNavigationView 选中该项
          if tab.needLogin and not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
            tip("请登录后使用")
            return false
          end
          self:initializeHomeTab(i - 1)
          viewPager.setCurrentItem(i - 1)
          return true
        end
      end
      return false
    end
  })

  viewPager.addOnPageChangeListener(luajava.createProxy(ViewPager.OnPageChangeListener, {
    onPageSelected = function(position)
      self:onHomePageSelected(position, displayTabs)
    end
  }))

  self:initializeHomeTab(startIndex)
  viewPager.setCurrentItem(startIndex, false)
  self:onHomePageSelected(startIndex, displayTabs)
end

function HomeFragment:initializeHomeTab(position)
  local state = self.homeTabStates[position + 1]
  if not state or state.initialized then
    return state and state.model or nil
  end

  local tab = state.tab
  local tabViews = {}
  local tabPage = loadlayout(self:getTabLayout(tab.name), tabViews)
  if not tabPage then return nil end

  self.homePagerAdapter.set(position, tabPage)
  self.homePageViews[tab.name] = tabViews

  local model = tab.modelClass:new()
  self.pageModels.home[tab.name] = model
  state.initialized = true
  state.views = tabViews
  state.view = tabPage
  state.model = model

  if tabViews.recycler_view then
    model:setupSingle(tabViews.recycler_view, tabViews.swipe_refresh)
    if tab.modelClass == RecommendModel then
      self:setupRecommendSectionTabs()
    end
   elseif tabViews.sub_view_pager and tabViews.sub_tab_layout then
    local defaultTabKey = Extensions.Config.getString(Constants.SharedDataKeys.FOLLOW_DEFAULT_TAB)
    model:setupTabs(tabViews.sub_view_pager, tabViews.sub_tab_layout, defaultTabKey)
  end

  self:registerModelBottomViews(model)
  return model
end

function HomeFragment:getTabLayout(tabName)
  return ({
    ["推荐"] = Layouts.pages.home.tabs.recommend,
    ["想法"] = Layouts.pages.home.tabs.think,
    ["热榜"] = Layouts.pages.home.tabs.hot,
    ["关注"] = Layouts.pages.home.tabs.followed,
  })[tabName] or error("找不到主页 Layout")
end

function HomeFragment:onHomePageSelected(position, displayTabs)
  local tab = displayTabs[position + 1]
  if not tab then return end
  self:updateBottomNavSelection(position)
  if tab.needLogin and not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    return
  end
  local model = self:initializeHomeTab(position)
  if model and model.ensureLoaded then model:ensureLoaded() end
end

function HomeFragment:updateBottomNavSelection(position)
  if not self.homePageViews or not self.homePageViews.bottom_nav then return end
  local menu = self.homePageViews.bottom_nav.menu
  for i = 0, menu.size() - 1 do
    menu.getItem(i).checked = (i == position)
  end
end

function HomeFragment:initPageWithModel(pageType, views)
  if not views then return end
  local swipeRefresh = views.swipe_refresh
  local recyclerView = views.recycler_view
  local viewPager = views.view_pager
  local tabLayout = views.tab_layout
  local hasList = recyclerView and swipeRefresh
  local hasPager = viewPager and tabLayout
  if not hasList and not hasPager then return end

  local userId = Extensions.Config.get(Constants.SharedDataKeys.USER_ID)

  if pageType == "collections" then
    local model = CollectionTabModel()
    if hasPager then
      model:setupTabs(viewPager, tabLayout)
      if userId then model:setUserId(userId) end
    end
    self.pageModels.collections = model
   elseif pageType == "daily" then
    local model = DailyModel()
    if hasList then
      model:setupSingle(recyclerView, swipeRefresh)
    end
    self.pageModels.daily = model
   elseif pageType == "follow_content" then
    local model = FollowContentModel()
    if hasPager then
      model:setupTabs(viewPager, tabLayout)
      if userId then model:setUserId(userId) end
    end
    self.pageModels.follow_content = model
  end
end

function HomeFragment:initDrawer()
  if not self.views.nav_view then return end
  self:setupDrawerHeader()
  self:setupDrawerMenu()
  self:setupDrawerEdge()
end

function HomeFragment:setupDrawerHeader()
  local nav = self.views.nav_view
  local headerViews = {}
  local header = loadlayout(Layouts.pages.home.drawer_header, headerViews)
  headerViews.card.onClick = function()
    if Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
      Router.go("people", { id = Extensions.Config.get(Constants.SharedDataKeys.USER_ID) })
     else
      Router.go("login")
    end
    self.views.drawer.closeDrawer(Gravity.LEFT)
  end
  headerViews.logout.onClick = function()
    Helpers.BottomDialog.confirm("确定要退出登录吗？", function()
      local headers = {
        ["cookie"] = NetWork.getCookie("https://www.zhihu.com/")
      }
      NetWork.get("https://www.zhihu.com/logout", headers, function(code, content)
        NetWork.clearCookies()
        Extensions.Config.delete(Constants.SharedDataKeys.SIGN_IN_DATA)
        Extensions.Config.delete(Constants.SharedDataKeys.USER_ID)
        Extensions.Config.delete(Constants.SharedDataKeys.UDID)
        tip("已退出登录")
        activity.recreate()
      end, true)
    end)
  end
  nav.addHeaderView(header)
  self.drawerHeader = headerViews
end

function HomeFragment:setupDrawerMenu()
  local nav = self.views.nav_view
  local menu = nav.menu
  menu.clear()
  loadmenu(menu, {
    { id = "home", title = "主页", icon = Helpers.Static.materialDrawable("twotone_home", 24), checkable = true, checked = true, group = 1 },
    { id = "collection", title = "收藏", icon = Helpers.Static.materialDrawable("twotone_book", 24), checkable = true, group = 1 },
    { id = "daily", title = "日报", icon = Helpers.Static.materialDrawable("twotone_work", 24), checkable = true, group = 1 },
    { id = "follow", title = "关注", icon = Helpers.Static.materialDrawable("twotone_list_alt", 24), checkable = true, group = 1 },
    { id = "notification", title = "通知", icon = Helpers.Static.materialDrawable("twotone_notifications", 24), group = 1 },
    { id = "more", title = "更多", icon = Helpers.Static.materialDrawable("twotone_menu", 24), group = 1 },
    { id = "local", title = "本地", icon = Helpers.Static.materialDrawable("twotone_inbox", 24), group = 2 },
    { id = "history", title = "历史", icon = Helpers.Static.materialDrawable("twotone_history", 24), group = 2 },
    { id = "settings", title = "设置", icon = Helpers.Static.materialDrawable("twotone_settings", 24), group = 2 },
  })
  nav.setNavigationItemSelectedListener({
    onNavigationItemSelected = function(menuItem)
      local title = menuItem.title
      local info = findDrawerPage(title)
      -- 返回 false 阻止菜单选中。特殊页走 handleSpecialPage 打开浏览器或对话框，
      -- 其中「更多」含圆桌/专题等无需登录的入口，不做登录拦截
      if info and info.needLogin and not info.isSpecial and not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
        tip("请登录后使用")
        return false
      end
      self:switchToPage(title)
      self.views.drawer.closeDrawer(Gravity.LEFT)
      return true
    end
  })
end

function HomeFragment:showMoreOptionsDialog()
  local options = {"通知", "私信", "设置", "屏蔽用户管理", "圆桌", "专题", "提问"}
  local urls = {
    "https://www.zhihu.com/notifications", "https://www.zhihu.com/messages",
    "https://www.zhihu.com/settings/account", "block_manage",
    "https://www.zhihu.com/appview/roundtable", "https://www.zhihu.com/appview/special", "ask"
  }
  local selectedIndex = 0
  MaterialAlertDialogBuilder(activity)
  .setTitle("请选择")
  .setSingleChoiceItems(options, 0, { onClick = function(v, p) selectedIndex = p + 1 end })
  .setPositiveButton("确定", { onClick = function()
      local url = urls[selectedIndex] or urls[1]
      if url == "block_manage" then
        Router.go("people_list", { title = "屏蔽用户列表",id = "self", type = "block_all" })
       elseif url == "ask" then Router.go("browser", { url = "https://www.zhihu.com", type = "ask", ua = "pc" })
       else Router.go("browser", { url = url })
      end
  end })
  .setNegativeButton("取消", nil)
  .show()
end

function HomeFragment:switchToPage(pageName)
  local page = self:ensurePageInitialized(pageName)
  if page then
    for _, p in pairs(self.pageViews) do
      if p.view then p.view.visibility = View.GONE end
    end
    page.view.visibility = View.VISIBLE
    if self.views.toolbar then self.views.toolbar.title = pageName end
    self.currentPage = pageName
    -- 根据当前页面更新右上角菜单
    self:updateToolbarMenu(pageName)
    for _, item in ipairs(drawerPages) do
      if item.name == pageName and item.modelKey then
        local model = self.pageModels[item.modelKey]
        if model and model.ensureLoaded then model:ensureLoaded() end
        break
      end
    end
   else
    self:handleSpecialPage(pageName)
  end
end

function HomeFragment:handleSpecialPage(pageName)
  local actions = {
    ["通知"] = function() Router.go("browser", { url = "https://www.zhihu.com/notifications" }) end,
    ["更多"] = function() self:showMoreOptionsDialog() end,
    ["本地"] = function() Router.go("local_list") end,
    ["历史"] = function() Router.go("history") end,
    ["设置"] = function() Router.go("settings") end,
  }
  if actions[pageName] then actions[pageName]() end
end

function HomeFragment:setupDrawerEdge()
  local drawer = self.views.drawer
  if not drawer then return end

  local drawerClass = drawer.class
  local leftDraggerField = drawerClass.getDeclaredField("mLeftDragger")
  leftDraggerField.accessible = true
  local viewDragHelper = leftDraggerField.get(drawer)
  local edgeSizeField = viewDragHelper.class.getDeclaredField("mDefaultEdgeSize")
  edgeSizeField.accessible = true
  -- 必须使用 int
  edgeSizeField.setInt(viewDragHelper, int(Helpers.UI.screenWidth()))
  local touchSlopField = viewDragHelper.class.getDeclaredField("mTouchSlop")
  touchSlopField.accessible = true
  -- 必须使用 int
  touchSlopField.setInt(viewDragHelper, int(touchSlopField.getInt(viewDragHelper) * 4))
  local leftCallbackField = drawerClass.getDeclaredField("mLeftCallback")
  leftCallbackField.accessible = true
  local dragCallback = leftCallbackField.get(drawer)
  local peekRunnableField = dragCallback.class.getDeclaredField("mPeekRunnable")
  peekRunnableField.accessible = true
  peekRunnableField.set(dragCallback, luajava.createProxy(Runnable, { run = function() end }))
end

function HomeFragment:loadUserInfo()
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    self:updateDrawerUser(nil)
    return
  end
  local userModel = UserModel(Extensions.Config.get(Constants.SharedDataKeys.USER_ID))
  userModel:load(nil, self:runIfAlive(function(success, data)
    self:updateDrawerUser(data)
    if success then
      self:onLoginSuccess()
    end
  end))
end

function HomeFragment:updateDrawerUser(data)
  if not self.drawerHeader then return end
  if data then
    self.drawerHeader.name.text = data.name
    self.drawerHeader.signature.text = data.headline and data.headline ~= "" and data.headline or "暂无签名"
    Helpers.Image.load(self.drawerHeader.avatar, data.avatarUrl)
   else
    self.drawerHeader.name.text = "未登录"
    self.drawerHeader.signature.text = "点击登录"
    -- 未登录头像使用本地 logo 位图（Bitmap 直接交给 Glide，不走网络解析）
    Helpers.Image.load(self.drawerHeader.avatar, Helpers.Static.image("logo"))
  end
  if self.lastLoginState then
    self.drawerHeader.logout.visibility = View.VISIBLE
   else
    self.drawerHeader.logout.visibility = View.GONE
  end
end

--- 建立推荐页的分区 Tab
--- 分区接口依赖登录态与请求头就绪，故只在 onLoginSuccess 之后生效；
--- 主页 Tab 懒加载，Tab 创建与用户信息返回的先后不定，两处都调用以补齐
function HomeFragment:setupRecommendSectionTabs()
  if not self.loginReady then return end
  local recommendModel = self.pageModels.home and self.pageModels.home["推荐"]
  local recommendViews = self.homePageViews and self.homePageViews["推荐"]
  if recommendModel and recommendViews and recommendViews.tab_layout then
    recommendModel:setupSectionTabs(recommendViews.tab_layout)
  end
end

function HomeFragment:onLoginSuccess()
  buildHeaders()
  self.loginReady = true
  local userId = Extensions.Config.get(Constants.SharedDataKeys.USER_ID)
  if self.pageModels.collections then
    self.pageModels.collections:setUserId(userId)
  end
  if self.pageModels.follow_content then
    self.pageModels.follow_content:setUserId(userId)
  end

  self:setupRecommendSectionTabs()
end

function HomeFragment:searchInCollection()
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用本功能")
    return
  end

  local views = {}
  local dialog = MaterialAlertDialogBuilder(activity)
  .setTitle("搜索收藏")
  .setView(loadlayout(Layouts.common.search_input, views))
  .setPositiveButton("确定", nil)
  .setNegativeButton("取消", nil)
  .show()

  dialog.getButton(dialog.BUTTON_POSITIVE).onClick = function()
    local keyword = views.edit and views.edit.text
    if keyword == "" then
      tip("请输入关键词")
      return
    end
    dialog.dismiss()
    Router.go("search_result", { keyword = keyword, scope = "collection" })
  end
end

function HomeFragment:updateToolbarMenu(pageName)
  local toolbar = self.views.toolbar
  if not toolbar then return end

  local isCollection = (pageName == "收藏")

  local menuItems = {
    { id = isCollection and "add" or "scan",
      title = isCollection and "新建收藏夹" or "扫描",
      icon = Helpers.Static.materialDrawable(isCollection and "twotone_add" or "twotone_qr_code_scanner", 24),
      asAction = "always",
      click = function()
        if isCollection then self:showCreateCollectionSheet() else Router.go("scan") end
      end
    },
    { id = isCollection and "search_collection" or "search",
      title = isCollection and "搜索收藏" or "搜索",
      icon = Helpers.Static.materialDrawable("twotone_search", 24),
      asAction = "always",
      click = function()
        if isCollection then self:searchInCollection() else Router.go("search") end
      end
    },
    { id = "feedback", title = "反馈", click = function() Router.go("feedback") end },
    { id = "about", title = "关于", click = function() Router.go("about") end },
    { id = "settings", title = "设置", click = function() Router.go("settings") end },
  }

  local navIcon = Helpers.Static.materialDrawable("twotone_menu", 24)
  Helpers.UI.setupToolbar(toolbar, {
    menu = menuItems,
    navIcon = navIcon,
    navCallback = function()
      local drawer = self.views.drawer
      if drawer then
        if drawer.isDrawerOpen(Gravity.LEFT) then
          drawer.closeDrawer(Gravity.LEFT)
         else
          drawer.openDrawer(Gravity.LEFT)
        end
      end
    end
  })
end

--- 更新底部导航栏布局方向（响应横竖屏/宽屏切换）
--- 依赖 style: Widget.Material3Expressive.BottomNavigationView
--- 内部读取 m3expressive_bottom_nav_icon_gravity 和 m3expressive_bottom_nav_item_gravity
--- 注意：这些资源 ID 可能在 Material Components 版本更新后变化
function HomeFragment:updateBottomNavLayout()
  local bottomNav = self.homePageViews and self.homePageViews.bottom_nav
  if not bottomNav then return end

  -- 夜间模式切换等场景可能导致 Activity 被重建（recreate）
  -- 重建过程中，EdgeToEdgeUtils.remove 调用的 luajava.clear 可能意外清理 View 使其变为 nil
  -- 此处判断 View 是否为 nil，避免访问空值引发异常（亦可使用 pcall 包装）
  if Objects.isNull(bottomNav) then return end
  bottomNav.itemIconGravity = Helpers.Resources.app.integer.m3expressive_bottom_nav_icon_gravity
  bottomNav.itemGravity = Helpers.Resources.app.integer.m3expressive_bottom_nav_item_gravity
end

function HomeFragment:onConfigurationChanged(newConfig)
  -- 延迟执行，等布局完成
  Helpers.UI.runDelayed(50, self:runIfAlive(function()
    self:updateBottomNavLayout()
  end))
end

function HomeFragment:showCreateCollectionSheet()
  local CollectionEditSheet = require("components.dialog.collection_edit_sheet")
  CollectionEditSheet.show({
    name = "",
    description = "",
    isPublic = true,
    isDefault = false,
    onSuccess = function(collectionId, name)
      tip("创建成功：" .. name)
      -- 刷新收藏夹列表
      if self.pageModels.collections then
        self.pageModels.collections:refresh()
      end
    end,
    onError = function(err)
      tip("创建失败：" .. err)
    end
  })
end

return HomeFragment
