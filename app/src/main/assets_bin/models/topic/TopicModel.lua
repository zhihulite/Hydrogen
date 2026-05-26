-- models/topic/TopicModel.lua
-- 话题详情 - PageToolModel（多Tab，第一页固定头部）

local PageToolModel = require("models.base.PageToolModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

local TopicModel = Extensions.Class(PageToolModel)
TopicModel:chainUp("destroy")

-- 排序映射表
local SORT_MAP = {
  essence = {
    essence = "essence",
    new = "timeline_activity",
    hot = "top_activity",
  },
  pin = {
    new = "pin-new",
    hot = "pin-hot",
  },
  zvideo = {
    new = "new_zvideo",
    hot = "top_zvideo",
  },
  question = {
    new = "new_question",
    hot = "top_question",
  },
}

function TopicModel:ctor(topicId)
  self.topicId = tostring(topicId)
  self.requestHeadKey = "defaultHead"
  self.needLogin = false
  self.topicInfo = nil
  self.detailViews = nil
  self.currentSort = {}
  self.tabConfigs = {
    { key = "detail", name = "详情" },
    { key = "essence", name = "讨论" },
    { key = "pin", name = "想法" },
    { key = "zvideo", name = "视频" },
    { key = "question", name = "问题" },
  }
  self.prePageCount = 1
  self.prePageCreator = function(key, idx)
    if key == "detail" then
      return self:createDetailPage()
    end
    return nil
  end

  self.currentSort["essence"] = "essence"
  self.currentSort["pin"] = "new"
  self.currentSort["zvideo"] = "new"
  self.currentSort["question"] = "new"
end

function TopicModel:setSort(key, sortType)
  if not SORT_MAP[key] or not SORT_MAP[key][sortType] then
    return
  end
  self.currentSort[key] = sortType
  if self.pageTool then
    self.pageTool:refresh(key)
  end
end

function TopicModel:getCurrentSort(key)
  return self.currentSort[key] or "new"
end

function TopicModel:createDetailPage()
  local detailViews = {}
  local view = loadlayout(Layouts.pages.topic.detail, detailViews)
  self.detailViews = detailViews
  if self.topicInfo then
    self:updateDetailPage(self.topicInfo)
  end
  return view
end

function TopicModel:getDetailViews()
  return self.detailViews
end

function TopicModel:updateDetailPage(topicInfo)
  local views = self.detailViews
  if not views then return end
  Helpers.Image.load(views.detail_avatar, topicInfo.avatarUrl)
  views.detail_name.text = topicInfo.name
  views.detail_intro.text = topicInfo.introduction
  views.detail_followers.text = self:formatNumber(topicInfo.followersCount)
  views.detail_questions.text = self:formatNumber(topicInfo.questionsCount)
  views.detail_best_answers.text = self:formatNumber(topicInfo.bestAnswersCount)
end

function TopicModel:loadTopicInfo(callback)
  local url = "https://www.zhihu.com/api/v5.1/topics/" .. self.topicId

  self:fetch(url, nil, function(success, response)
    if not success then
      if callback then callback(false, nil) end
      return
    end

    self.topicInfo = {
      id = tostring(response.id),
      name = response.name,
      introduction = response.introduction or "",
      avatarUrl = response.avatar_url,
      followersCount = response.followers_count or 0,
      questionsCount = response.questions_count or 0,
      bestAnswersCount = response.best_answers_count or 0,
    }

    self:updateDetailPage(self.topicInfo)
    self:notifyListeners("topicInfoChanged", self.topicInfo)

    if callback then callback(true, self.topicInfo) end
  end)
end

function TopicModel:getTopicInfo()
  return self.topicInfo
end

function TopicModel:getTabConfigs()
  return self.tabConfigs
end

function TopicModel:getInitialUrls()
  local baseUrl = "https://www.zhihu.com/api/v5.1/topics/" .. self.topicId .. "/feeds/"

  local essenceSort = SORT_MAP["essence"][self.currentSort["essence"]] or "essence"
  local pinSort = SORT_MAP["pin"][self.currentSort["pin"]] or "pin-new"
  local zvideoSort = SORT_MAP["zvideo"][self.currentSort["zvideo"]] or "top_zvideo"
  local questionSort = SORT_MAP["question"][self.currentSort["question"]] or "top_question"

  return {
    essence = baseUrl .. essenceSort .. "/v2",
    pin = baseUrl .. pinSort .. "/v2",
    zvideo = baseUrl .. zvideoSort .. "/v2",
    question = baseUrl .. questionSort .. "/v2",
  }
end

function TopicModel:parseItem(rawItem, key)
  local target = rawItem.target or rawItem

  local name = ""
  pcall(function()
    name = target.author.name
  end)

  local excerpt = target.excerpt or ""
  local preview = name ~= "" and (name .. " : " .. excerpt) or excerpt

  local title = ""
  local id = ""
  local bottomText

  if target.type == "answer" then
    title = target.question and target.question.title or ""
    id = tostring(target.id)
   elseif target.type == "question" then
    title = target.title or ""
    id = tostring(target.id)
    bottomText = (target.answer_count or 0) .. "个回答 · " .. (target.follower_count or 0) .. "人关注"
    preview = nil
   elseif target.type == "article" then
    title = target.title or ""
    id = tostring(target.id)
   elseif target.type == "zvideo" then
    title = target.title or ""
    id = tostring(target.id)
    if excerpt == "" then
      preview = name .. " : [视频]"
    end
   elseif target.type == "pin" then
    title = target.title ~= nil and target.title ~= "" and target.title or "一个想法"
    id = tostring(target.id)
    pcall(function()
      if target.content and target.content[1] then
        preview = fromHtml(target.content[1].content)
      end
    end)
   else
    return nil
  end

  local voteupCount = target.voteup_count or target.like_count or 0
  local commentCount = target.comment_count or 0

  return {
    id = id,
    type = target.type,
    title = title,
    preview = preview,
    voteupCount = voteupCount,
    commentCount = commentCount,
    bottomText = bottomText,
  }
end

function TopicModel:createAdapter(dataList, key)
  return SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.topic)
    end,
    onBind = function(views, item, position, holder)
      views.title.text = item.title

      local hasPreview = item.preview and item.preview ~= ""
      views.preview.text = item.preview or ""
      views.preview.visibility = hasPreview and View.VISIBLE or View.GONE

      local hasBottom = item.bottomText ~= nil
      views.bottom_text.text = item.bottomText or ""
      views.bottom_text.visibility = hasBottom and View.VISIBLE or View.GONE

      if hasBottom then
        views.stats_layout.visibility = View.GONE
       else
        views.stats_layout.visibility = View.VISIBLE
        views.voteup_count.text = tostring(item.voteupCount)
        views.comment_count.text = tostring(item.commentCount)
      end

      views.card.onClick = function()
        Helpers.ZhihuParser.go(item.type, { id = item.id }, { sharedElement = views.card })
      end
    end
  })
end

function TopicModel:onTabSelected(key)
  self:notifyListeners("tabSelected", key)
end

function TopicModel:formatNumber(num)
  if not num then return "0" end
  if num >= 10000 then
    return string.format("%.1f万", num / 10000)
  end
  return tostring(num)
end

function TopicModel:destroy()
  self.topicInfo = nil
  self.detailViews = nil
end

return TopicModel