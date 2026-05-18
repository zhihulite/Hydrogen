-- models/content/ContentModel.lua
-- 内容模型 - BaseModel，支持文章、想法、视频、直播、圆桌、专题、离线内容

local BaseModel = require("models.base.BaseModel")

local ContentModel = Extensions.Class(BaseModel)
ContentModel:chainUp("destroy")

local contentTypes = {
  ["article"] = {
    apiUrl = "https://www.zhihu.com/api/v4/articles/",
    webUrl = "https://www.zhihu.com/appview/p/",
    shareUrl = "https://zhuanlan.zhihu.com/p/",
    typeKey = "article",
    allowFavorite = true,
  },
  ["pin"] = {
    apiUrl = "https://www.zhihu.com/api/v4/pins/",
    webUrl = "https://www.zhihu.com/appview/pin/",
    shareUrl = "https://www.zhihu.com/pin/",
    typeKey = "pin",
    allowFavorite = true,
  },
  ["zvideo"] = {
    apiUrl = "https://www.zhihu.com/api/v4/zvideos/",
    webUrl = "https://www.zhihu.com/zvideo/",
    shareUrl = "https://www.zhihu.com/zvideo/",
    typeKey = "zvideo",
    allowFavorite = true,
  },
  ["drama"] = {
    apiUrl = "https://api.zhihu.com/drama/theaters/",
    webUrl = "https://www.zhihu.com/theater/",
    shareUrl = "https://www.zhihu.com/theater/",
    typeKey = "drama",
    allowFavorite = false,
  },
  ["roundtable"] = {
    apiUrl = nil,
    webUrl = "https://www.zhihu.com/roundtable/",
    shareUrl = "https://www.zhihu.com/roundtable/",
    typeKey = "roundtable",
    allowFavorite = false,
  },
  ["special"] = {
    apiUrl = nil,
    webUrl = "https://www.zhihu.com/special/",
    shareUrl = "https://www.zhihu.com/special/",
    typeKey = "special",
    allowFavorite = false,
  }
}

function ContentModel:ctor(contentId, contentType)
  self.contentId = tostring(contentId)
  self.contentType = contentType or "article"
  self.typeInfo = contentTypes[self.contentType] or contentTypes["文章"]

  self.apiUrl = self.typeInfo.apiUrl and (self.typeInfo.apiUrl .. self.contentId) or nil
  self.webUrl = self.typeInfo.webUrl and (self.typeInfo.webUrl .. self.contentId) or nil

  -- 特殊处理
  if self.contentType == "article" then
    self.webUrl = self.webUrl .. "?use_hybrid_toolbar=1"
  end

  self.shareUrl = self.typeInfo.shareUrl and (self.typeInfo.shareUrl .. self.contentId) or nil

  self._historyRecorded = false
end

-- 检查是否允许收藏
function ContentModel:canFavorite()
  return self.typeInfo.allowFavorite == true
end

function ContentModel:parseResponse(response)
  local data = {
    id = tostring(response.id),
    type = self.typeInfo.typeKey,
    title = response.title or "",
    content = response.content,
    excerpt = response.excerpt or response.excerpt_title or "",
    voteupCount = response.voteup_count or 0,
    commentCount = response.comment_count or 0,
    webUrl = self.webUrl,
    shareUrl = self.shareUrl,
    allowFavorite = self:canFavorite(),
  }

  if self.contentType == "pin" then
    if response.content and #response.content > 0 then
      data.title = response.content[1].title or "一个想法"
    end
    data.voteupCount = response.reaction_count or response.like_count or 0
  end

  if data.title == "" then
    data.title = "无标题"
  end

  if response.author then
    data.author = {
      id = tostring(response.author.id),
      name = response.author.name,
      headline = response.author.headline,
      avatarUrl = response.author.avatar_url,
    }
  end

  return data
end

function ContentModel:load(params, callback)
  if not self.apiUrl then
    self.data = {
      id = self.contentId,
      type = self.typeInfo.typeKey,
      webUrl = self.webUrl,
      allowFavorite = self:canFavorite(),
    }
    self.isLoaded = true
    if callback then callback(true, self.data) end
    return
  end

  self:fetch(self.apiUrl, params, function(success, data)
    if success and data then
      data.allowFavorite = self:canFavorite()
      if not self._historyRecorded then
        self:_recordHistory(data)
        self._historyRecorded = true
      end
    end
    if callback then callback(success, data) end
  end)
end

-- 添加到历史记录
function ContentModel:_recordHistory(data)
  local title = data.title

  local preview = data.excerpt or "无预览内容"
  HistoryService.add(data.id, title, preview, data.type)
end

function ContentModel:getWebUrl()
  return self.data and self.data.webUrl
end

function ContentModel:getShareUrl()
  return self.data and self.data.shareUrl
end

function ContentModel:getAuthor()
  return self.data and self.data.author
end

return ContentModel