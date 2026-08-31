-- pages/fragment/topic/topic_fragment.lua
-- 话题详情 Fragment

import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

local BaseFragment = require("pages.base.base_fragment")
local TopicModel = require("models.topic.topic_model")

local TopicFragment = Extensions.Class(BaseFragment, {"topic"})

function TopicFragment:ctor()
  self.topicId = nil
  self.topicModel = nil
  self.currentTabKey = nil
  self.sortMenuVisible = nil
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
  local rvList = self:collectModelBottomViews(self.topicModel)

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

  -- 排序项只区分「列表 Tab 有 / 详情 Tab 无」两种状态，状态不变时跳过整体重建
  local needSort = tabKey and tabKey ~= "detail"
  if self.sortMenuVisible == needSort then return end
  self.sortMenuVisible = needSort

  local menuItems = {
    { id = "share", title = "分享", click = function() self:shareTopic() end },
    { id = "copy", title = "复制链接", click = function() self:copyTopicLink() end },
    { id = "refresh", title = "刷新", icon = Helpers.Static.materialDrawable("twotone_refresh", 24), click = function() self:refreshCurrentTab() end },
  }

  if needSort then
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
  local key = self.currentTabKey or self.topicModel:getCurrentKey()
  if key and not self.topicModel:isPrePageByKey(key) then
    self.topicModel:refresh(key)
   else
    self.topicModel:loadTopicInfo()
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