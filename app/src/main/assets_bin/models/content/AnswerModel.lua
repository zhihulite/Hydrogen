-- models/content/AnswerModel.lua
-- 回答详情 - BaseModel（纯数据层，不涉及 UI）

local BaseModel = require("models.base.BaseModel")

local AnswerModel = Extensions.Class(BaseModel)
AnswerModel:chainUp("destroy")

function AnswerModel:ctor(answerId)
  self.answerId = tostring(answerId)
  self.pageInfo = {}
  self.usedIds = {}
  self.isLeft = false
  self.isRight = false
  self._historyRecorded = false -- 防止重复记录
end

-- 获取问题信息
function AnswerModel:getQuestionInfo(callback)
  local include = '?include=question.answer_count,question.visit_count,question.comment_count'
  local url = "https://www.zhihu.com/api/v4/answers/" .. self.answerId .. include
  self:fetch(url, nil, function(success, response)
    if success and response and response.question then
      callback(response.question)
     else
      callback(nil)
    end
  end)
end

-- BaseModel 要求实现
function AnswerModel:load(params, callback)
  self:loadAnswer(self.answerId, callback)
end

-- 加载回答详情
function AnswerModel:loadAnswer(answerId, callback, silent)
  local include = '?include=author,content,voteup_count,comment_count,favlists_count,thanks_count,is_author,is_thanked,voting,is_favorited,pagination_info,excerpt,attachment'
  local url = "https://www.zhihu.com/api/v4/answers/" .. tostring(answerId) .. include

  self:fetch(url, nil, function(success, response)
    if not success then
      if not silent then self:setError("加载失败") end
      if callback then callback(false, nil) end
      return
    end

    local data = {
      id = tostring(response.id),
      content = response.content,
      excerpt = response.excerpt,
      voteupCount = response.voteup_count or 0,
      commentCount = response.comment_count or 0,
      thanksCount = response.thanks_count or 0,
      favlistsCount = response.favlists_count or 0,
      isAuthor = response.relationship and response.relationship.is_author or false,
      isLiked = response.relationship and response.relationship.voting == 1,
      isThanked = response.relationship and response.relationship.is_thanked or false,
      isFavorited = response.relationship and response.relationship.is_favorited or false,
      author = response.author and {
        id = tostring(response.author.id),
        name = response.author.name,
        headline = response.author.headline,
        avatarUrl = response.author.avatar_url,
      } or nil,
      question = response.question and {
        id = tostring(response.question.id),
        title = response.question.title,
        answerCount = response.question.answer_count,
      } or nil,
      attachmentUrl = (function()
        local playlist = response.attachment and response.attachment.video and
        response.attachment.video.video_info and
        response.attachment.video.video_info.playlist
        if playlist then
          return (playlist.sd or playlist.ld or playlist.hd).url
        end
        return nil
      end)(),
    }

    -- 记录历史记录（仅在首次加载成功后）
    if not self._historyRecorded then
      self:_recordHistory(data)
      self._historyRecorded = true
    end

    if response.pagination_info then
      self.pageInfo[tostring(answerId)] = {
        prevIds = response.pagination_info.prev_answer_ids or {},
        nextIds = response.pagination_info.next_answer_ids or {},
      }
      self:updateLR()
    end

    if callback then callback(true, data) end
  end)
end

-- 添加到历史记录
function AnswerModel:_recordHistory(data)
  -- 标题：问题标题
  local title = (data.question and data.question.title ~= "") and data.question.title or "回答"

  -- 预览：作者名: 预览内容
  local authorName = data.author and data.author.name or "未知用户"
  local previewContent = data.excerpt or ""
  if previewContent == "" and data.content then
    previewContent = data.content
  end
  if previewContent == "" then
    previewContent = "回答内容"
  end
  
  local preview = authorName .. ": " .. previewContent

  HistoryService.add(data.id, title, preview, "answer")
end

-- 更新左右边界状态
function AnswerModel:updateLR()
  local info = self.pageInfo[tostring(self.answerId)]
  if info then
    self.isLeft = #(info.prevIds or {}) == 0
    self.isRight = #(info.nextIds or {}) == 0
  end
end

-- 获取上一个/下一个回答 ID（跳过已使用的）
function AnswerModel:getNextId(isPrev, fromId)
  local baseId = tostring(fromId or self.answerId)
  local info = self.pageInfo[baseId]
  if info then
    local ids = isPrev and info.prevIds or info.nextIds
    if ids and #ids > 0 then
      for _, id in ipairs(ids) do
        local sid = tostring(id)
        if not self.usedIds[sid] then
          return sid
        end
      end
    end
  end
  return nil
end

function AnswerModel:getPrevAnswerId(fromId)
  return self:getNextId(true, fromId)
end

function AnswerModel:getNextAnswerId(fromId)
  return self:getNextId(false, fromId)
end

function AnswerModel:markUsed(answerId)
  self.usedIds[tostring(answerId)] = true
end

function AnswerModel:setCurrentId(answerId)
  self.answerId = tostring(answerId)
  self:updateLR()
end

function AnswerModel:isAtLeft()
  return self.isLeft
end

function AnswerModel:isAtRight()
  return self.isRight
end

-- 递归获取上一个/下一个回答（跳过已使用）
function AnswerModel:getOneData(callback, isPrev, depth)
  depth = (depth or 0) + 1
  if depth > 10 then
    callback(false)
    return
  end

  local currentId = tostring(self.answerId)
  local nextId = self:getNextId(isPrev, currentId)

  if not nextId then
    callback(false)
    return
  end

  local originalId = self.answerId
  self.answerId = nextId

  self:loadAnswer(nextId, function(success, data)
    if not success then
      local info = self.pageInfo[currentId]
      if info then
        if isPrev then
          table.remove(info.prevIds, #info.prevIds)
         else
          table.remove(info.nextIds, 1)
        end
      end
      self.answerId = originalId
      self:getOneData(callback, isPrev, depth)
     else
      self.answerId = originalId
      callback(data)
    end
  end, true)

  return nextId
end

-- 点赞/取消点赞
function AnswerModel:like(answerId, isCurrentlyLiked, callback)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  local isUp = not isCurrentlyLiked
  local typeStr = isUp and "up" or "neutral"
  local url = "https://api.zhihu.com/answers/" .. tostring(answerId) .. "/voters"

  self:post(url, '{"type":"' .. typeStr .. '"}', { requestHeadKey = "post" } , function(success)
    if callback then callback(success, isUp) end
  end)
end

-- 感谢/取消感谢
function AnswerModel:thank(answerId, isCurrentlyThanked, callback)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  local isThank = not isCurrentlyThanked
  local url = "https://www.zhihu.com/api/v4/zreaction"

  if isThank then
    local data = '{"content_type":"answers","content_id":"' .. tostring(answerId) ..
    '","action_type":"emojis","action_value":"red_heart"}'
    self:post(url, data, { requestHeadKey = "post" } , function(success)
      if callback then callback(success, isThank) end
    end)
   else
    local deleteUrl = url .. "?content_type=answers&content_id=" .. tostring(answerId).. "&action_type=emojis&action_value="
    self:delete(deleteUrl, { requestHeadKey = "post" } , function(success)
      if callback then callback(success, isThank) end
    end)
  end
end

function AnswerModel:destroy()
  self.pageInfo = nil
  self.usedIds = nil
end

return AnswerModel