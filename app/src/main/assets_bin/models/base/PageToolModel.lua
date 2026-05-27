-- models/base/PageToolModel.lua
-- 分页列表模型 - 负责配置 PageTool，支持单页和多页（带 Tab）

local BaseModel = require("models.base.BaseModel")
local PageTool = require("components.views.PageTool")

local PageToolModel = Extensions.Class(BaseModel)

function PageToolModel:ctor()
  self.pageTool = nil -- PageTool 实例
  self.allowLoadPrev = false -- 是否允许加载上一页（用于评论等双向分页）
  self.tabClickThrottle = false -- 是否启用 Tab 点击节流
  self.prePageCount = 0 -- 前置页面数量
  self.prePageCreator = nil -- 前置页面创建函数 function(idx, key) return view
  self.requestHeadKey = "defaultHead" -- 请求头 key
  self.needLogin = false -- 是否需要登录
  self.urlProcessor = nil -- URL/Header 预处理函数
end

-- 子类必须实现 -----------------------------------------------------------------

--- 获取单页请求 URL（单页模式）
--- @return string
function PageToolModel:getInitialUrl()
  error("必须实现 getInitialUrl()")
end

--- 获取多页 URL 列表（多 Tab 模式），返回字典 key -> url
--- @return table
function PageToolModel:getInitialUrls()
  return { single = self:getInitialUrl() }
end

--- 获取请求头（可被子类重写）
--- @param key string 页面标识
--- @return table
function PageToolModel:getRequestHeaders(key)
  if self.requestHeadKey then
    return Headers[self.requestHeadKey] or {}
  end
  return {}
end

--- 解析单条原始数据（统一签名）
--- @param raw table 原始数据
--- @param key string 页面标识（单页时为 "single"，多页时为对应 key）
--- @return table|nil 解析后的 item，可返回 { items = {...} } 批量添加
function PageToolModel:parseItem(raw, key)
  error("必须实现 parseItem(raw, key)")
end

--- 创建适配器
--- @param dataList table 当前页的数据列表
--- @param key string 页面标识
--- @return SimpleRecyclerAdapter
function PageToolModel:createAdapter(dataList, key)
  error("必须实现 createAdapter(dataList, key)")
end

-- 子类可选实现 -----------------------------------------------------------------

--- 获取 Tab 配置列表（多页模式），每项包含 { key = string, name = string }
--- @return table|nil
function PageToolModel:getTabConfigs()
  return nil
end

--- 首次加载回调
--- @param data table 原始响应数据
--- @param list table 当前页数据列表
--- @param key string 页面标识
function PageToolModel:onFirstLoad(data, list, key) end

--- Tab 切换回调（仅多页模式）
--- @param key string 切换到的新页面标识
function PageToolModel:onTabSelected(key) end

-- 内部辅助 --------------------------------------------------------------------

--- 处理 parseItem 返回值，支持单条或批量
--- @param result table|nil
--- @param dataList table
local function processParseResult(result, dataList)
  if not result then return end
  if result.items then
    for _, item in ipairs(result.items) do
      table.insert(dataList, item)
    end
   else
    table.insert(dataList, result)
  end
end

-- 初始化单页模式 --------------------------------------------------------------

--- 初始化单页模式（无 Tab）
--- @param recyclerView RecyclerView
--- @param swipeRefresh SwipeRefreshLayout|nil
--- @return PageTool
function PageToolModel:setupSingle(recyclerView, swipeRefresh)
  self.pageTool = PageTool.new({
    contentView = recyclerView,
    swipeRefresh = swipeRefresh,
    needLogin = self.needLogin,
    allowLoadPrev = self.allowLoadPrev,
    baseUrlGetter = function() return self:getInitialUrl() end,
    headersGetter = function(key) return self:getRequestHeaders(key) end,
    urlProcessor = self.urlProcessor,
    adapterCreator = function(dataList, key)
      return self:createAdapter(dataList, key)
    end,
    itemParser = function(rawItem, dataList)
      local result = self:parseItem(rawItem, "single")
      processParseResult(result, dataList)
    end,
    onLoad = function(data, dataList, key, isFirst)
      if isFirst then
        self:onFirstLoad(data, dataList, key)
      end
    end,
  })
  self.pageTool:initPage()
  return self.pageTool
end

-- 初始化多页模式 --------------------------------------------------------------

--- 初始化多页模式（带 TabLayout + ViewPager）
--- @param viewPager ViewPager
--- @param tabLayout TabLayout
--- @param defaultTab string|nil 默认选中的 Tab key
--- @return PageTool
function PageToolModel:setupTabs(viewPager, tabLayout, defaultTab)
  local tabConfigs = self:getTabConfigs()
  if not tabConfigs or #tabConfigs == 0 then
    error("多页模式必须实现 getTabConfigs() 返回非空列表")
  end

  local itemParsers = {}

  for _, tab in ipairs(tabConfigs) do
    local key = tab.key
    itemParsers[key] = function(rawItem, dataList)
      local result = self:parseItem(rawItem, key)
      processParseResult(result, dataList)
    end
  end

  self.pageTool = PageTool.new({
    contentView = viewPager,
    tabLayout = tabLayout,
    prePageCount = self.prePageCount,
    prePageCreator = self.prePageCreator,
    tabClickThrottle = self.tabClickThrottle,
    needLogin = self.needLogin,
    baseUrlsGetter = function() return self:getInitialUrls() end,
    headersGetter = function(key) return self:getRequestHeaders(key) end,
    urlProcessor = self.urlProcessor,
    adapterCreator = function(dataList, key)
      return self:createAdapter(dataList, key)
    end,
    itemParsers = itemParsers,
    onLoad = function(data, dataList, key, isFirst)
      if isFirst then
        self:onFirstLoad(data, dataList, key)
      end
    end,
  })

  self.pageTool:addPages({ tabConfigs = tabConfigs, defaultTab = defaultTab })
  self.pageTool:setOnTabListener(function(tool, key)
    self:onTabSelected(key)
  end)

  return self.pageTool
end

-- 公共方法（单页模式请勿传入key）---------------------------------------------

--- 刷新页面（单页模式请勿传入key）
--- @param key string|nil
function PageToolModel:refresh(key)
  if not self:isAlive() then return end
  key = key or self:getCurrentKey()
  if self.pageTool then self.pageTool:refresh(key) end
end

--- 加载更多（下一页）（单页模式请勿传入key）
--- @param key string|nil
function PageToolModel:loadMore(key)
  if not self:isAlive() then return end
  if self.pageTool then self.pageTool:loadPage(key, false) end
end

--- 获取指定页面的数据列表（单页模式请勿传入key）
--- @param key string|nil
--- @return table
function PageToolModel:getItems(key)
  if not self:isAlive() then return {} end
  return self.pageTool and self.pageTool:getDataList(key) or {}
end

--- 判断当前页面是否为前置页面
--- @return boolean
function PageToolModel:isCurrentPagePrePage()
  if not self:isAlive() then return false end
  return self.pageTool and self.pageTool:isCurrentPagePrePage() or false
end

--- 判断指定 key 的页面是否为前置页面
--- @param key string
--- @return boolean
function PageToolModel:isPrePageByKey(key)
  if not self:isAlive() then return false end
  return self.pageTool and self.pageTool:isPrePageByKey(key) or false
end

--- 确保页面数据已加载，如果当前无数据则自动刷新
--- @param key string|nil 页面标识（多页模式可选，单页模式请勿传入key）
function PageToolModel:ensureLoaded(key)
  if not self:isAlive() then return end
  if self:isCurrentPagePrePage() then return end
  key = key or self:getCurrentKey()
  local items = self:getItems(key)
  if #items > 0 then return end
  self:refresh(key)
end

--- 清空指定页面的数据（单页模式请勿传入key)
--- @param key string|nil
function PageToolModel:clear(key)
  if not self:isAlive() then return end
  if self.pageTool then self.pageTool:clearPage(key) end
end

--- 获取当前页面标识（仅多页模式有效）
--- @return string|nil
function PageToolModel:getCurrentKey()
  if not self:isAlive() then return nil end
  return self.pageTool and self.pageTool:getCurrentPageKey() or nil
end

--- 获取当前页面的 RecyclerView 实例（单页模式直接返回，多页模式返回当前 Tab 的 RecyclerView）
--- @return RecyclerView|nil
function PageToolModel:getCurrentRecyclerView()
  if not self:isAlive() then return nil end
  if not self.pageTool then return nil end
  local key = self:getCurrentKey() or self.pageTool.singleKey
  local rv = self.pageTool:getPageView(key)
  return rv
end

--- 获取当前页面下的所有 RecyclerView 实例（多 Tab 页面返回每个 Tab 的列表，单页返回自身）
--- 自动跳过前置页面（prePage）
--- @return table RecyclerView 列表
function PageToolModel:getAllRecyclerViews()
  local rvs = {}
  if not self:isAlive() then return rvs end
  if not self.pageTool then return rvs end

  for i, key in ipairs(self.pageTool.pageKeys or {}) do
    -- 跳过前置页面
    if not self:isPrePageByKey(key) then
      local rv = self.pageTool:getPageView(key)
      if rv then
        table.insert(rvs, rv)
      end
    end
  end

  -- 单页模式兜底
  if #rvs == 0 and self.pageTool.isSingle and not self:isCurrentPagePrePage() then
    local rv = self.pageTool:getPageView()
    if rv then
      table.insert(rvs, rv)
    end
  end

  return rvs
end

--- 销毁实例
function PageToolModel:destroy()
  self.isDestroyed = true
  if self.pageTool then
    self.pageTool:destroy()
    self.pageTool = nil
  end
end

return PageToolModel