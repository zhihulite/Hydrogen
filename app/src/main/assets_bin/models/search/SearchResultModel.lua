-- models/search/SearchResultModel.lua
-- 搜索结果 - PageToolModel

local PageToolModel = require("models.base.PageToolModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

local SearchResultModel = Extensions.Class(PageToolModel)
SearchResultModel:chainUp("destroy")

function SearchResultModel:ctor(keyword, searchType, extraId)
  self.keyword = keyword
  self.searchType = searchType or "general"
  self.extraId = extraId
  self.requestHeadKey = "defaultHead"
  self.needLogin = false
end

function SearchResultModel:getInitialUrl()
  local keyword = NetWork.urlEncode(self.keyword)

  if self.searchType == "people" and self.extraId then
    return string.format(
    "https://www.zhihu.com/api/v4/search_v3?correction=1&t=general&q=%s&restricted_scene=member&restricted_field=member_hash_id&restricted_value=%s",
    keyword, self.extraId
    )
   elseif self.searchType == "collection" then
    return string.format(
    "https://www.zhihu.com/api/v4/search_v3?q=%s&t=favlist",
    keyword
    )
   else
    return string.format(
    "https://www.zhihu.com/api/v4/search_v3?q=%s&t=general",
    keyword
    )
  end
end

function SearchResultModel:parseItem(rawItem)
  local target = rawItem.object or rawItem

  local actionText = ""
  local title = target.excerpt_title or target.title or ""

  if target.type == "answer" then
    actionText = "添加了回答"
   elseif target.type == "question" then
    actionText = "添加了问题"
   elseif target.type == "article" then
    actionText = "添加了文章"
   elseif target.type == "pin" or target.type == "pin_general" then
    actionText = "添加了想法"
   elseif target.type == "zvideo" then
    actionText = "添加了视频"
   elseif target.type == "topic" then
    actionText = "添加了话题"
    title = target.name
   elseif target.type == "column" then
    actionText = "添加了专栏"
   else
    actionText = "添加了内容"
  end

  return {
    id = tostring(target.id),
    type = target.type,
    title = fromHtml(title or ""),
    preview = target.excerpt and fromHtml(target.excerpt) or "无",
    voteupCount = target.voteup_count or 0,
    commentCount = target.comment_count or 0,
    actionText = actionText,
  }
end

function SearchResultModel:createAdapter(dataList)
  return SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.search_result)
    end,
    onBind = function(views, item, position, holder)
      views.action_text.text = item.actionText or ""
      if views.title then views.title.text = item.title or ""
        views.preview.text = item.preview or ""
      end
      views.like_count.text = tostring(item.voteupCount)
      views.comment_count.text = tostring(item.commentCount)
      views.card.onClick = function()
        Helpers.ZhihuParser.go(item.type, { id = item.id }, { sharedElement = views.card })
      end
    end,
  })
end

return SearchResultModel