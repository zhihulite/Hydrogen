-- models/collection/CollectionContentModel.lua
-- 收藏夹内容列表（分页模型）- PageToolModel

local PageToolModel = require("models.base.PageToolModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")
local CollectionMoveSheet = require("components.dialog.CollectionMoveSheet")

local CollectionContentModel = Extensions.Class(PageToolModel)
CollectionContentModel:chainUp("destroy")

function CollectionContentModel:ctor(collectionId)
  self.collectionId = tostring(collectionId)
  self.requestHeadKey = "defaultHead"
  self.collectionInfo = nil
end

function CollectionContentModel:getInitialUrl()
  return "https://api.zhihu.com/collections/" .. self.collectionId ..
  "/contents?with_deleted=1"
end

function CollectionContentModel:parseItem(rawItem)
  local target = rawItem.target or rawItem

  if target.type == "answer" then
    return {
      id = target.id,
      type = target.type,
      title = target.question and target.question.title or "",
      preview = target.excerpt and fromHtml(target.excerpt) or nil,
      voteupCount = target.voteup_count or 0,
      commentCount = target.comment_count or 0,
    }
   elseif target.type == "article" then
    return {
      id = target.id,
      type = target.type,
      title = target.title or "",
      preview = target.excerpt and fromHtml(target.excerpt) or nil,
      voteupCount = target.voteup_count or 0,
      commentCount = target.comment_count or 0,
    }
   elseif target.type == "pin" then
    return {
      id = target.id,
      type = target.type,
      title = "一个想法",
      preview = target.excerpt_title and fromHtml(target.excerpt_title) or nil,
      voteupCount = target.collection_count or 0,
      commentCount = target.comment_count or 0,
    }
   elseif target.type == "zvideo" then
    return {
      id = target.id,
      type = target.type,
      title = target.title or "",
      preview = target.excerpt_title and fromHtml(target.excerpt_title) or nil,
      voteupCount = target.collection_count or 0,
      commentCount = target.comment_count or 0,
    }
  end

  return nil
end

function CollectionContentModel:createAdapter(dataList)
  return SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.collection_content)
    end,
    onBind = function(views, item, position, holder)
      views.title.text = item.title or ""
      views.preview.text = item.preview or ""
      views.like_count.text = tostring(item.voteupCount)
      views.comment_count.text = tostring(item.commentCount)
      views.card.onClick = function()
        Helpers.ZhihuParser.go(item.type, { id = item.id }, { sharedElement = views.card })
      end
      views.card.onLongClick = function()
        self:showItemMenu(item, views.card)
        return true
      end
    end,
  })
end

function CollectionContentModel:loadCollectionInfo(callback)
  local url = "https://api.zhihu.com/collections/" .. self.collectionId .. "?with_deleted=1&censor=1"

  self:fetch(url, nil, function(success, response)
    if not success then
      if callback then callback(false, nil) end
      return
    end

    local collection = response.collection
    self.collectionInfo = {
      id = tostring(collection.id),
      title = collection.title,
      description = collection.description,
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

    self:notifyListeners("collectionInfoChanged", self.collectionInfo)
    if callback then callback(true, self.collectionInfo) end
  end)
end

function CollectionContentModel:getCollectionInfo()
  return self.collectionInfo
end

function CollectionContentModel:followCollection(callback)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  local url = "https://api.zhihu.com/collections/" .. self.collectionId .. "/followers"

  if self.collectionInfo and self.collectionInfo.isFollowing then
    self:delete(url, nil, function(success)
      if success and self.collectionInfo then
        self.collectionInfo.isFollowing = false
        self.collectionInfo.followerCount = math.max(0, (self.collectionInfo.followerCount or 1) - 1)
        self:notifyListeners("collectionInfoChanged", self.collectionInfo)
      end
      if callback then callback(success) end
    end)
   else
    self:post(url, "", nil, function(success)
      if success and self.collectionInfo then
        self.collectionInfo.isFollowing = true
        self.collectionInfo.followerCount = (self.collectionInfo.followerCount or 0) + 1
        self:notifyListeners("collectionInfoChanged", self.collectionInfo)
      end
      if callback then callback(success) end
    end)
  end
end

import "com.google.android.material.dialog.MaterialAlertDialogBuilder"
function CollectionContentModel:removeFromCollection(contentId, contentType)
  MaterialAlertDialogBuilder(activity)
  .setTitle("取消收藏")
  .setMessage("确定取消收藏吗？取消后不可恢复！")
  .setPositiveButton("确定", function()
    local url = "https://api.zhihu.com/collections/" .. self.collectionId ..
    "/contents/" .. contentId .. "?content_type=" .. contentType

    self:delete(url, nil, function(success)
      if success then
        tip("已取消收藏")
        self:refresh()
      end
    end)
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function CollectionContentModel:showItemMenu(item, anchorView)
  local popup = PopupMenu(activity, anchorView)

  popup.getMenu().add("取消收藏")
  popup.getMenu().add("移动到其他收藏夹")

  popup.setOnMenuItemClickListener({
    onMenuItemClick = function(menuItem)
      local title = menuItem.getTitle()
      if title == "取消收藏" then
        self:removeFromCollection(item.id, item.type)
       elseif title == "移动到其他收藏夹" then
        CollectionMoveSheet.show({
          contentId = item.id,
          contentType = item.type,
          autoToggle = false,
          onSuccess = function(stillInAnyCollection, addedCount, removedCount)
            self:refresh()
            tip(string.format("已更新 %d 个收藏夹", addedCount + removedCount))
          end,
          onError = function(err)
            tip(err or "操作失败")
          end
        })
      end
      return true
    end
  })

  popup.show()
end

function CollectionContentModel:destroy()
  self.collectionInfo = nil
end

return CollectionContentModel