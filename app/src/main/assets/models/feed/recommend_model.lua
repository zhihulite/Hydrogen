-- models/feed/recommend_model.lua
-- 推荐流 - PageToolModel

local PageToolModel = require("models.base.page_tool_model")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
local Storage = require("services.cache.storage")

import "androidx.appcompat.widget.PopupMenu"
import "androidx.recyclerview.widget.GridLayoutManager"
import "com.google.android.material.tabs.TabLayout"

local RecommendModel = Extensions.Class(PageToolModel)

function RecommendModel:ctor()
  self.requestHeadKey = Constants.RequestHeadKeys.DEFAULT_HEAD
  self.needLogin = false
  self.pageSize = 10
  self.currentSectionUrl = self:getDefaultUrl()
  self.sectionUrls = {}
  self.cacheLoaded = false
  self.cache = {}
  self.cacheDirty = false
  self.cacheFlushScheduled = false
end

function RecommendModel:getDefaultUrl()
  return "https://api.zhihu.com/topstory/recommend"
end

function RecommendModel:setSectionUrl(url)
  self.currentSectionUrl = url
  self:refresh()
end

function RecommendModel:getInitialUrl()
  return self.currentSectionUrl
end

-- 网格每列的目标宽度(dp)，列数 = 容器宽度 / 目标宽度，下限 1 列
local ITEM_WIDTH_DP = 300

local function computeSpanCount(width)
  -- RecyclerView 尚未测量时用屏幕宽度做初始值，首次布局后由监听器按实际宽度修正
  if width <= 0 then
    width = activity.resources.displayMetrics.widthPixels
  end
  return math.max(math.floor(px2dp(width) / ITEM_WIDTH_DP), 1)
end

--- 初始化单页模式：推荐流用网格布局，每次初始化新建 LayoutManager
--- @param recyclerView RecyclerView
--- @param swipeRefresh SwipeRefreshLayout|nil
--- @return PageTool
function RecommendModel:setupSingle(recyclerView, swipeRefresh)
  local layoutManager = GridLayoutManager(activity, computeSpanCount(recyclerView.width))
  recyclerView.layoutManager = layoutManager
  -- 旋转与分屏不重建 Activity，容器宽度变化时按新宽度重算列数。
  -- setSpanCount 只改字段并清 span 索引缓存，不安排新的布局；此处又正处在布局回调里，
  -- 同步 requestLayout 会被忽略，故 post 到下一帧再请求，让新列数当场生效
  recyclerView.addOnLayoutChangeListener(luajava.createProxy(View.OnLayoutChangeListener, {
    onLayoutChange = function(v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom)
      local width = right - left
      if width <= 0 or width == oldRight - oldLeft then return end
      local spanCount = computeSpanCount(width)
      if spanCount ~= layoutManager.spanCount then
        layoutManager.spanCount = spanCount
        recyclerView.post(self:runIfAlive(function()
          layoutManager.requestLayout()
        end))
      end
    end,
  }))
  return PageToolModel.setupSingle(self, recyclerView, swipeRefresh)
end

function RecommendModel:setupSectionTabs(tabLayout)
  if not tabLayout then return end

  local function buildSectionUrl(sec)
    if sec.section_id then
      return string.format(
      "https://api.zhihu.com/feed-root/section/%s?%schannelStyle=0",
      sec.section_id,
      sec.sub_page_id and "sub_page_id=" .. sec.sub_page_id .. "&" or ""
      )
    end
    return self:getDefaultUrl()
  end

  tabLayout.clearOnTabSelectedListeners()
  tabLayout.removeAllTabs()
  self.sectionUrls = {}

  self:loadSections(function(sections)
    if not sections or #sections == 0 then
      tabLayout.visibility = View.GONE
      return
    end

    for _, sec in ipairs(sections) do
      local name = sec.section_name or "推荐"
      local tab = tabLayout.newTab()
      tab.text = name
      tabLayout.addTab(tab, false)
      table.insert(self.sectionUrls, buildSectionUrl(sec))
    end

    tabLayout.visibility = View.VISIBLE

    tabLayout.addOnTabSelectedListener(luajava.createProxy(TabLayout.OnTabSelectedListener, {
      onTabSelected = function(tab)
        local pos = tab.position
        local url = self.sectionUrls[pos + 1]
        if url then self:setSectionUrl(url) end
      end,
      onTabReselected = function(tab) self:refresh() end,
    }))

    if tabLayout.tabCount > 0 then
      tabLayout.selectTab(tabLayout.getTabAt(0))
      if #self.sectionUrls > 0 then
        self:setSectionUrl(self.sectionUrls[1])
      end
    end
  end)
end

function RecommendModel:loadSections(callback)
  local url = "https://api.zhihu.com/feed-root/sections/query/v2"
  self:fetch(url, nil, function(success, data)
    if not success then
      if callback then callback(nil) end
      return
    end

    if not data.selected_sections then
      if callback then callback(nil) end
      return
    end

    if not Extensions.Config.getBool(Constants.SharedDataKeys.CLOSE_RECOMMEND_ALL_SECTION) then
      table.insert(data.selected_sections, 1, { section_name = "全站" })
    end

    if callback then callback(data.selected_sections) end
  end)
end

function RecommendModel:initCache()
  if self.cacheLoaded then return end
  self.cache = Storage.get("recommend_history", {})
  self.cacheLoaded = true
end

function RecommendModel:saveCache()
  Storage.set("recommend_history", self.cache)
end

-- 合并落盘：Storage.set 是同步文件写，解析一页会连续追加多条去重键，
-- 集中到下一次主线程消息里只写一次
function RecommendModel:scheduleSaveCache()
  self.cacheDirty = true
  if self.cacheFlushScheduled then return end
  self.cacheFlushScheduled = true
  Helpers.UI.runDelayed(0, self:runIfAlive(function()
    self.cacheFlushScheduled = false
    if self.cacheDirty then
      self.cacheDirty = false
      self:saveCache()
    end
  end))
end

function RecommendModel:isDuplicate(key)
  for _, v in ipairs(self.cache) do
    if v == key then return true end
  end
  return false
end

-- 追加去重键，超出上限时从头裁剪到上限
-- @param key 去重键
-- @param limit 缓存上限，缺省时读配置
function RecommendModel:addToCache(key, limit)
  limit = limit or Extensions.Config.getNumber(Constants.SharedDataKeys.FEED_CACHE)
  while #self.cache > 0 and #self.cache >= limit do
    table.remove(self.cache, 1)
  end
  table.insert(self.cache, key)
  self:scheduleSaveCache()
end

function RecommendModel:reportRead(readData, isRead)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then return end
  local state = isRead and '"r"' or '"t"'
  local postData = string.format('targets=%s',
  NetWork.urlEncode('[[' .. state .. ',' .. readData .. ']]'))
  NetWork.post("https://api.zhihu.com/lastread/touch/v2", postData, function() end)
end

-- 从当前列表移除条目
-- getItems() 返回的表就是适配器持有的那张表，改表后按下标通知适配器
-- @param item 条目数据
function RecommendModel:removeItem(item)
  local items = self:getItems()
  for i, it in ipairs(items) do
    if it == item then
      table.remove(items, i)
      local rv = self:getCurrentRecyclerView()
      if rv and rv.adapter then
        rv.adapter.notifyItemRemoved(i - 1)
      end
      break
    end
  end
end

-- 显示不感兴趣菜单
-- @param item 当前条目数据
-- @param anchor 锚点View（菜单将显示在其旁边）
function RecommendModel:showDislikeMenu(item, anchor)
  local url = string.format(
  "https://api.zhihu.com/negative-feedback/panel?scene_code=RECOMMEND&content_type=%s&content_token=%s",
  item.type, item.id
  )

  self:fetch(url, {}, function(success, data)
    if not success or not data then
      tip("获取选项失败")
      return
    end

    local menuItems = {}
    local panelItems = data.data and data.data.items or {}
    for _, v in ipairs(panelItems) do
      local raw_button = v.raw_button
      if raw_button and raw_button.action and raw_button.text then
        local panel_text = raw_button.text.panel_text
        table.insert(menuItems, {
          title = panel_text,
          action = function()
            if raw_button.action.backend_url then
              -- 发送反馈请求
              self:post(raw_button.action.backend_url, "", nil , function(success, data)
                if success then
                  tip(raw_button.text.toast_text or "操作成功")
                  self:removeItem(item)
                  self:notifyListeners("itemDisliked", item)
                end
              end)
             elseif raw_button.action.intent_url then
              Router.go("browser", { url = "https://www.zhihu.com/report?id=" .. raw_button.action.intent_url .. "&source=android" })
            end
          end
        })
      end
    end

    if #menuItems == 0 then
      tip("没有可用的选项")
      return
    end

    -- 创建并显示 PopupMenu
    local popup = PopupMenu(activity, anchor)
    local menu = popup.menu

    for i, menuItem in ipairs(menuItems) do
      menu.add(0, i, 0, menuItem.title)
    end

    popup.onMenuItemClick = function(menuItem)
      local callback = menuItems[menuItem.itemId]
      if callback and callback.action then
        callback.action()
      end
      return true
    end

    popup.show()
  end)
end

function RecommendModel:parseItem(rawItem)
  if rawItem.type ~= "feed" then return nil end

  local target = Helpers.ZhihuItem.unwrap(rawItem)
  local author = Helpers.ZhihuItem.authorOf(target.author)
  local authorName = author and author.name or ""

  local contentType = target.type
  local id = tostring(target.id)

  local cacheKey = contentType .. "_" .. id

  local feedCacheLimit = Extensions.Config.getNumber(Constants.SharedDataKeys.FEED_CACHE)
  if feedCacheLimit > 1 then
    self:initCache()
    if self:isDuplicate(cacheKey) then
      if Extensions.Config.getBool(Constants.SharedDataKeys.FEED_CACHE_TIP) then
        tip("找到重复内容")
      end
      self:reportRead(rawItem.brief, true)
      return nil
    end
    self:addToCache(cacheKey, feedCacheLimit)
  end

  -- pin 卡标题带作者名前缀，其余类型走统一取标题链
  local title
  if contentType == "pin" then
    title = authorName .. "发表了想法"
   else
    title = Helpers.ZhihuItem.titleOf(target)
  end

  local preview = authorName .. " : " .. (target.excerpt or target.excerpt_title or "")

  return {
    id = id,
    type = contentType,
    title = title,
    preview = preview ~= "" and fromHtml(preview) or nil,
    voteupCount = Helpers.ZhihuItem.voteupOf(target),
    commentCount = target.comment_count or 0,
    author = author,
    readInfo = {
      isRead = false,
      data = rawItem.brief,
    },
  }
end

function RecommendModel:createAdapter(dataList)
  return SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.recommend)
    end,
    onBind = function(views, item, position, holder)
      views.title.text = item.title or ""
      views.preview.text = item.preview or ""
      views.like_count.text = tostring(item.voteupCount)
      views.comment_count.text = tostring(item.commentCount)

      -- 长按卡片显示不感兴趣菜单
      views.card.onLongClick = function()
        self:showDislikeMenu(item, views.card)
        return true
      end

      views.card.onClick = function()
        if item.readInfo and not item.readInfo.isRead then
          item.readInfo.isRead = true
          self:reportRead(item.readInfo.data, true)
        end
        Helpers.ZhihuParser.go(item.type, { id = item.id }, { sharedElement = views.card })
      end
    end,
  })
end

return RecommendModel