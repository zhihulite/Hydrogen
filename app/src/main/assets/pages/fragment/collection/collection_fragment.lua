-- pages/fragment/collection/collection_fragment.lua
-- 收藏夹详情页面，展示单个收藏夹的内容列表和信息

import "android.view.View"

local BaseFragment = require("pages.base.base_fragment")
local CollectionContentModel = require("models.collection.collection_content_model")
local RecyclerViewHelper = require("components.views.recycler_view_helper")
local CollectionEditSheet = require("components.dialog.collection_edit_sheet")

local CollectionFragment = Extensions.Class(BaseFragment, { "collection" })

function CollectionFragment:ctor()
  self.collectionId = nil
  self.model = nil
  self.headerView = nil
  self.headerViews = nil
  self.helper = nil
end

function CollectionFragment:onCreate(params)
  self.collectionId = tostring(params.id)
  self.model = CollectionContentModel(self.collectionId)

  self.model:addListener("collectionInfoChanged", function(info)
    self:updateHeaderCard(info)
    self:updateToolbarMenu(info)
  end)
end

function CollectionFragment:onDestroy()
  if self.model then
    self.model:destroy()
    self.model = nil
  end
end

function CollectionFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.collections.main, self.views)
end

function CollectionFragment:initViews()
  local views = self.views
  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = { views.recycler_view },
  })

  self:createHeaderCard()
  self:initContentList()
  self:loadData()
end

function CollectionFragment:updateToolbarMenu(info)
  local toolbar = self.views.toolbar
  if not toolbar then return end

  local userId = Extensions.Config.get(Constants.SharedDataKeys.USER_ID)
  local creatorId = info and info.creator and info.creator.id
  local isOwner = userId and creatorId and userId == creatorId

  local menuItems = {
    { id = "share", title = "分享", click = function() self:shareCollection() end },
    { id = "copy", title = "复制链接", click = function() self:copyCollectionLink() end },
    { id = "refresh", title = "刷新", click = function() self.model:refresh() end },
  }

  if isOwner then
    table.insert(menuItems, { id = "edit", title = "编辑", click = function() self:editCollection() end })
    table.insert(menuItems, { id = "delete", title = "删除", click = function() self:deleteCollection() end })
  end

  Helpers.UI.setupToolbar(toolbar, {
    title = info and info.title or "收藏夹",
    menu = menuItems
  })
end

function CollectionFragment:createHeaderCard()
  local colors = AppTheme.colors

  self.headerViews = {}
  self.headerView = loadlayout(Layouts.pages.collections.header, self.headerViews)

  if self.headerViews.follow_btn then
    self.headerViews.follow_btn.onClick = function()
      self:onFollowClick()
    end
  end
end

function CollectionFragment:updateHeaderCard(info)
  if not info then
    error("updateHeaderCard info不存在")
    return
  end

  local views = self.headerViews
  views.header_title.text = info.title or ""

  local desc = info.description or ""
  if desc ~= "" then
    views.header_description.text = desc
    views.header_description.visibility = View.VISIBLE
   else
    views.header_description.visibility = View.GONE
  end

  views.header_item_count.text = tostring(info.itemCount or 0)
  views.header_follower_count.text = tostring(info.followerCount or 0)

  if info.creator then
    views.creator_layout.visibility = View.VISIBLE
    views.creator_name.text = info.creator.name or ""
    Helpers.Image.load(views.creator_avatar, info.creator.avatarUrl)
   else
    views.creator_layout.visibility = View.GONE
  end

  self:updateFollowButtonVisiblity(info)
end

function CollectionFragment:updateFollowButtonVisiblity(info)
  local userId = Extensions.Config.get(Constants.SharedDataKeys.USER_ID)
  local creatorId = info and info.creator and info.creator.id

  if userId and creatorId and userId == creatorId then
    self.headerViews.follow_btn_container.visibility = View.GONE
    return
  end

  self.headerViews.follow_btn_container.visibility = View.VISIBLE
  self.headerViews.follow_btn.text = info.isFollowing and "已关注" or "关注"
end

function CollectionFragment:initContentList()
  local views = self.views

  Helpers.UI.setupSwipeRefresh(views.swipe_refresh, function()
    self.model:refresh()
  end)

  self.model:setupSingle(views.recycler_view, views.swipe_refresh)

  self.helper = RecyclerViewHelper.new(views.recycler_view.adapter)
  self.helper:addHeader(self.headerView)
  views.recycler_view.adapter = self.helper:getAdapter()
end

function CollectionFragment:loadData()
  self.model:loadCollectionInfo()
  self.model:refresh()
end

function CollectionFragment:shareCollection()
  local info = self.model:getCollectionInfo()
  local url = "https://www.zhihu.com/collection/" .. self.collectionId
  local title = info and info.title or "收藏夹"
  Helpers.UI.shareText(title .. "： " .. url)
end

function CollectionFragment:copyCollectionLink()
  local url = "https://www.zhihu.com/collection/" .. self.collectionId
  Helpers.UI.copyText(url)
  tip("链接已复制")
end

function CollectionFragment:editCollection()
  local info = self.model:getCollectionInfo()
  if not info then
    error("editCollection info不存在")
    return
  end

  CollectionEditSheet.show({
    collectionId = self.collectionId,
    name = info.title,
    description = info.description,
    isPublic = info.isPublic,
    isDefault = info.isDefault,
    onSuccess = function(collectionId, name)
      tip("保存成功")
      self.model:loadCollectionInfo()
    end,
    onError = function(err)
      tip(err or "保存失败")
    end
  })
end

function CollectionFragment:deleteCollection()
  Helpers.BottomDialog.confirm("确定删除该收藏夹吗？此操作不可撤销！", function()
    local url = "https://api.zhihu.com/collections/" .. self.collectionId
    NetWork.delete(url, Headers.defaultHead, self:runIfAlive(function(code)
      if code == 200 then
        tip("已删除")
        Router.back()
       else
        tip("删除失败")
      end
    end))
  end)
end

function CollectionFragment:onFollowClick()
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    Router.go("login")
    return
  end

  self.model:followCollection(function(success)
    if success then
      local info = self.model:getCollectionInfo()
      local isFollowing = info and info.isFollowing or false
      tip(isFollowing and "已关注" or "已取消关注")
    end
  end)
end

return CollectionFragment