-- components/dialog/CommentSheet.lua
-- 评论sheet

local M = {}

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.recyclerview.widget.RecyclerView"
import "androidx.recyclerview.widget.LinearLayoutManager"
import "com.google.android.material.bottomsheet.BottomSheetDialog"
import "com.google.android.material.bottomsheet.BottomSheetBehavior"
import "android.view.View"
import "androidx.appcompat.widget.PopupMenu"

local CommentModel = require("models.content.CommentModel")

function M:initListView()
  local model = self.model
  local views = self.sheetViews

  local menuItems = {
    {
      id = "sort_score",
      title = "默认",
      click = function() self:changeSortOrder("score") end,
    },
    {
      id = "sort_ts",
      title = "最新",
      click = function() self:changeSortOrder("ts") end,
    },
  }

  Helpers.UI.setupToolbar(views.toolbar, {  
    title = "评论",
    menu = menuItems,
    navCallback = function() self.bottomSheet.dismiss() end,
  })

  model:setupSingle(views.recycler_view, views.swipe_refresh)
  model:ensureLoaded()

  model:addListener("commentClick", function(item, position)
    self:onCommentClick(item)
  end)

  model:addListener("commentLongClick", function(item, position, anchorView)
    self:showCommentMenu(item, anchorView)
  end)

  model:addListener("showMoreComments", function(parentId, nextOffset)
    M.show({
      contentId = parentId,
      contentType = "comment",
      parentContentType = self.model.parentContentType or self.contentType
    })
  end)

  model:addListener("totalCountChanged", function(count)
    self.totalCount = count
    self:updateHeader()
  end)
end

function M:setupEvents()
  local views = self.sheetViews

  -- 点击卡片打开评论编辑器
  views.bottom_card.onClick = function()
    self:openCommentEditor()
  end
end

function M:openCommentEditor()
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    Router.go("login")
    return
  end

  local CommentEditorSheet = require("components.dialog.CommentEditorSheet")
  CommentEditorSheet.show({
    contentType = self.parentContentType or self.contentType,
    contentId = self.contentId,
    onSuccess = function()
      self.model:refresh()
    end,
    onError = function(err)
      tip(err or "发布失败")
    end
  })
end

function M:changeSortOrder(orderBy)
  if self.currentOrder == orderBy then return end
  self.currentOrder = orderBy
  self.model:setOrderBy(orderBy)
end

function M:updateHeader()
  self.sheetViews.toolbar.title = "评论"
  -- 设置子标题
  self.sheetViews.toolbar.subtitle = string.format("共%d条", self.totalCount)
end

function M:onCommentClick(item)
  self:showReplyDialog(item.id, item.title)
end

function M:postComment()
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    Router.go("login")
    return
  end
  local input = self.sheetViews.comment_input
  local content = input and input.text.toString() or ""
  if content == "" then tip("请输入内容") return end
  self.model:postComment(content, nil, function(success)
    if success then input.text = "" self.model:refresh() end
  end)
end

function M:showReplyDialog(commentId, authorName)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    return
  end

  local CommentEditorSheet = require("components.dialog.CommentEditorSheet")

  CommentEditorSheet.show({
    contentType = self.parentContentType or self.contentType, -- 父内容类型（来自 M.show 时传入的 parentContentType）
    contentId = self.contentId,
    replyId = commentId,
    authorName = authorName,
    onSuccess = function()
      self.model:refresh()
      tip("回复成功")
    end,
    onError = function(err)
      tip(err or "回复失败")
    end
  })
end

function M:showCommentMenu(item, anchorView)
  local menuItems = {
    { title = "分享", onClick = function() Helpers.UI.shareText(item.content and item.content.toString() or "") end },
    { title = "复制", onClick = function() Helpers.UI.copyText(item.content and item.content.toString() or "") tip("复制成功") end },
    { title = item.isDisliked and "取消踩" or "踩评论", onClick = function() self:handleDislike(item) end },
    { title = "举报", onClick = function() Router.go("report", { id = item.id, type="comment" }) end },
    { title = "屏蔽用户", onClick = function() self:handleBlockUser(item.authorId) end },
    { title = "查看主页", onClick = function() Router.go("people", { id = item.authorId, data = item.author }) end },
  }

  if item.isAuthor then
    table.insert(menuItems, {
      title = "删除",
      onClick = function()
        self:handleDeleteComment(item)
      end
    })
  end

  self:showCommentMenuPopup(item, menuItems, anchorView)
end

function M:handleDeleteComment(item)
  MaterialAlertDialogBuilder(activity)
  .setTitle("提示")
  .setMessage("确定删除这条评论吗？")
  .setPositiveButton("确定", function()
    self.model:deleteComment(item.id, function(success)
      if success then
        tip("删除成功")
        self.model:refresh()
       else
        tip("删除失败")
      end
    end)
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function M:showCommentMenuPopup(item, menuItems, anchorView)
  local popup = PopupMenu(activity, anchorView or self.sheetViews.toolbar)
  for _, m in ipairs(menuItems) do popup.menu.add(m.title) end
  popup.onMenuItemClick = function(menuItem)
    for _, m in ipairs(menuItems) do
      if m.title == menuItem.title then
        m.onClick()
        return true
      end
    end
    return false
  end
  popup.show()
end

function M:handleDislike(item)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then tip("请登录后使用") return end
  local isDislike = not item.isDisliked
  self.model:dislikeComment(item.id, isDislike, function(success)
    if success then item.isDisliked = isDislike tip(isDislike and "踩成功" or "取消踩成功") end
  end)
end

function M:handleBlockUser(userId)
  MaterialAlertDialogBuilder(activity)
  .setTitle("提示")
  .setMessage("确定拉黑该用户吗？")
  .setPositiveButton("确定", function()
    self.model:post("https://api.zhihu.com/settings/blocked_users", "people_id=" .. userId, nil, function(success)
      if success then tip("已拉黑") end
    end)
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function M:close()
  if self.model then self.model:destroy() self.model = nil end
end

function M.show(options)
  options = options or {}

  local self = {
    contentId = tostring(options.contentId or ""),
    contentType = options.contentType,
    parentContentType = options.parentContentType
  }

  setmetatable(self, { __index = M })

  self.model = CommentModel(self.contentId, self.contentType, self.parentContentType)

  self.sheetViews = {}
  local sheetView = loadlayout(Layouts.dialogs.comment_sheet, self.sheetViews)

  self:initListView()
  self:setupEvents()

  self.bottomSheet = BottomSheetDialog(activity)
  self.bottomSheet.contentView = sheetView

  local behavior = self.bottomSheet.behavior
  behavior.skipCollapsed = true

  self.bottomSheet.show()

  return self
end

return M