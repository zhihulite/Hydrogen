-- models/feed/ThinkModel.lua
-- 想法流 - PageToolModel

local PageToolModel = require("models.base.PageToolModel")
local SimpleAdapter = require("components.adapter.SimpleRecyclerAdapter")

local ThinkModel = Extensions.Class(PageToolModel)
ThinkModel:chainUp("destroy")

function ThinkModel:ctor()
  self.requestHeadKey = "defaultHead"
  self.needLogin = false
end

function ThinkModel:getInitialUrl()
  return string.format("https://api.zhihu.com/prague/feed")
end

function ThinkModel:parseItem(rawItem)
  local target = rawItem.target or {}

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
    voteupCount = target.reaction and target.reaction.statistics.up_vote_count or 0,
    commentCount = target.reaction and target.reaction.statistics.comment_count or 0,
  }
end

function ThinkModel:createAdapter(dataList)
  local selfRef = self

  return SimpleAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleAdapter.inflate(Layouts.cards.think)
    end,
    onBind = function(views, item, position, holder)
      views.title.text = item.title or ""
      views.like_count.text = tostring(item.voteupCount)
      views.comment_count.text = tostring(item.commentCount)
      if item.imageUrl then
        Helpers.Image.load(views.image, item.imageUrl)
        views.image.setVisibility(View.VISIBLE)
       else
        views.image.setVisibility(View.GONE)
      end
      views.card.onClick = function()
        Router.go("content", { id = item.id, type = "pin" }, { sharedElement = views.card })
      end
    end,
  })
end

return ThinkModel