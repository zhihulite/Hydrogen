-- pages/fragment/history/HistoryFragment.lua
-- 历史记录 Fragment

import "android.view.View"
import "androidx.recyclerview.widget.LinearLayoutManager"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

local BaseFragment = require("pages.base.BaseFragment")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")
local TabBar = require("components.views.TabBar")

local HistoryFragment = Extensions.Class(BaseFragment)

local tabConfig = {
  { id = "all", display = "全部" },
  { id = "answer", display = "回答" },
  { id = "article", display = "文章" },
  { id = "pin", display = "想法" },
  { id = "question", display = "问题" },
  { id = "people", display = "用户" },
  { id = "zvideo", display = "视频" },
}

local tabNames = {}
local typeMap = {}
for _, v in ipairs(tabConfig) do
  table.insert(tabNames, v.display)
  typeMap[v.id] = v.display
end

function HistoryFragment:ctor()
  self.items = {}
  self.currentTab = "all"
  self.tabs = nil
end

function HistoryFragment:onCreate(params) end

function HistoryFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.history.main, self.views)
end

function HistoryFragment:initViews()
  local views = self.views

  self:setupEdgeToEdge({
    top = views.main_container,
    bottom = views.recycler_view
  })

  Helpers.UI.setupToolbar(views.toolbar, {
    title = "历史记录",
    menu = {
      { id = "search", title = "搜索", icon = Helpers.Static.materialDrawable("twotone_search", 24),
        click = function() self:showSearchDialog() end },
      { id = "clear", title = "清空",
        click = function() self:clearAll() end },
    }
  })

  Helpers.UI.setupSwipeRefresh(views.swipe_refresh, function()
    self:loadData()
  end)

  self:initTabs()
  self:initListView()
  self:loadData()
end

function HistoryFragment:initTabs()
  self.tabs = TabBar.create(
  self.views.tab_layout,
  tabNames,
  function(index, name)
    local tabID = tabConfig[index].id
    if self.currentTab == tabID then return end
    self.currentTab = tabID
    self:loadData()
    TabBar.select(self.tabs, index)
  end
  )
end

function HistoryFragment:loadData()
  local data = (self.currentTab == "all")
  and HistoryService.getAll()
  or HistoryService.filterByType(self.currentTab)

  table.clear(self.items)
  for _, item in ipairs(data) do
    table.insert(self.items, {
      id = item.id,
      type = item.type,
      typeName = typeMap[item.type] or "内容",
      title = item.title,
      preview = item.preview,
    })
  end

  self.adapter.notifyDataSetChanged()
  self:updateEmptyState()

  self.views.swipe_refresh.refreshing = false
end

function HistoryFragment:updateEmptyState()
  local isEmpty = #self.items == 0
  self.views.swipe_refresh.visibility = isEmpty and View.GONE or View.VISIBLE
  self.views.empty_view.visibility = isEmpty and View.VISIBLE or View.GONE
end

function HistoryFragment:initListView()
  local views = self.views
  if not views.recycler_view then return end

  self.adapter = SimpleRecyclerAdapter.new({
    items = self.items,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.history)
    end,
    onBind = function(views, item, position)
      views.type_text.text = item.typeName or "内容"
      views.title.text = item.title or ""
      local hasPreview = item.preview and item.preview ~= ""
      views.preview.visibility = hasPreview and View.VISIBLE or View.GONE
      views.preview.text = item.preview or ""
      views.card.onClick = function()
        self:onItemClick(item, position)
      end
      views.card.onLongClick = function()
        self:showDeleteConfirm(item)
        return true
      end
    end,
  })

  views.recycler_view.layoutManager = LinearLayoutManager(activity)
  views.recycler_view.adapter = self.adapter
end

function HistoryFragment:onItemClick(item, position)
  Helpers.ZhihuParser.go(item.type, { id = item.id })
end

function HistoryFragment:showDeleteConfirm(item)
  MaterialAlertDialogBuilder(activity)
  .setTitle("删除")
  .setMessage("删除该历史记录？该操作不可撤消！")
  .setPositiveButton("确定", function()
    HistoryService.remove(item.id, item.type)
    self:loadData()
    tip("已删除")
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function HistoryFragment:showSearchDialog()
  local views = {}
  MaterialAlertDialogBuilder(activity)
  .setTitle("搜索历史记录")
  .setView(loadlayout(Layouts.common.search_input, views))
  .setPositiveButton("搜索", function()
    local keyword = views.edit.text
    if keyword ~= "" then
      local results = HistoryService.search(keyword)
      table.clear(self.items)
      for _, item in ipairs(results) do
        table.insert(self.items, {
          id = item.id,
          type = item.type,
          typeName = typeMap[item.type] or "内容",
          title = item.title,
          preview = item.preview,
        })
      end
      self.adapter.notifyDataSetChanged()
      self:updateEmptyState()
      tip(string.format("找到 %d 条结果", #results))
    end
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function HistoryFragment:clearAll()
  MaterialAlertDialogBuilder(activity)
  .setTitle("清空")
  .setMessage("确定清空所有历史记录吗？此操作不可撤销！")
  .setPositiveButton("确定", function()
    HistoryService.clearAll()
    self:loadData()
    tip("已清空")
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function HistoryFragment:onDestroy()
  if self.adapter then
    self.adapter = nil
  end
  self.items = nil
  self.tabs = nil
end

return HistoryFragment