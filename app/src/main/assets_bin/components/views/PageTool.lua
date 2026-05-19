-- components/views/PageTool.lua

local M = {}

import "androidx.viewpager.widget.ViewPager"
import "androidx.viewpager2.widget.ViewPager2"
import "androidx.recyclerview.widget.RecyclerView"
import "com.hydrogen.view.CustomSwipeRefresh"
import "com.google.android.material.tabs.TabLayout"
import "com.hydrogen.LinearLayoutManager"
import "com.hydrogen.adapter.LuaPagerAdapter"
import "com.bumptech.glide.Glide"

local function toInternal(idx) return idx + 1 end
local function toExternal(internalIdx) return internalIdx - 1 end

local function copyTable(original)
  local copy = {}
  for k, v in pairs(original) do copy[k] = v end
  return copy
end

local function clearTable(t)
  for k in pairs(t) do t[k] = nil end
end

local function hasBlockWord(text)
  if not text then return false end
  local blockWords = Extensions.Config.getString(Constants.SharedDataKeys.BLOCK_WORDS)
  if not blockWords or blockWords:gsub(" ", "") == "" then return false end
  for word in string.gmatch(blockWords, "%S+") do
    if string.find(text, word, 1, true) then return true end
  end
  return false
end

local function setupSwipeRefresh(sr, onRefresh)
  local colors = AppTheme.getColors()
  sr.setProgressBackgroundColorSchemeColor(colors.background)
  sr.setColorSchemeColors({colors.primary})
  sr.setOnRefreshListener({ onRefresh = onRefresh })
end

local function setupRecyclerView(rv, adapter, onLoadMore)
  if not rv.getLayoutManager() then
    rv.setLayoutManager(LinearLayoutManager(activity, RecyclerView.VERTICAL, false))
  end
  rv.setAdapter(adapter)

  local lm = rv.getLayoutManager()
  rv.addOnScrollListener(RecyclerView.OnScrollListener{
    onScrollStateChanged = function(_, state)
      if state == RecyclerView.SCROLL_STATE_IDLE then
        Glide.with(activity).resumeRequests()
       else
        Glide.with(activity).pauseRequests()
      end
    end,
    onScrolled = function(_, _, dy)
      if dy > 0 then
        local lastVisible = lm.findLastVisibleItemPosition()
        local totalCount = adapter.getItemCount()
        if lastVisible >= totalCount - 5 then
          onLoadMore()
        end
      end
    end
  })
end

local function finishRefresh(rv, sr, withAnimation)
  if withAnimation and rv and rv.animate then
    rv.animate().alpha(1).setDuration(100).withEndAction({
      run = function()
        if sr then sr.setRefreshing(false) end
      end
    }).start()
   else
    if sr then sr.setRefreshing(false) end
  end
end

local function isLastItemVisible(rv)
  local lm = rv.getLayoutManager()
  return lm.findLastVisibleItemPosition() >= rv.getAdapter().getItemCount() - 1
end

local function needLoginCheck()
  if Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    return true
  end
  tip("请登录后使用")
  return false
end

local DEFAULT_PAGE_STATE = {
  prevUrl = false,
  nextUrl = false,
  isEnd = false,
  canLoad = true,
  isFirstLoad = true,
  needCheckFullPage = true,
  loadPrev = false,
}

--- 创建 PageTool 实例
--- @param config.contentView RecyclerView|ViewPager 列表视图或 ViewPager
--- @param config.swipeRefresh SwipeRefreshLayout 可选，下拉刷新组件
--- @param config.tabLayout TabLayout 可选，Tab 布局
--- @param config.needLogin boolean 是否需要登录
--- @param config.allowLoadPrev boolean 是否允许加载上一页
--- @param config.baseUrlGetter function(key) 获取初始 URL 的函数（单页模式）
--- @param config.baseUrlsGetter function() 获取所有初始 URL 的函数（多页模式）
--- @param config.headersGetter function(key) 获取请求头的函数
--- @param config.urlProcessor function(url, headers) URL 和 Headers 处理器
--- @param config.adapterCreator function(dataList, key) 适配器创建函数
--- @param config.itemParser function(item, dataList) 单页数据解析器（仅单页）
--- @param config.itemParsers table 多页数据解析器 key->function
--- @param config.onLoad function(data, dataList, key, isFirst) 加载回调
--- @param config.prePageCount number 前置页面数量
--- @param config.prePageCreator function(key, idx) 前置页面创建函数
--- @param config.tabClickThrottle boolean 是否启用 Tab 点击节流
function M.new(config)
  if config.prePageCount and config.prePageCount > 0 and not config.prePageCreator then
    error("设置了 prePageCount 必须提供 prePageCreator")
  end

  local isSingle = luajava.instanceof(config.contentView, RecyclerView)
  local singleKey = "__single__"

  local self = {
    contentView = config.contentView,
    swipeRefresh = config.swipeRefresh,
    tabLayout = config.tabLayout,
    needLogin = config.needLogin or false,
    allowLoadPrev = config.allowLoadPrev or false,
    baseUrlGetter = config.baseUrlGetter,
    baseUrlsGetter = config.baseUrlsGetter,
    headersGetter = config.headersGetter,
    urlProcessor = config.urlProcessor,
    adapterCreator = config.adapterCreator,
    itemParsers = {},
    onLoad = config.onLoad,
    prePageCount = config.prePageCount or 0,
    prePageCreator = config.prePageCreator,
    tabClickThrottle = config.tabClickThrottle or false,
    tabThrottleFlags = {},
    viewIds = {},
    pages = {},
    pageKeys = {},
    loadFunction = nil,
    isSingle = isSingle,
    singleKey = singleKey,
    isDestroyed = false,
  }

  if isSingle then
    if config.itemParsers then
      error("单页模式下不能使用 itemParsers，请使用 itemParser")
    end
    if not config.itemParser then
      error("单页模式下必须提供 itemParser")
    end
    self.itemParsers[singleKey] = config.itemParser
   else
    if config.itemParser then
      error("多页模式下不能使用 itemParser，请使用 itemParsers")
    end
    if not config.itemParsers then
      error("多页模式下必须提供 itemParsers")
    end
    for key, parser in pairs(config.itemParsers) do
      self.itemParsers[key] = parser
    end
  end

  setmetatable(self, { __index = M })

  if not self.contentView then
    error("必须提供 contentView")
  end

  if luajava.instanceof(self.contentView, ViewPager) then
    if self.contentView.getAdapter() then
      error("ViewPager 已有 adapter，PageTool 需要自己管理 adapter")
    end
    self.contentView.setAdapter(LuaPagerAdapter())
  end
  if luajava.instanceof(self.contentView, ViewPager2) then
    error("PageTool 不支持 ViewPager2，请更改为ViewPager")
  end

  return self
end

-- 检测是否存活
function M:isAlive()
  return not self.isDestroyed
end

-- 安全执行回调
function M:runIfAlive(callback)
  if not callback then
    return function() end
  end

  return function(...)
    if self:isAlive() then
      callback(...)
    end
  end
end

-- 内部规范化 key
function M:_getKey(key)
  if self.isSingle then
    return key or self.singleKey
   else
    if not key then
      error("多页模式下必须传入 key")
    end
    return key
  end
end

-- 获取页面对象，不存在则报错
function M:_getPage(key)
  key = self:_getKey(key)
  local page = self.pages[key]
  if not page then
    error("未找到 key 为 " .. tostring(key) .. " 的页面，请先调用 initPage")
  end
  return page
end

function M:resetPageState(page)
  for k, v in pairs(DEFAULT_PAGE_STATE) do
    page.state[k] = v
  end
end

--- 初始化页面
function M:initPage(key, pageType, tabName)
  key = self:_getKey(key)
  if self.pages[key] then
    error("页面 key " .. tostring(key) .. " 已经存在，不允许重复初始化")
  end

  local page = {
    data = {},
    state = copyTable(DEFAULT_PAGE_STATE),
    adapter = nil,
  }
  self.pages[key] = page

  if self.tabClickThrottle then
    self.tabThrottleFlags[key] = true
  end

  local rv, sr = self:getPageView(key)

  if self.adapterCreator then
    page.adapter = self.adapterCreator(self:getDataList(key), key)
  end

  if not self.itemParsers[key] then
    error("未找到 key 为 " .. tostring(key) .. " 的 itemParser")
  end

  if not rv.adapter then
    if sr then
      setupSwipeRefresh(sr, function() self:refresh(key) end)
    end

    if page.adapter then
      setupRecyclerView(rv, page.adapter, function()
        if page.state.canLoad then
          self.loadFunction(key, false)
        end
      end)
     else
      error("必须设置适配器")
    end
  end

  if not self.loadFunction then
    self:setupLoadFunction()
  end

  return self
end

function M:setupLoadFunction()
  if self.loadFunction then
    error("loadFunction 已经创建，不能重复初始化")
  end

  local selfRef = self

  self.loadFunction = function(key, loadPrev, isRefresh)
    local page = selfRef:_getPage(key)
    local state = page.state

    if isRefresh and state.isEnd then
      state.isEnd = false
      state.canLoad = true
    end

    if not state.canLoad then return end

    if state.isEnd and not isRefresh then
      tip("已经到底了")
      return
    end

    if loadPrev then
      state.loadPrev = true
    end

    -- 获取请求 URL（优先使用分页 URL，否则使用 baseUrlGetter）
    local url = selfRef:getRequestUrl(key, isRefresh, state)

    if selfRef.needLogin and not needLoginCheck() then
      return
    end

    -- 获取请求头
    local headers = {}
    if selfRef.headersGetter then
      headers = selfRef.headersGetter(key) or {}
    end

    if selfRef.urlProcessor then
      url, headers = selfRef.urlProcessor(url, headers)
    end

    local rv, sr = selfRef:getPageView(key)
    if not rv then return end

    local adapter = page.adapter
    if not adapter then
      error("页面 " .. tostring(key) .. " 的适配器为空")
    end

    NetWork.get(self:runIfAlive(url, headers, function(success, content)
      if not success then
        state.loadPrev = false
        state.canLoad = true
        finishRefresh(rv, sr)
        tip("加载失败")
        return
      end

      state.loadPrev = false
      local data = json.decode(content)

      local function update()
        if isRefresh then
          clearTable(page.data)
          adapter.notifyDataSetChanged()
          selfRef:resetPageState(page)
        end

        if data.paging then
          state.isEnd = data.paging.is_end
          state.prevUrl = data.paging.previous
          state.nextUrl = data.paging.next
          state.canLoad = not state.isEnd
         else
          state.isEnd = true
          state.canLoad = false
        end

        local isFirst = state.isFirstLoad
        if isFirst then
          state.isFirstLoad = false
          if selfRef.onLoad then
            selfRef.onLoad(data, page.data, key, true)
          end
         elseif selfRef.onLoad then
          selfRef.onLoad(data, page.data, key, false)
        end

        if state.needCheckFullPage then
          self.contentView.postDelayed({
            run = self:runIfAlive(function()
              if isLastItemVisible(rv) and state.canLoad then
                self.loadFunction(key, loadPrev, false)
               else
                state.needCheckFullPage = false
              end
            end)
          }, 50)
        end

        local oldCount = #page.data
        local parser = selfRef.itemParsers[key]
        if not parser then
          error("解析器缺失: " .. tostring(key))
        end
        local items = data.data or { data }

        for _, item in ipairs(items) do
          local title = item.title or item.question and item.question.title or ""
          local preview = item.excerpt or item.content or ""
          local contentText = tostring(title) .. tostring(preview)
          if not hasBlockWord(contentText) then
            parser(item, page.data)
          end
        end

        if state.isEnd then
          tip("没有新内容了")
        end

        if isRefresh then
          adapter.notifyDataSetChanged()
          finishRefresh(rv, sr, true)
         else
          if oldCount > 0 then
            adapter.notifyItemRangeInserted(oldCount, #page.data - oldCount)
           else
            adapter.notifyDataSetChanged()
          end
          if sr then
            sr.setRefreshing(false)
          end
        end
      end

      if isRefresh and rv.animate then
        rv.animate().alpha(0).setDuration(100).withEndAction({
          run = update
        }).start()
       else
        update()
      end
    end))

    if isRefresh or state.isFirstLoad then
      if sr then
        sr.setRefreshing(true)
      end
    end
    state.canLoad = false
  end
end

--- 获取请求 URL
function M:getRequestUrl(key, isRefresh, state)
  -- 优先使用分页 URL（prevUrl/nextUrl）
  if state.loadPrev and state.prevUrl and state.prevUrl ~= "" then
    return state.prevUrl
  end
  if not isRefresh and state.nextUrl and state.nextUrl ~= "" then
    return state.nextUrl
  end

  -- 没有分页 URL 时，使用 baseUrlGetter 获取初始 URL
  if self.baseUrlsGetter then
    local urls = self.baseUrlsGetter()
    local url = urls and urls[key]
    if url then return url end
  end

  if self.baseUrlGetter then
    return self.baseUrlGetter(key)
  end

  error("无法获取 URL，请设置 baseUrlGetter 或 baseUrlsGetter")
end

--- 添加多个页面（ViewPager 模式）
function M:addPages(config)
  if self.isSingle then
    error("单页模式不支持 addPages")
  end

  if not config.tabConfigs or #config.tabConfigs == 0 then
    error("必须传入 tabConfigs，且每个配置必须包含 key 和 name")
  end

  for _, tabConfig in ipairs(config.tabConfigs) do
    if not tabConfig.key or tabConfig.key == "" then
      error("每个 tabConfig 必须包含非空的 key 字段")
    end
  end

  local pageType = config.pageType or 2
  local tabConfigs = config.tabConfigs
  local defaultKey = config.defaultTab
  local adapter = self.contentView.getAdapter()

  -- 收集所有页面的 key（按顺序）
  self.pageKeys = {}
  for _, tabConfig in ipairs(tabConfigs) do
    table.insert(self.pageKeys, tabConfig.key)
  end

  -- 前置页面
  for i = 1, self.prePageCount do
    if i > #tabConfigs then
      error("前置页面数量超出 tabConfigs 总数")
    end
    local tabConfig = tabConfigs[i]
    local externalIdx = toExternal(i)
    local view = self.prePageCreator(tabConfig.key, externalIdx)
    if view then
      adapter.add(view, tabConfig.name)
      adapter.notifyDataSetChanged()
    end
  end

  -- 列表页面
  local listCount = #tabConfigs - self.prePageCount
  for i = 1, listCount do
    local tabConfig = tabConfigs[self.prePageCount + i]
    self:addSinglePage(tabConfig.key, pageType, tabConfig.name)
    adapter.notifyDataSetChanged()
  end

  self.tabLayout.setupWithViewPager(self.contentView)

  if defaultKey then
    for i, tabConfig in ipairs(tabConfigs) do
      if tabConfig.key == defaultKey then
        self.tabLayout.getTabAt(toExternal(i)).select()
        break
      end
    end
  end

  return self
end

--- 添加单个列表页（内部使用）
function M:addSinglePage(key, pageType, tabName)
  if not key or key == "" then
    error("addSinglePage 必须传入非空的 key")
  end

  local listId = "list_" .. key
  local srId = "sr_" .. key

  local layout = pageType == 1 and {
    RecyclerView,
    layout_width = "fill",
    layout_height = "fill",
    id = listId,
    nestedScrollingEnabled = true,
    } or {
    CustomSwipeRefresh,
    id = srId,
    layout_height = "fill",
    layout_width = "fill",
    {
      RecyclerView,
      layout_width = "fill",
      id = listId,
      layout_height = "fill",
      nestedScrollingEnabled = true,
    }
  }

  self.contentView.getAdapter().add(loadlayout(layout, self.viewIds), tabName or "")
  self:initPage(key, pageType, tabName)
  return self
end

--- 设置 Tab 切换监听
function M:setOnTabListener(callback)
  if not self.loadFunction then
    error("先调用 initPage 或 addPages")
  end

  callback = callback or function() end
  local selfRef = self

  self.tabLayout.addOnTabSelectedListener({
    onTabSelected = function(tab)
      local pos = tab.getPosition()
      local key = selfRef.pageKeys[pos + 1]
      callback(selfRef, key)
      -- 跳过前置页面
      if self:isCurrentPagePrePage() then
        return
      end
      selfRef:throttleTabClick(key, function()
        selfRef:loadPage(key, false, true)
      end)
    end,
    onTabReselected = function(tab)
      local pos = tab.getPosition()
      local key = selfRef.pageKeys[pos + 1]
      callback(selfRef, key)
      -- 跳过前置页面
      if self:isCurrentPagePrePage() then
        return
      end
      selfRef:throttleTabClick(key, function()
        selfRef:refresh(key)
      end)
    end
  })
  return self
end

function M:throttleTabClick(key, action)
  if not self.tabClickThrottle then
    action()
    return
  end

  if self.tabThrottleFlags[key] then
    self.tabThrottleFlags[key] = false
    task(1050, self:runIfAlive(function()
      self.tabThrottleFlags[key] = true
    end))
    action()
  end
end

--- 加载页面（单页可省略 key）
function M:loadPage(key, loadPrev, skipIfHasData)
  key = self:_getKey(key)
  local page = self:_getPage(key)
  if skipIfHasData and #page.data > 0 then
    return self
  end
  if not self.loadFunction then
    error("loadFunction 未初始化")
  end
  self.loadFunction(key, loadPrev, false)
  return self
end

--- 刷新页面（单页可省略 key）
function M:refresh(key)
  key = self:_getKey(key)
  self:_getPage(key)
  if not self.loadFunction then
    error("loadFunction 未初始化")
  end
  self.loadFunction(key, false, true)
  return self
end

--- 清空页面数据
function M:clearPage(key)
  key = self:_getKey(key)
  local page = self.pages[key]
  if page then
    self:resetPageState(page)
    clearTable(page.data)
    if page.adapter then
      page.adapter.notifyDataSetChanged()
    end
  end
  return self
end

--- 获取页面数据
function M:getDataList(key)
  local page = self:_getPage(key)
  return page.data
end

--- 获取当前页面 key（仅多页模式有效）
function M:getCurrentPageKey()
  if self.isSingle then
    return self.singleKey
  end
  local pos = self.contentView.getCurrentItem()
  return self.pageKeys[pos + 1]
end

--- 判断当前页面是否为前置页面
function M:isCurrentPagePrePage()
  if self.isSingle then
    return false
  end
  local pos = self.contentView.getCurrentItem()
  return pos < self.prePageCount
end

--- 判断指定 key 的页面是否为前置页面
function M:isPrePageByKey(key)
  if self.isSingle then
    return false
  end
  for i = 1, self.prePageCount do
    if self.pageKeys[i] == key then
      return true
    end
  end
  return false
end

--- 获取当前页面索引（包含前置页面）
function M:getCurrentPageIndex()
  if self.isSingle then
    return 0
  end
  return self.contentView.getCurrentItem()
end

--- 获取管理索引（排除前置页面）
function M:toManagedIndex(viewPagerPosition)
  return viewPagerPosition - self.prePageCount
end

--- 获取页面视图
function M:getPageView(key)
  if self.isSingle then
    return self.contentView, self.swipeRefresh
  end
  local listId = "list_" .. key
  local srId = "sr_" .. key
  local rv = self.viewIds[listId]
  if not rv then
    error("未找到 key 为 " .. tostring(key) .. " 的 RecyclerView 视图")
  end
  return rv, self.viewIds[srId]
end

function M:destroy()
  self.isDestroyed = true
  self.pages = nil
  self.viewIds = nil
  self.pageKeys = nil
end

return M