-- models/user/people_list_model.lua
-- 用户列表 - PageToolModel（单页）

local PageToolModel = require("models.base.page_tool_model")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
local UserModel = require("models.user.user_model")

local PeopleListModel = Extensions.Class(PageToolModel)

local FOLLOW_CFG = {
  field = "isFollowing", onText = "取关", offText = "关注",
  onOk = "关注成功", offOk = "取关成功", onFail = "关注失败", offFail = "取关失败",
  doOn = "follow", doOff = "unfollow",
}

local BLOCK_CFG = {
  field = "isBlocking", onText = "取消屏蔽", offText = "屏蔽",
  onOk = "已屏蔽", offOk = "已取消屏蔽", onFail = "屏蔽失败", offFail = "取消屏蔽失败",
  doOn = "block", doOff = "unblock",
}

function PeopleListModel:ctor(userId, listType)
  self.needLogin = true
  self.userId = tostring(userId)
  self.listType = listType or "followers"
  self.requestHeadKey = Constants.RequestHeadKeys.DEFAULT_HEAD
  self.userModel = UserModel()
end

function PeopleListModel:destroy()
  if self.userModel then
    self.userModel:destroy()
    self.userModel = nil
  end
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
  return SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.people_list)
    end,
    onBind = function(views, item, position, holder, adapter)
      views.title.text = item.title or ""
      views.preview.text = item.preview or ""
      Helpers.Image.load(views.avatar, item.avatarUrl)

      views.action_btn.text = item.actionText or ""
      views.action_btn.onClick = function()
        self:onActionClick(item, position, adapter)
      end

      views.card.onClick = function()
        Router.go("people", { id = item.id }, { sharedElement = views.card })
      end
    end,
  })
end

function PeopleListModel:onActionClick(item, position, adapter)
  if self.listType == "followers" or self.listType == "followees" then
    self:handleFollow(item, position, adapter)
   elseif self.listType:find("block") then
    self:handleBlock(item, position, adapter)
  end
end

--- 切换 item 的关注/屏蔽状态：写回 item 后按位置重绘该行
--- @param item table 列表条目（与 page.data 同引用）
--- @param position number 该行在适配器中的位置
--- @param adapter table 所属适配器
--- @param cfg table 状态字段、文案与请求方法名配置
function PeopleListModel:toggleAction(item, position, adapter, cfg)
  if not self:requireLogin() then return end

  self.userModel:setUserId(item.id)
  local active = item[cfg.field]

  local function callback(success)
    if success then
      item[cfg.field] = not active
      item.actionText = item[cfg.field] and cfg.onText or cfg.offText
      -- 请求返回时 views 可能已绑到别的用户，按位置重绘
      adapter.notifyItemChanged(position)
      tip(active and cfg.offOk or cfg.onOk)
     else
      tip(active and cfg.offFail or cfg.onFail)
    end
  end

  self.userModel[active and cfg.doOff or cfg.doOn](self.userModel, callback)
end

function PeopleListModel:handleFollow(item, position, adapter)
  self:toggleAction(item, position, adapter, FOLLOW_CFG)
end

function PeopleListModel:handleBlock(item, position, adapter)
  self:toggleAction(item, position, adapter, BLOCK_CFG)
end

return PeopleListModel