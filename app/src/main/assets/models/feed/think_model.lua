-- models/feed/think_model.lua
-- 想法流 - PageToolModel

local PageToolModel = require("models.base.page_tool_model")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")

local ThinkModel = Extensions.Class(PageToolModel)

function ThinkModel:ctor()
  self.requestHeadKey = Constants.RequestHeadKeys.DEFAULT_HEAD
  self.needLogin = false
end

function ThinkModel:getInitialUrl()
  return string.format("https://api.zhihu.com/prague/feed")
end

function ThinkModel:parseItem(rawItem)
  local target = Helpers.ZhihuItem.unwrap(rawItem)
  if not target.id then return nil end

  local statistics = target.reaction and target.reaction.statistics or {}

  local imageUrl = nil
  pcall(function()
    imageUrl = target.images and target.images[1] and target.images[1].url
    if not imageUrl and target.video then
      imageUrl = target.video.thumbnail
    end
  end)

  local title = target.excerpt or ""
  title = title:gsub("<[^>]+>", "")
  if title == "" then title = "一个想法" end

  return {
    id = tostring(target.id),
    type = "pin",
    title = title,
    imageUrl = imageUrl,
    voteupCount = Helpers.ZhihuItem.voteupOf(target),
    commentCount = statistics.comment_count or 0,
  }
end

function ThinkModel:createAdapter(dataList)
  return SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.think)
    end,
    onBind = function(views, item, position, holder)
      views.title.text = item.title or ""
      views.like_count.text = tostring(item.voteupCount)
      views.comment_count.text = tostring(item.commentCount)
      if item.imageUrl then
        Helpers.Image.load(views.image, item.imageUrl)
        views.image.visibility = View.VISIBLE
       else
        views.image.visibility = View.GONE
      end
      views.card.onClick = function()
        Router.go("content", { id = item.id, type = "pin" }, { sharedElement = views.card })
      end
    end,
  })
end

return ThinkModel