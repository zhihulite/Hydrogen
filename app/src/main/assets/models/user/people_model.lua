-- models/user/people_model.lua
-- 用户主页 - PageToolModel

local PageToolModel = require("models.base.page_tool_model")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
local UserModel = require("models.user.user_model")

local PeopleModel = Extensions.Class(PageToolModel)

-- 回答排序选项
local ANSWER_SORT_OPTIONS = {
  { name = "时间", order_by = "created" },
  { name = "赞同", order_by = "voteup_count" },
}

-- 动态流可解析的内容类型白名单，其余类型返回 nil 由分页框架跳过
local PARSEABLE_TYPES = {
  answer = true, question = true, article = true, pin = true,
  zvideo = true, column = true, topic = true,
}

function PeopleModel:ctor(userId)
  self.requestHeadKey = Constants.RequestHeadKeys.APP
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

-- 用户信息由 UserModel 拉取，本模型只负责转发结果与记录历史
function PeopleModel:loadUserInfo(callback)
  self.userModel:setUserId(self.userId)
  self.userModel:load(nil, function(success, data)
    if not success then
      if callback then callback(false) end
      return
    end

    self.userId = data.id
    self.urlToken = data.urlToken
    self.userData = data

    -- 记录历史记录（仅在首次加载成功后）
    if not self._historyRecorded then
      self:_recordHistory()
      self._historyRecorded = true
    end

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

-- 关注/拉黑等用户操作转发到 UserModel，登录校验与提示在 UserModel 内完成
local function delegateToUser(action)
  return function(self, callback)
    if not self.userModel then
      if callback then callback(false) end
      return
    end

    self.userModel:setUserId(self.userId)
    self.userModel[action](self.userModel, callback)
  end
end

PeopleModel.follow = delegateToUser("follow")
PeopleModel.unfollow = delegateToUser("unfollow")
PeopleModel.block = delegateToUser("block")
PeopleModel.unblock = delegateToUser("unblock")

-- 加载动态Tab配置
function PeopleModel:loadTabs(callback)
  local url = "https://api.zhihu.com/people/" .. self.userId .. "/profile/tab"

  self:fetch(url, { requestHeadKey = Constants.RequestHeadKeys.APP }, function(success, response)
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
  local target = Helpers.ZhihuItem.unwrap(rawItem)
  local targetAuthor = target.author or {}

  local avatarUrl = targetAuthor.avatar_url or actor.avatar_url
  if not avatarUrl or avatarUrl == "" then
    avatarUrl = self.userData and self.userData.avatarUrl
  end

  local contentType = Helpers.ZhihuItem.normalizeType(target.type)
  local actionText = rawItem.action_text or ""
  if rawItem.source and rawItem.source.action_text then
    actionText = rawItem.source.action_text
  end
  if actionText == "" then
    actionText = self:getDefaultActionText(contentType)
  end

  if not PARSEABLE_TYPES[contentType] then
    return nil
  end

  local title = Helpers.ZhihuItem.titleOf(target)

  -- 预览依序取 excerpt、content_html、description，命中后经 fromHtml 反转义
  local preview = Helpers.ZhihuItem.excerptOf(target)
  or (target.content_html and fromHtml(target.content_html))
  or (target.description and fromHtml(target.description))

  return {
    id = tostring(target.id),
    type = contentType,
    title = title,
    preview = preview,
    -- 点赞区靠 voteupCount 为 nil 判断是否隐藏，无赞同字段的类型不能填 0 兜底
    voteupCount = (target.voteup_count or target.like_count) and Helpers.ZhihuItem.voteupOf(target),
    commentCount = target.comment_count or target.items_count,
    actionText = actionText,
    avatarUrl = avatarUrl,
  }
end

function PeopleModel:createAdapter(dataList)
  return SimpleRecyclerAdapter.new({
    items = dataList,
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

return PeopleModel