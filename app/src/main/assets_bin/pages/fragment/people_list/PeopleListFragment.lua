-- pages/fragment/people_list/PeopleListFragment.lua

local SimpleListFragment = require("pages.fragment.base.SimpleListFragment")
local PeopleListModel = require("models.user.PeopleListModel")

local PeopleListFragment = Extensions.Class(SimpleListFragment)
PeopleListFragment:chainUp("onDestroy")

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
      { title = "粉丝列表", onClick = function() self:switchType("followers") end },
      { title = "关注列表", onClick = function() self:switchType("followees") end },
    }
  elseif self.model.listType:find("block") then
    items = {
      { title = "全部黑名单", onClick = function() self:switchType("block_all") end },
      { title = "瓦力黑名单", onClick = function() self:switchType("block_walle") end },
    }
  end

  self.menuItems = items
end

function PeopleListFragment:switchType(newType)
  if self.model.listType == newType then return true end
  self.model:setListType(newType)
  return true
end

return PeopleListFragment