-- pages/fragment/base/SimpleListFragment.lua

local BaseFragment = require("pages.base.BaseFragment")

local SimpleListFragment = Extensions.Class(BaseFragment, {"simple_list"})

function SimpleListFragment:ctor()
  self.model = nil
  self.title = "列表"
  self.menuItems = nil
end

function SimpleListFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.simple_list.main, self.views)
end

function SimpleListFragment:initViews()
  local views = self.views
  if not views then return end

  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = { views.recycler_view },
  })

  Helpers.UI.setupToolbar(views.toolbar, {
    title = self.title,
    menu = self.menuItems
  })

  self:initList()
end

function SimpleListFragment:setMenuItems(items)
  self.menuItems = items
  if self.views and self.views.toolbar then
    Helpers.UI.setupToolbar(self.views.toolbar, {
      title = self.title,
      menu = self.menuItems
    })
  end
end

function SimpleListFragment:initList()
  local views = self.views

  if self.model.init then
    self.model:init(views.recycler_view, views.swipe_refresh)
    self.model:ensureLoaded()
   elseif self.model.setupSingle then
    self.model:setupSingle(views.recycler_view, views.swipe_refresh)
    self.model:ensureLoaded()
  end
end

function SimpleListFragment:refresh()
  if self.model and self.model.refresh then
    self.model:refresh()
  end
end

function SimpleListFragment:onDestroy()
  if self.model and self.model.destroy then
    self.model:destroy()
    self.model = nil
  end
end

return SimpleListFragment