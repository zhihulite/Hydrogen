-- models/content/question_model.lua
-- 问题页面 - PageToolModel（包含详情 + 答案列表）

local PageToolModel = require("models.base.page_tool_model")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")

local QuestionModel = Extensions.Class(PageToolModel)

function QuestionModel:ctor(questionId)
  self.questionId = tostring(questionId)
  self.detailData = nil
  self.sortBy = "default"
  self.requestHeadKey = Constants.RequestHeadKeys.DEFAULT_HEAD
  self._historyRecorded = false -- 防止重复记录
  self._followPending = false -- 关注请求进行中，防止连点重复提交
end

function QuestionModel:getInitialUrl()
  return "https://www.zhihu.com/api/v4/questions/" .. self.questionId ..
  "/feeds?include=badge%5B*%5D.topics,comment_count,excerpt,voteup_count,created_time,updated_time,upvoted_followees,voteup_count,media_detail&limit=20" ..
  "&order=" .. self.sortBy .. "&ws_qiangzhisafe=0"
end

function QuestionModel:parseItem(rawItem)
  local target = Helpers.ZhihuItem.unwrap(rawItem)

  if target.excerpt == "" and target.media_detail and target.media_detail.videos then
    if #target.media_detail.videos > 0 then
      target.excerpt = "[视频]"
    end
  end

  return {
    id = target.id,
    title = target.author and target.author.name or "未知用户",
    preview = Helpers.ZhihuItem.excerptOf(target),
    voteupCount = Helpers.ZhihuItem.voteupOf(target),
    commentCount = target.comment_count or 0,
    avatarUrl = target.author and target.author.avatar_url,
  }
end

function QuestionModel:createAdapter(dataList)
  return SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.question_answer)
    end,
    onBind = function(views, item, position, holder)
      views.title.text = item.title
      views.preview.text = item.preview or ""
      views.like_count.text = tostring(item.voteupCount)
      views.comment_count.text = tostring(item.commentCount)
      Helpers.Image.load(views.avatar, item.avatarUrl)
      views.card.onClick = function()
        Helpers.ZhihuParser.go("answer", { id = item.id, questionId = self.questionId }, { sharedElement = views.card })
      end
    end,
  })
end

function QuestionModel:loadDetail(callback)
  local url = "https://www.zhihu.com/api/v4/questions/" .. self.questionId ..
  "?include=read_count,answer_count,comment_count,follower_count,detail,excerpt,author,relationship.is_following,topics"

  self:fetch(url, nil, function(success, response)
    if not success then
      if callback then callback(false) end
      return
    end

    self.detailData = {
      id = tostring(response.id),
      title = response.title,
      excerpt = response.excerpt,
      detail = response.detail,
      answerCount = response.answer_count or 0,
      commentCount = response.comment_count or 0,
      followerCount = response.follower_count or 0,
      isFollowing = response.relationship and response.relationship.is_following or false,
      author = Helpers.ZhihuItem.authorOf(response.author),
      topics = response.topics or {},
    }

    -- 记录历史记录（仅在首次加载详情成功后）
    if not self._historyRecorded then
      self:_recordHistory()
      self._historyRecorded = true
    end

    self:notifyListeners("detailChanged", self.detailData)
    if callback then callback(true, self.detailData) end
  end)
end

-- 添加到历史记录
function QuestionModel:_recordHistory()
  if not self.detailData then return end

  local title = self.detailData.title or ""
  if title == "" then
    title = "问题"
  end

  local preview = self.detailData.excerpt or self.detailData.detail or ""
  if preview == "" then
    preview = "问题详情"
  end

  HistoryService.add(self.questionId, title, preview, "question")
end

function QuestionModel:getDetail()
  return self.detailData
end

function QuestionModel:follow(callback)
  if not self:requireLogin(callback) then return end

  local url = "https://api.zhihu.com/questions/" .. self.questionId .. "/followers"

  -- 请求进行中直接拒绝，避免连点发出重复关注
  if self._followPending then
    if callback then callback(false) end
    return
  end
  self._followPending = true

  local function done(success)
    self._followPending = false
    if callback then callback(success) end
  end

  if self.detailData and self.detailData.isFollowing then
    self:delete(url, nil, function(success)
      if success and self.detailData then
        self.detailData.isFollowing = false
        self.detailData.followerCount = math.max(0, (self.detailData.followerCount or 1) - 1)
        self:notifyListeners("followChanged", self.detailData)
      end
      done(success)
    end)
   else
    self:post(url, "", nil, function(success)
      if success and self.detailData then
        self.detailData.isFollowing = true
        self.detailData.followerCount = (self.detailData.followerCount or 0) + 1
        self:notifyListeners("followChanged", self.detailData)
      end
      done(success)
    end)
  end
end

function QuestionModel:setSortBy(sortBy)
  self.sortBy = sortBy
  self:refresh()
end

function QuestionModel:destroy()
  self.detailData = nil
end

return QuestionModel