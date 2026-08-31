-- models/search/search_result_model.lua
-- 搜索结果 - PageToolModel

local PageToolModel = require("models.base.page_tool_model")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")

local SearchResultModel = Extensions.Class(PageToolModel)

-- 可跳转类型白名单，与 Helpers.ZhihuParser.go 支持的类型一致
local ROUTABLE_TYPES = {
  answer = true, question = true, collection = true, article = true,
  pin = true, zvideo = true, roundtable = true, special = true,
  drama = true, topic = true, people = true, column = true,
}

function SearchResultModel:ctor(keyword, searchType, extraId)
  self.keyword = keyword
  self.searchType = searchType or "general"
  self.extraId = extraId
  self.requestHeadKey = Constants.RequestHeadKeys.DEFAULT_HEAD
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
  local target = Helpers.ZhihuItem.unwrap(rawItem)

  -- 归一化类型后过滤掉不可跳转的条目，返回 nil 由 processParseResult 跳过
  local itemType = Helpers.ZhihuItem.normalizeType(target.type)
  if not ROUTABLE_TYPES[itemType] then return nil end

  local actionText = ""
  local title = target.excerpt_title or target.title or ""
  local preview = Helpers.ZhihuItem.excerptOf(target) or "无"

  if itemType == "people" then
    actionText = "用户"
    title = target.name or ""
    preview = target.headline and target.headline ~= "" and target.headline or "无签名"
   elseif itemType == "answer" then
    actionText = "添加了回答"
   elseif itemType == "question" then
    actionText = "添加了问题"
   elseif itemType == "article" then
    actionText = "添加了文章"
   elseif itemType == "pin" then
    actionText = "添加了想法"
   elseif itemType == "zvideo" then
    actionText = "添加了视频"
   elseif itemType == "topic" then
    actionText = "添加了话题"
    title = target.name
   elseif itemType == "column" then
    actionText = "添加了专栏"
   else
    actionText = "添加了内容"
  end

  return {
    id = tostring(target.id),
    type = itemType,
    title = fromHtml(title or ""),
    preview = preview,
    voteupCount = Helpers.ZhihuItem.voteupOf(target),
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
      views.title.text = item.title or ""
      views.preview.text = item.preview or ""
      views.like_count.text = tostring(item.voteupCount)
      views.comment_count.text = tostring(item.commentCount)
      views.card.onClick = function()
        Helpers.ZhihuParser.go(item.type, { id = item.id }, { sharedElement = views.card })
      end
    end,
  })
end

return SearchResultModel