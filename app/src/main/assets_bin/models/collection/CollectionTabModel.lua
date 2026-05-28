-- models/collection/CollectionTabModel.lua
-- 收藏夹Tab页（我的收藏/关注的收藏）- 使用 PageToolModel 多页模式

local PageToolModel = require("models.base.PageToolModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

local CollectionTabModel = Extensions.Class(PageToolModel)

local TAB_CONFIGS = {
  { name = "收藏", key = "created" },
  { name = "关注", key = "followed" },
}

local EMPTY_FOLLOWING_DATA = {
  id = "empty_following",
  type = "empty",
  title = "推荐收藏夹",
  preview = "为你推荐",
  itemCount = 0,
  followerCount = 0,
  isPublic = true,
  creator = { name = "知乎" },
}

function CollectionTabModel:ctor(userId)
  self.requestHeadKey = "defaultHead"
  self.needLogin = true
  self.userId = userId or Extensions.Config.get(Constants.SharedDataKeys.USER_ID)
  self.tabConfigs = {
    { key = "created", name = "收藏" },
    { key = "followed", name = "关注" },
  }
end

function CollectionTabModel:setUserId(userId)
  self.userId = userId
end

function CollectionTabModel:getTabConfigs()
  return self.tabConfigs
end

function CollectionTabModel:getInitialUrls()
  if not self.userId then return {} end
  return {
    created = "https://api.zhihu.com/people/" .. self.userId .. "/collections_v2?limit=20",
    followed = "https://api.zhihu.com/people/" .. self.userId .. "/following_collections?limit=20",
  }
end

function CollectionTabModel:parseItem(rawItem)
  local collection = rawItem.collection or rawItem
  return {
    id = tostring(collection.id),
    type = "collection",
    title = collection.title,
    preview = collection.description or "",
    itemCount = collection.item_count or 0,
    followerCount = collection.follower_count or 0,
    isPublic = collection.is_public,
    isDefault = collection.is_default or false,
    isFollowing = collection.is_following or false,
    creator = collection.creator and {
      id = tostring(collection.creator.id),
      name = collection.creator.name,
      avatarUrl = collection.creator.avatar_url,
    } or nil,
  }
end

function CollectionTabModel:createAdapter(dataList)
  return SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.collection_tab)
    end,
    onBind = function(views, item, position, holder)
      if item.isDefault then
        views.title.text = item.title .. " (默认)"
       else
        views.title.text = item.title or ""
      end
      local previewText = item.preview or ""
      if previewText == "" then
        views.preview.visibility = View.GONE
       else
        views.preview.visibility = View.VISIBLE
        views.preview.text = previewText
      end

      views.item_count.text = string.format("%d个内容", item.itemCount)
      if item.followerCount then
        views.follower_count.text = string.format("%d人关注", item.followerCount)
      end

      views.lock_icon.visibility = item.isPublic == false and View.VISIBLE or View.GONE
      if item.creator and item.creator.name then
        views.creator_name.text = item.creator.name .. " 创建"
      end

      views.card.onClick = function()
        if item.type == "empty" then
          self:showRecommendDialog()
          return
        end
        Router.go("collection", { id = item.id }, { sharedElement = views.card })
      end
    end,
  })
end

function CollectionTabModel:onFirstLoad(data, dataList, key)
  -- 只在“关注”tab 且数据为空时插入空状态
  if key == "followed" and #dataList == 0 then
    table.insert(dataList, {
      id = "empty_following",
      type = "empty",
      title = "推荐收藏夹",
      preview = "为你推荐",
      itemCount = 0,
      followerCount = 0,
      isPublic = true,
      creator = { name = "知乎" },
    })
  end
end

local CollectionRecommendModel = require("models.collection.CollectionRecommendModel")
function CollectionTabModel:showRecommendDialog()
  import "androidx.appcompat.widget.LinearLayoutCompat"
  import "com.hydrogen.view.CustomSwipeRefresh"
  import "androidx.recyclerview.widget.RecyclerView"
  import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

  local dialogViews = {}
  local layout = Layouts.pages.simple_list.main

  local dialogView = loadlayout(layout, dialogViews)
  local toolbar = dialogViews.toolbar
  toolbar.parent.removeView(toolbar)
  -- 背景透明
  dialogViews.main_container.backgroundColor = 0
  local dialog = MaterialAlertDialogBuilder(activity)
  .setTitle("推荐收藏夹")
  .setView(dialogView)
  .setPositiveButton("关闭", nil)
  .show()

  local model = CollectionRecommendModel()
  model:setupSingle(dialogViews.recycler_view, dialogViews.swipe_refresh)
  model:refresh()

  dialog.onDismiss = function()
    model:destroy()
  end
end

function CollectionTabModel:destroy()
  self.userId = nil
end

return CollectionTabModel