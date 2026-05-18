-- models/user/PeopleListModel.lua
-- 用户列表 - PageToolModel（单页）

local PageToolModel = require("models.base.PageToolModel")
local SimpleAdapter = require("components.adapter.SimpleRecyclerAdapter")
local UserModel = require("models.user.UserModel")

local PeopleListModel = Extensions.Class(PageToolModel)
PeopleListModel:chainUp("destroy")

function PeopleListModel:ctor(userId, listType)
  self.needLogin = true
  self.userId = tostring(userId)
  self.listType = listType or "followers"
  self.requestHeadKey = "defaultHead"
  self.userModel = UserModel()
end

function PeopleListModel:destroy()
  if self.userModel then
    self.userModel:destroy()
    self.userModel = nil
  end
  self:super("destroy")
end

function PeopleListModel:setListType(listType)
  self.listType = listType
  self:clear()
  self:refresh()
end

function PeopleListModel:getInitialUrl()
  if self.listType == "followers" then
    return "https://api.zhihu.com/people/" .. self.userId .. "/followers"
   elseif self.listType == "followees" then
    return "https://api.zhihu.com/people/" .. self.userId .. "/followees"
   elseif self.listType == "block_all" then
    return "https://api.zhihu.com/settings/blocked_users?filter=all"
   elseif self.listType == "block_walle" then
    return "https://api.zhihu.com/settings/blocked_users?filter=walle"
   elseif self.listType == "voter" then
    return "https://api.zhihu.com/pins/" .. self.userId .. "/actions"
  end
  return ""
end

function PeopleListModel:parseItem(rawItem)
  local avatarUrl, name, headline, userId, isFollowing, isBlocking

  if rawItem.type == "people" then
    avatarUrl = rawItem.avatar_url
    name = rawItem.name
    headline = rawItem.headline or ""
    userId = tostring(rawItem.id)
    isFollowing = rawItem.is_following or false
    if self.listType:find("block") then
      isBlocking = true
     else
      isBlocking = rawItem.is_blocking or false
    end
   elseif rawItem.type == "pin_action" then
    avatarUrl = rawItem.member.avatar_url
    name = rawItem.member.name
    headline = rawItem.member.headline or ""
    userId = tostring(rawItem.member.id)
    isFollowing = rawItem.member.is_following or false
    if self.listType:find("block") then
      isBlocking = true
     else
      isBlocking = rawItem.member.is_blocking or false
    end
   else
    return nil
  end

  if headline == "" then
    headline = "无签名"
  end

  local actionText = ""
  if self.listType == "followers" or self.listType == "followees" then
    actionText = isFollowing and "取关" or "关注"
   elseif self.listType:find("block") then
    actionText = isBlocking and "取消屏蔽" or "屏蔽"
   elseif self.listType == "voter" then
    actionText = rawItem.action_type == "like" and "喜欢了" or "转发了"
  end

  return {
    id = userId,
    type = "people",
    title = name,
    preview = headline,
    avatarUrl = avatarUrl,
    actionText = actionText,
    isFollowing = isFollowing,
    isBlocking = isBlocking,
  }
end

function PeopleListModel:createAdapter(dataList)
  local selfRef = self

  return SimpleAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleAdapter.inflate(Layouts.cards.people_list)
    end,
    onBind = function(views, item, position, holder)
      views.title.text = item.title or ""
      views.preview.text = item.preview or ""
      Helpers.Image.load(views.avatar, item.avatarUrl)

      views.action_btn.text = item.actionText or ""
      views.action_btn.onClick = function()
        selfRef:onActionClick(item, views.action_btn)
      end

      views.card.onClick = function()
        Router.go("people", { id = item.id }, { sharedElement = views.card })
      end
    end,
  })
end

function PeopleListModel:onActionClick(item, btn)
  if self.listType == "followers" or self.listType == "followees" then
    self:handleFollow(item, btn)
   elseif self.listType:find("block") then
    self:handleBlock(item, btn)
  end
end

function PeopleListModel:handleFollow(item, btn)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    return
  end

  self.userModel:setUserId(item.id)
  local isFollowing = btn.text == "取关"

  local function callback(success)
    if success then
      btn.text = isFollowing and "关注" or "取关"
      tip(isFollowing and "取关成功" or "关注成功")
     else
      tip(isFollowing and "取关失败" or "关注失败")
    end
  end

  if isFollowing then
    self.userModel:unfollow(callback)
   else
    self.userModel:follow(callback)
  end
end

function PeopleListModel:handleBlock(item, btn)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    return
  end

  self.userModel:setUserId(item.id)
  local isBlocked = btn.text == "取消屏蔽"

  local function callback(success)
    if success then
      btn.text = isBlocked and "屏蔽" or "取消屏蔽"
      tip(isBlocked and "已取消屏蔽" or "已屏蔽")
     else
      tip(isBlocked and "取消屏蔽失败" or "屏蔽失败")
    end
  end

  if isBlocked then
    self.userModel:unblock(callback)
   else
    self.userModel:block(callback)
  end
end

return PeopleListModel