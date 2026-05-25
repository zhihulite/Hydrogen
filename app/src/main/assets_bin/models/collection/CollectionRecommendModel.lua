-- models/collection/CollectionRecommendModel.lua
-- 推荐收藏夹模型 - 使用 PageToolModel

local PageToolModel = require("models.base.PageToolModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

local CollectionRecommendModel = Extensions.Class(PageToolModel)
CollectionRecommendModel:chainUp("destroy")

function CollectionRecommendModel:ctor()
  self.requestHeadKey = "defaultHead"
  self.enableLoadMore = true
end

function CollectionRecommendModel:getInitialUrl()
  return "https://api.zhihu.com/explore/collections"
end

function CollectionRecommendModel:parseItem(rawItem)
  return {
    id = tostring(rawItem.id),
    title = rawItem.title,
    description = rawItem.description or "无介绍",
    itemCount = rawItem.item_count or 0,
    followerCount = rawItem.follower_count or 0,
    creatorName = rawItem.creator and rawItem.creator.name or "",
    avatarUrl = rawItem.creator and rawItem.creator.avatar_url or "",
  }
end

function CollectionRecommendModel:createAdapter(dataList)
  import "androidx.appcompat.widget.LinearLayoutCompat"
  import "com.google.android.material.textview.MaterialTextView"
  import "com.google.android.material.card.MaterialCardView"
  import "android.view.View"
  
  local colors = AppTheme.getColors()

  return SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.collection_recommend)
    end,
    onBind = function(views, item, position)
      views.title.text = item.title or ""
      views.description.text = item.description or ""
      views.creator.text = "由 " .. item.creatorName .. " 创建"
      views.stats.text = string.format("%d个内容 · %d关注", item.itemCount, item.followerCount)
      views.card.onClick = function()
        Router.go("collection", { id = item.id })
      end
    end,
  })
end

return CollectionRecommendModel