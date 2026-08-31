-- pages/fragment/people_list/people_list_fragment.lua
-- 用户列表 Fragment

local SimpleListFragment = require("pages.fragment.base.simple_list_fragment")
local PeopleListModel = require("models.user.people_list_model")

-- 菜单切换列表类型时对应的页面标题
local TYPE_TITLES = {
  followers = "粉丝列表",
  followees = "关注列表",
  block_all = "全部黑名单",
  block_walle = "瓦力黑名单",
}

local PeopleListFragment = Extensions.Class(SimpleListFragment)

function PeopleListFragment:ctor()
  self.title = nil
  self.model = nil
end

function PeopleListFragment:onCreate(params)
  self.title = params.title or "用户列表"

  local listType = params.type or "followers"
  self.model = PeopleListModel(params.id, listType)

  self:updateMenu()
end

function PeopleListFragment:updateMenu()
  local items = {}
  if self.model.listType == "followers" or self.model.listType == "followees" then
    items = {
      { title = "粉丝列表", click = function() self:switchType("followers") end },
      { title = "关注列表", click = function() self:switchType("followees") end },
    }
   elseif self.model.listType:find("block") then
    items = {
      { title = "全部黑名单", click = function() self:switchType("block_all") end },
      { title = "瓦力黑名单", click = function() self:switchType("block_walle") end },
    }
  end

  self.menuItems = items
end

function PeopleListFragment:switchType(newType)
  if self.model.listType == newType then return true end
  self.model:setListType(newType)
  self.title = TYPE_TITLES[newType] or self.title
  if self.views and self.views.toolbar then
    self.views.toolbar.title = self.title
  end
  return true
end

return PeopleListFragment