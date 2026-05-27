-- pages/fragment/people_more/PeopleMoreFragment.lua
-- 用户更多内容

local BaseFragment = require("pages.base.BaseFragment")

local PeopleMoreFragment = Extensions.Class(BaseFragment)

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
  local colors = AppTheme.colors

  if self.moreType:find("收藏") then
    self.root_view = loadlayout(Layouts.pages.people_more.collections, self.views)
   else
    self.root_view = loadlayout(Layouts.pages.people_more.main, self.views)
  end
end

-- 收集所有需要底部导航栏避让的页面并设置 clipToPadding
function PeopleMoreFragment:collectAllBottomViews()
  local bottomViews = {}

  if not self.model then return bottomViews end

  -- 收集 model 中的所有 RecyclerView
  for _, rv in ipairs(self.model:getAllRecyclerViews()) do
    rv.clipToPadding = false
    table.insert(bottomViews, rv)
  end

  return bottomViews
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

  -- 收集所有需要底部避让的视图
  local bottomViews = self:collectAllBottomViews()
  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = bottomViews
  })
end

function PeopleMoreFragment:onDestroy()
  if self.model then
    self.model:destroy()
    self.model = nil
  end
end

return PeopleMoreFragment