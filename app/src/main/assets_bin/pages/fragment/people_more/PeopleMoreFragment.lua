-- pages/fragment/people_more/PeopleMoreFragment.lua
-- 用户更多内容

local BaseFragment = require("pages.base.BaseFragment")

local PeopleMoreFragment = Extensions.Class(BaseFragment)
PeopleMoreFragment:chainUp("onDestroy")

function PeopleMoreFragment:ctor()
  self.userId = nil
  self.moreType = nil
  self.title = "更多内容"
  self.model = nil
end

function PeopleMoreFragment:onCreate(params)
  self.userId = tostring(params.id)
  self.moreType = params.title or ""
  self.title = self.moreType

  if self.moreType:find("收藏") then
    self.model = require("models.collection.CollectionTabModel"):new(self.userId)
   else
    self.model = require("models.user.PeopleMoreModel"):new(self.userId, self.moreType)
  end
end

function PeopleMoreFragment:initLayout()
  local colors = AppTheme.getColors()

  if self.moreType:find("收藏") then
    self.root_view = loadlayout(Layouts.pages.people_more.collections, self.views)
   else
    self.root_view = loadlayout(Layouts.pages.people_more.main, self.views)
  end
end

function PeopleMoreFragment:initViews()
  local views = self.views

  Helpers.UI.setupToolbar(views.toolbar, { title = self.title })

  if self.moreType:find("收藏") then
    if views.view_pager and views.tab_layout then
      self.model:setupTabs(views.view_pager, views.tab_layout)
      self.model:ensureLoaded()
    end
   else
    if views.recycler_view then
      self.model:setupSingle(views.recycler_view, views.swipe_refresh)
      self.model:ensureLoaded()
    end
  end

  self:setupEdgeToEdge({
    top = { self.views.main_container },
    callback = function(statusBarHeight, navBarHeight)
      for _, rv in ipairs(self.model:getAllRecyclerViews()) do
        rv.setPadding(
        rv.getPaddingLeft(),
        rv.getPaddingTop(),
        rv.getPaddingRight(),
        rv.getPaddingBottom() + navBarHeight
        )
        rv.setClipToPadding(false)
      end
    end
  })

end

function PeopleMoreFragment:onDestroy()
  if self.model then
    self.model:destroy()
    self.model = nil
  end
end

return PeopleMoreFragment