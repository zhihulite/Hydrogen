-- models/user/PeopleMoreModel.lua
-- 用户更多内容 - PageToolModel（支持分页）

local PageToolModel = require("models.base.PageToolModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

local PeopleMoreModel = Extensions.Class(PageToolModel)

function PeopleMoreModel:ctor(userId, moreType)
  self.userId = tostring(userId)
  self.moreType = moreType or ""
  self.requestHeadKey = "app"
  self.needLogin = false
end

function PeopleMoreModel:getInitialUrl()
  if self.moreType:find("视频合集") then
    if self.moreType:find("详情") then
      return "https://api.zhihu.com/zvideo-collections/collections/" .. self.userId .. "/include?limit=10&include=answer"
     else
      return "https://api.zhihu.com/zvideo-collections/members/" .. self.userId .. "/collections?limit=10"
    end
  end

  if self.moreType:find("划线") then
    return "https://www.zhihu.com/api/v4/members/" .. self.userId .. "/segments?limit=10"
  end

  local typeMap = {
    ["专栏"] = "columns",
    ["话题"] = "topics",
    ["提问"] = "questions",
    ["圆桌"] = "roundtables",
    ["专题"] = "news_specials",
  }

  for name, key in pairs(typeMap) do
    if self.moreType:find(name) then
      return "https://api.zhihu.com/people/" .. self.userId .. "/following_" .. key .. "?limit=20"
    end
  end

  return ""
end

function PeopleMoreModel:parseItem(rawItem)
  if self.moreType:find("视频合集") then
    return self:parseVideoItem(rawItem)
   elseif self.moreType:find("划线") then
    return self:parseUnderlineItem(rawItem)
   elseif self.moreType:find("专栏") then
    return self:parseColumnItem(rawItem)
   elseif self.moreType:find("话题") then
    return self:parseTopicItem(rawItem)
   elseif self.moreType:find("问题") then
    return self:parseQuestionItem(rawItem)
   elseif self.moreType:find("圆桌") then
    return self:parseRoundtableItem(rawItem)
   elseif self.moreType:find("专题") then
    return self:parseSpecialItem(rawItem)
  end

  return self:parseDefaultItem(rawItem)
end

function PeopleMoreModel:parseUnderlineItem(rawItem)
  local source = rawItem.source_content or {}
  local reaction = rawItem.reaction or {}

  return {
    id = tostring(rawItem.id),
    type = "underline",
    title = rawItem.content or "",
    preview = source.title or "",
    bottomText = (source.voteup_count or 0) .. " 赞同 · " .. (reaction.like_count or 0) .. " 划线赞同",
    sourceId = source.id,
    sourceType = source.type,
    token = source.token,
    url = source.url
  }
end

function PeopleMoreModel:parseVideoItem(target)
  if self.moreType:find("详情") then
    return {
      id = tostring(target.id),
      type = "zvideo",
      title = target.title or "",
      preview = target.description or "",
      bottomText = (target.play_count or 0) .. "个播放",
    }
   else
    return {
      id = tostring(target.id),
      type = "video_collection",
      title = target.name or "",
      preview = target.description or "",
      bottomText = string.format("%d个视频 · %d个赞同", target.zvideo_count or 0, target.voteup_count or 0),
    }
  end
end

function PeopleMoreModel:parseColumnItem(target)
  return {
    id = tostring(target.id),
    type = "column",
    title = target.title or "",
    preview = target.description or "",
    bottomText = string.format("%d篇内容 · %d个赞同", target.items_count or 0, target.voteup_count or 0),
  }
end

function PeopleMoreModel:parseTopicItem(target)
  return {
    id = tostring(target.id),
    type = "topic",
    title = target.name or "",
    preview = target.excerpt or target.description or "",
  }
end

function PeopleMoreModel:parseQuestionItem(target)
  return {
    id = tostring(target.id),
    type = "question",
    title = target.title or "",
    bottomText = string.format("%d个回答 · %d个关注", target.answer_count or 0, target.follower_count or 0),
  }
end

function PeopleMoreModel:parseRoundtableItem(target)
  return {
    id = tostring(target.id),
    type = "roundtable",
    title = target.name or "",
    preview = target.description or "",
  }
end

function PeopleMoreModel:parseSpecialItem(target)
  return {
    id = tostring(target.id),
    type = "special",
    title = target.title or "",
    preview = target.description or "",
  }
end

function PeopleMoreModel:parseDefaultItem(target)
  return {
    id = tostring(target.id),
    type = target.type or "unknown",
    title = target.title or target.name or "",
    preview = target.description or target.excerpt or "",
  }
end

function PeopleMoreModel:createAdapter(dataList)
  return SimpleRecyclerAdapter.new({
    items = dataList,
    getItemViewType = function(position, item)
      if self.moreType:find("划线") then return 1 end
      return 0
    end,
    onCreateView = function(viewType)
      if viewType == 1 then
        return SimpleRecyclerAdapter.inflate(Layouts.cards.underline)
       else
        return SimpleRecyclerAdapter.inflate(Layouts.cards.people_more)
      end
    end,
    onBind = function(views, item, position, holder)
      if self.moreType:find("划线") then
        views.content.text = item.title or ""
        views.source_title.text = item.preview or ""
        views.bottom_text.text = item.bottomText or ""

        views.card.onClick = function()
          Helpers.ZhihuParser.goUrl(item.url, { sharedElement = views.card })
        end
       else
        views.title.text = item.title or ""

        local hasPreview = item.preview and item.preview ~= ""
        views.preview.text = item.preview or ""
        views.preview.visibility = hasPreview and View.VISIBLE or View.GONE

        local hasBottomText = item.bottomText ~= nil
        views.bottom_text.text = item.bottomText or ""
        views.bottom_text.visibility = hasBottomText and View.VISIBLE or View.GONE

        views.card.onClick = function()
          if item.type == "video_collection" then
            Router.go("people_more", { id = item.id, title = "视频合集详情" }, { sharedElement = views.card })
           else
            Helpers.ZhihuParser.go(item.type, { id = item.id }, { sharedElement = views.card })
          end
        end
      end
    end,
  })
end

return PeopleMoreModel