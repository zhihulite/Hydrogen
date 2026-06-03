-- models/user/PeopleModel.lua
-- 用户主页 - PageToolModel

local PageToolModel = require("models.base.PageToolModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")
local UserModel = require("models.user.UserModel")

local PeopleModel = Extensions.Class(PageToolModel)

-- 回答排序选项
local ANSWER_SORT_OPTIONS = {
  { name = "时间", order_by = "created" },
  { name = "赞同", order_by = "voteup_count" },
}

function PeopleModel:ctor(userId)
  self.requestHeadKey = "app"
  self.needLogin = false
  self.userId = tostring(userId)
  self.urlToken = nil
  self.userData = nil
  self.tabConfigs = {}
  self.urls = {}
  self.currentSortIndex = 1
  self.currentSortOption = ANSWER_SORT_OPTIONS[1]
  self.answerKey = nil
  self.userModel = UserModel()
  self._historyRecorded = false -- 防止重复记录
end

function PeopleModel:destroy()
  if self.userModel then
    self.userModel:destroy()
    self.userModel = nil
  end
  self.userData = nil
  self.tabConfigs = nil
  self.urls = nil
  self.answerKey = nil
end

function PeopleModel:getSortOptions()
  return ANSWER_SORT_OPTIONS
end

function PeopleModel:getCurrentSortIndex()
  return self.currentSortIndex
end

function PeopleModel:getCurrentSortName()
  return self.currentSortOption.name
end

function PeopleModel:getAnswerKey()
  return self.answerKey
end

function PeopleModel:setSort(sortIndex, callback)
  if sortIndex == self.currentSortIndex then
    if callback then callback(false) end
    return
  end
  self.currentSortIndex = sortIndex
  self.currentSortOption = ANSWER_SORT_OPTIONS[sortIndex]
  self:reloadAnswerTab(callback)
end

function PeopleModel:reloadAnswerTab(callback)
  if self.answerKey and self.pageTool then
    self.urls[self.answerKey] = self:getAnswerUrl()
    self.pageTool:refresh(self.answerKey)
    if callback then callback(true) end
   elseif callback then
    callback(false)
  end
end

function PeopleModel:getAnswerUrl()
  local baseId = self.urlToken or self.userId
  local sort = self.currentSortOption
  return "https://www.zhihu.com/api/v4/members/" .. baseId .. "/answers?limit=20&order_by=" .. sort.order_by
end

function PeopleModel:updateDetailPage(userData)
  local views = self.detailViews
  if not views then return end
  if views.avatar and userData.avatarUrl then
    Helpers.Image.load(views.avatar, userData.avatarUrl)
  end
  if views.name then
    views.name.text = userData.name
  end
  if views.headline then
    views.headline.text = userData.headline or "无签名"
  end
  if views.followers then
    views.followers.text = self:formatNumber(userData.followerCount)
  end
  if views.following then
    views.following.text = self:formatNumber(userData.followingCount)
  end
  if views.voteup then
    views.voteup.text = self:formatNumber(userData.voteupCount)
  end
end

function PeopleModel:loadUserInfo(callback)
  local url = "https://www.zhihu.com/api/v4/members/" .. self.userId ..
  "?include=voteup_count,follower_count,following_count,is_following,is_blocking,headline,avatar_url"

  self:fetch(url, nil, function(success, response)
    if not success then
      if callback then callback(false) end
      return
    end

    self.userId = tostring(response.id)
    self.urlToken = response.url_token

    self.userData = {
      id = tostring(response.id),
      name = response.name,
      headline = response.headline or "",
      avatarUrl = response.avatar_url or "",
      voteupCount = response.voteup_count or 0,
      followerCount = response.follower_count or 0,
      followingCount = response.following_count or 0,
      isFollowing = response.is_following or false,
      isBlocking = response.is_blocking or false,
      urlToken = response.url_token,
    }

    -- 记录历史记录（仅在首次加载成功后）
    if not self._historyRecorded then
      self:_recordHistory()
      self._historyRecorded = true
    end

    self:updateDetailPage(self.userData)
    self:notifyListeners("userInfoChanged", self.userData)

    if callback then callback(true, self.userData) end
  end)
end

-- 添加到历史记录
function PeopleModel:_recordHistory()
  if not self.userData then return end

  -- 标题：用户昵称
  local title = self.userData.name or "用户"
  -- 预览：个人简介
  local preview = self.userData.headline or ""
  if preview == "" then
    preview = "知乎用户"
  end

  HistoryService.add(self.userData.id, title, preview, "people")
end

function PeopleModel:follow(callback)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  self.userModel:setUserId(self.userId)
  self.userModel:follow(callback)
end

function PeopleModel:unfollow(callback)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  self.userModel:setUserId(self.userId)
  self.userModel:unfollow(callback)
end

function PeopleModel:block(callback)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  self.userModel:setUserId(self.userId)
  self.userModel:block(callback)
end

function PeopleModel:unblock(callback)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  self.userModel:setUserId(self.userId)
  self.userModel:unblock(callback)
end

-- 加载动态Tab配置
function PeopleModel:loadTabs(callback)
  local url = "https://api.zhihu.com/people/" .. self.userId .. "/profile/tab"

  self:fetch(url, { requestHeadKey = "app" }, function(success, response)
    local result = {}
    if success and response and response.tabs_v3 then
      for _, tab in ipairs(response.tabs_v3) do
        if tab.sub_tab then
          for _, sub in ipairs(tab.sub_tab) do
            if sub.name ~= "全部" and sub.key ~= "all" then
              local name = sub.name
              if sub.number and sub.number > 0 then
                name = name .. " " .. tostring(sub.number)
              end
              table.insert(result, { key = sub.key, name = name, url = sub.url })
            end
          end
         else
          if tab.name ~= "全部" and tab.key ~= "all" then
            local name = tab.name
            if tab.number and tab.number > 0 then
              name = name .. " " .. tostring(tab.number)
            end
            table.insert(result, { key = tab.key, name = name, url = tab.url })
          end
        end
      end
    end

    local baseId = self.urlToken or self.userId
    local urlMap = {
      activities = "https://www.zhihu.com/api/v3/moments/" .. self.userId .. "/activities?limit=20",
      answer = self:getAnswerUrl(),
      article = "https://www.zhihu.com/api/v4/members/" .. baseId .. "/articles?limit=20",
      zvideo = "https://www.zhihu.com/api/v4/members/" .. baseId .. "/zvideos?limit=20",
      pin = "https://api.zhihu.com/v2/pins/" .. self.userId .. "/moments",
      question = "https://www.zhihu.com/api/v4/members/" .. baseId .. "/questions?limit=20&ws_qiangzhisafe=0",
      column = "https://www.zhihu.com/api/v4/members/" .. baseId .. "/column-contributions?limit=20",
      more = "https://api.zhihu.com/people/" .. baseId .. "/profile/tab/more?tab_type=1",
    }

    local finalTabs = {}
    for _, t in ipairs(result) do
      local tabUrl = urlMap[t.key] or t.url
      if tabUrl then
        table.insert(finalTabs, { key = t.key, name = t.name, url = tabUrl })
      end
    end

    local activitiesIdx = nil
    for i, tab in ipairs(finalTabs) do
      if tab.key == "activities" then
        activitiesIdx = i
        break
      end
    end
    if activitiesIdx and activitiesIdx > 1 then
      local act = table.remove(finalTabs, activitiesIdx)
      table.insert(finalTabs, 1, act)
    end

    if #finalTabs == 0 then
      finalTabs = { { key = "activities", name = "动态", url = urlMap.activities } }
    end

    self.tabConfigs = {}
    self.urls = {}
    for _, tab in ipairs(finalTabs) do
      table.insert(self.tabConfigs, { key = tab.key, name = tab.name })
      self.urls[tab.key] = tab.url
      if tab.key == "answer" then
        self.answerKey = tab.key
      end
    end

    if callback then callback(self.tabConfigs) end
  end)
end

function PeopleModel:getTabConfigs()
  return self.tabConfigs
end

function PeopleModel:getInitialUrls()
  return self.urls
end

function PeopleModel:getDefaultActionText(contentType)
  local map = {
    answer = "发布了回答",
    question = "发布了问题",
    article = "发布了文章",
    column = "发布了专栏",
    pin = "发布了想法",
    zvideo = "发布了视频",
    topic = "关注了话题",
    roundtable = "关注了圆桌",
    special = "关注了专题",
  }
  return map[contentType] or "发布了内容"
end

function PeopleModel:parseItem(rawItem)
  if rawItem.more_tabs then
    local items = {}
    for _, tab in ipairs(rawItem.more_tabs) do
      local previewText = ""
      if tab.sub_title and tab.sub_title ~= "" then
        previewText = tab.sub_title .. "个内容 · "
      end
      table.insert(items, {
        id = "more_" .. tab.title,
        type = "more",
        title = tab.title,
        preview = previewText .. "点击查看",
        actionText = "的更多",
        avatarUrl = self.userData and self.userData.avatarUrl,
      })
    end
    return { items = items }
  end

  if rawItem.column then
    rawItem = rawItem.column
  end

  local actor = rawItem.actor or rawItem.author or {}
  local target = rawItem.target or rawItem
  local targetAuthor = target.author or {}

  local avatarUrl = targetAuthor.avatar_url or actor.avatar_url
  if not avatarUrl or avatarUrl == "" then
    avatarUrl = self.userData and self.userData.avatarUrl
  end

  local contentType = target.type == "moments_pin" and "pin" or target.type
  local actionText = rawItem.action_text or ""
  if rawItem.source and rawItem.source.action_text then
    actionText = rawItem.source.action_text
  end
  if actionText == "" then
    actionText = self:getDefaultActionText(contentType)
  end

  local id = target.id
  local title = ""

  if contentType == "answer" then
    id = target.id
    title = target.question and target.question.title or ""
   elseif contentType == "question" then
    id = target.id
    title = target.title or ""
   elseif contentType == "article" then
    id = target.id
    title = target.title or ""
   elseif contentType == "pin" then
    id = target.id
    title = target.excerpt_title or target.title or "一个想法"
   elseif contentType == "zvideo" then
    id = target.id
    title = target.title or ""
   elseif contentType == "column" then
    id = target.id
    title = target.title or target.name or ""
   elseif contentType == "topic" then
    id = target.id
    title = target.name or ""
   else
    return nil
  end

  local preview = target.excerpt or target.content_html or target.description
  if preview then
    preview = fromHtml(preview)
  end

  return {
    id = tostring(id),
    type = contentType,
    title = title,
    preview = preview,
    voteupCount = target.voteup_count or target.like_count,
    commentCount = target.comment_count or target.items_count,
    actionText = actionText,
    avatarUrl = avatarUrl,
  }
end

function PeopleModel:createAdapter(dataList)
  return SimpleRecyclerAdapter.new({
    items = dataList,
    getItemViewType = function(position, item)
      if not item.voteupCount and not item.commentCount then return 3 end
      if not item.voteupCount then return 1 end
      if not item.commentCount then return 2 end
      return 0
    end,
    onCreateView = function(viewType)
      return SimpleRecyclerAdapter.inflate(Layouts.cards.people_content)
    end,
    onBind = function(views, item, position, holder)
      views.action_text.text = item.actionText or ""
      views.title.text = item.title or ""

      local hasPreview = item.preview and item.preview ~= ""
      views.preview.text = item.preview or ""
      views.preview.visibility = hasPreview and View.VISIBLE or View.GONE

      local hasVoteup = item.voteupCount ~= nil
      views.like_count.text = tostring(item.voteupCount or 0)
      views.like_layout.visibility = hasVoteup and View.VISIBLE or View.GONE

      local hasComment = item.commentCount ~= nil
      views.comment_count.text = tostring(item.commentCount or 0)
      views.comment_layout.visibility = hasComment and View.VISIBLE or View.GONE

      Helpers.Image.load(views.avatar, item.avatarUrl)

      views.card.onClick = function()
        if item.type == "more" then
          Router.go("people_more", { id = self.userId, title = item.title }, { sharedElement = views.card })
         else
          Helpers.ZhihuParser.go(item.type, { id = item.id }, { sharedElement = views.card })
        end
      end
    end
  })
end

function PeopleModel:formatNumber(num)
  if not num then return "0" end
  if num >= 10000 then
    return string.format("%.1f万", num / 10000)
  end
  return tostring(num)
end

return PeopleModel