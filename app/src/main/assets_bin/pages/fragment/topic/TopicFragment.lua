-- pages/fragment/topic/TopicFragment.lua
-- 话题详情 Fragment

import "android.widget.PopupMenu"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

local BaseFragment = require("pages.base.BaseFragment")
local TopicModel = require("models.topic.TopicModel")

local TopicFragment = Extensions.Class(BaseFragment, {"topic"})

function TopicFragment:ctor()
  self.topicId = nil
  self.topicModel = nil
  self.currentTabKey = nil
end

function TopicFragment:onCreate(params)
  self.topicId = tostring(params.id)
  self.topicModel = TopicModel(self.topicId)

  self.topicModel:addListener("topicInfoChanged", function(topicInfo)
    self:updateTitle(topicInfo.name or "话题详情")
  end)

  self.topicModel:addListener("tabSelected", function(key)
    self.currentTabKey = key
    self:updateSortMenuVisibility(key)
  end)
end

function TopicFragment:onDestroy()
  if self.topicModel then
    self.topicModel:destroy()
    self.topicModel = nil
  end
end

function TopicFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.topic.main, self.views)
end

-- 收集所有需要底部导航栏避让的页面并设置 clipToPadding
function TopicFragment:collectAllBottomViews()
  local rvList = {}

  -- 收集 topicModel 中的所有 RecyclerView
  for _, rv in ipairs(self.topicModel:getAllRecyclerViews()) do
    rv.clipToPadding = false
    table.insert(rvList, rv)
  end

  -- 收集详情页的 detail_container
  local detail_container = self.topicModel:getDetailViews().detail_container
  if detail_container then
    detail_container.clipToPadding = false
    table.insert(rvList, detail_container)
  end

  return rvList
end

function TopicFragment:initViews()
  local views = self.views
  self.topicModel:loadTopicInfo()
  self:initViewPager()
  self:updateSortMenuVisibility(nil) -- 默认初始化工具栏

  -- 收集所有需要底部导航栏避让的视图
  local bottomViews = self:collectAllBottomViews()

  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = bottomViews
  })
end

function TopicFragment:updateSortMenuVisibility(tabKey)
  local toolbar = self.views.toolbar
  if not toolbar then return end

  local menuItems = {
    { id = "share", title = "分享", icon = Helpers.Static.materialDrawable("twotone_share", 24), click = function() self:shareTopic() end },
    { id = "copy", title = "复制链接", icon = Helpers.Static.materialDrawable("twotone_link", 24), click = function() self:copyTopicLink() end },
    { id = "refresh", title = "刷新", icon = Helpers.Static.materialDrawable("twotone_refresh", 24), click = function() self:refreshCurrentTab() end },
  }

  if tabKey and tabKey ~= "detail" then
    table.insert(menuItems, 1, {
      id = "sort", title = "排序",
      icon = Helpers.Static.materialDrawable("twotone_sort", 24),
      asAction = "always",
      click = function() self:showSortDialog() end
    })
  end

  Helpers.UI.setupToolbar(toolbar, {
    menu = menuItems
  })
end

function TopicFragment:refreshCurrentTab()
  if self.currentTabKey and self.currentTabKey ~= "detail" then
    self.topicModel:refresh(self.currentTabKey)
   else
    self.topicModel:refresh()
  end
end

function TopicFragment:showSortDialog()
  local options = {}
  local currentSort = self.topicModel:getCurrentSort(self.currentTabKey)

  if self.currentTabKey == "essence" then
    options = { "按精华排序", "按时间排序", "按热度排序" }
   elseif self.currentTabKey == "pin" then
    options = { "按时间排序", "按热度排序" }
   elseif self.currentTabKey == "zvideo" then
    options = { "按最新排序", "按热度排序" }
   elseif self.currentTabKey == "question" then
    options = { "按最新排序", "按热度排序" }
   else
    return
  end

  local selected = 0
  for i, opt in ipairs(options) do
    local sortKey = self:getSortKeyFromName(opt)
    if sortKey == currentSort then
      selected = i - 1
      break
    end
  end

  MaterialAlertDialogBuilder(activity)
  .setTitle("排序方式")
  .setSingleChoiceItems(options, selected, function(dialog, which)
    local sortKey = self:getSortKeyFromName(options[which + 1])
    self.topicModel:setSort(self.currentTabKey, sortKey)
    dialog.dismiss()
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function TopicFragment:getSortKeyFromName(name)
  local map = {
    ["按精华排序"] = "essence",
    ["按时间排序"] = "new",
    ["按热度排序"] = "hot",
    ["按最新排序"] = "new",
  }
  return map[name] or "new"
end

function TopicFragment:updateTitle(title)
  local toolbar = self.views.toolbar
  if toolbar then toolbar.title = title end
end

function TopicFragment:initViewPager()
  local viewPager = self.views.view_pager
  local tabLayout = self.views.tab_layout
  if not viewPager or not tabLayout then return end

  self.topicModel:setupTabs(viewPager, tabLayout)
  self.topicModel:ensureLoaded()
end

function TopicFragment:shareTopic()
  local topicInfo = self.topicModel:getTopicInfo()
  local topicName = topicInfo and topicInfo.name or "话题"
  local url = "https://www.zhihu.com/topic/" .. self.topicId
  Helpers.UI.shareText(topicName .. "： " .. url)
end

function TopicFragment:copyTopicLink()
  local url = "https://www.zhihu.com/topic/" .. self.topicId
  Helpers.UI.copyText(url)
  tip("链接已复制")
end

return TopicFragment