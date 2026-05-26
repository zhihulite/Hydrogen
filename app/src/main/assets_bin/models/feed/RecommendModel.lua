-- models/feed/RecommendModel.lua
-- 推荐流 - PageToolModel

local PageToolModel = require("models.base.PageToolModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")
local Storage = require("services.cache.storage")

import "androidx.appcompat.widget.PopupMenu"

local RecommendModel = Extensions.Class(PageToolModel)
RecommendModel:chainUp("destroy")

function RecommendModel:ctor()
  self.requestHeadKey = "defaultHead"
  self.needLogin = false
  self.pageSize = 10
  self.currentSectionUrl = self:getDefaultUrl()
  self.sectionUrls = {}
  self.cacheLoaded = false
  self.cache = {}
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

    tabLayout.addOnTabSelectedListener(TabLayout.OnTabSelectedListener({
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

function RecommendModel:isDuplicate(key)
  for _, v in ipairs(self.cache) do
    if v == key then return true end
  end
  return false
end

function RecommendModel:addToCache(key)
  local limit = Extensions.Config.getNumber(Constants.SharedDataKeys.FEED_CACHE)
  if #self.cache >= limit then
    table.remove(self.cache, 1)
  end
  table.insert(self.cache, key)
  self:saveCache()
end

function RecommendModel:reportRead(readData, isRead)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then return end
  local encoded = json.encode(readData)
  local state = isRead and '"r"' or '"t"'
  local postData = string.format('targets=%s',
  NetWork.urlEncode('[[' .. state .. ',' .. encoded .. ']]'))
  NetWork.post("https://api.zhihu.com/lastread/touch/v2", postData, function() end)
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
    for _, v in ipairs(data.data.items or {}) do
      local raw_button = v.raw_button
      local method = string.lower(raw_button.action.method)
      local panel_text = raw_button.text.panel_text
      table.insert(menuItems, {
        title = panel_text,
        action = function()
          if raw_button.action.backend_url then
            -- 发送反馈请求
            self:post(raw_button.action.backend_url, "", nil , function(success, data)
              if success then
                tip(raw_button.text.toast_text or "操作成功")
                -- 刷新当前列表，移除该条目
                self:notifyListeners("itemDisliked", item)
              end
            end)
           elseif raw_button.action.intent_url then
            Router.go("browser", { url = "https://www.zhihu.com/report?id=" .. raw_button.action.intent_url .. "&source=android" })
          end
        end
      })
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

    popup.setOnMenuItemClickListener({
      onMenuItemClick = function(menuItem)
        local callback = menuItems[menuItem.itemId]
        if callback and callback.action then
          callback.action()
        end
        return true
      end
    })

    popup.show()
  end)
end

function RecommendModel:parseItem(rawItem)
  if rawItem.type ~= "feed" then return nil end

  local target = rawItem.target or {}
  local author = target.author or {}

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
    self:addToCache(cacheKey)
  end

  local title = target.title or ""
  if contentType == "answer" then
    title = target.question and target.question.title or ""
   elseif contentType == "pin" then
    title = author.name .. "发表了想法"
  end

  local preview = author.name .. " : " .. (target.excerpt or target.excerpt_title or "")

  return {
    id = id,
    type = contentType,
    title = title,
    preview = preview ~= "" and fromHtml(preview) or nil,
    voteupCount = target.voteup_count or target.vote_count or target.reaction_count or 0,
    commentCount = target.comment_count or 0,
    author = {
      id = tostring(author.id),
      name = author.name or "",
    },
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

-- 添加监听 itemDisliked 的方法，在外部移除条目
function RecommendModel:onItemDisliked(item)
  -- 这个方法由外部调用或监听触发，用于从列表中移除被点踩的条目
  self:notifyListeners("itemDisliked", item)
end

return RecommendModel