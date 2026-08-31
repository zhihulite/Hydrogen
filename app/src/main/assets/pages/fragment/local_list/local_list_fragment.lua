-- pages/fragment/local_list/local_list_fragment.lua
-- 本地网页保存内容列表页面（专门用于 answer）

import "com.google.android.material.dialog.MaterialAlertDialogBuilder"
import "java.io.File"
import "android.view.View"

local BaseFragment = require("pages.base.base_fragment")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
local BottomDialog = require("helpers.bottom_dialog")
local SafeLinearLayoutManager = luajava.bindClass("com.hydrogen.SafeLinearLayoutManager")

local LocalListFragment = Extensions.Class(BaseFragment, {"local_list"})

function LocalListFragment:ctor()
  self.items = {}
  self.allItems = {}
  self.downloadDir = Extensions.File.getAppDir("Download")
end

function LocalListFragment:onCreate(params) end

function LocalListFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.local_list.main, self.views)
end

function LocalListFragment:initViews()
  local views = self.views
  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = { views.recycler_view },
  })

  Helpers.UI.setupToolbar(views.toolbar, {
    title = "本地内容",
    menu = {
      { id = "search", title = "搜索", icon = Helpers.Static.materialDrawable("twotone_search", 24), click = function() self:showSearchDialog() end },
      { id = "clear", title = "清空", click = function() self:clearAll() end },
    }
  })

  Helpers.UI.setupSwipeRefresh(views.swipe_refresh, function() self:loadData() end)
  self:initListView()
  self:loadData()
end

function LocalListFragment:loadData()
  local items = self:scanTitles()
  table.sort(items, function(a,b) return a.timestamp > b.timestamp end)
  table.clear(self.allItems)
  for _, item in ipairs(items) do table.insert(self.allItems, item) end
  table.clear(self.items)
  for _, item in ipairs(items) do table.insert(self.items, item) end
  self.adapter.notifyDataSetChanged()
  self.views.swipe_refresh.refreshing = false
  self:updateEmptyState()
end

function LocalListFragment:scanTitles()
  local results = {}
  local dir = File(self.downloadDir)
  if not dir.exists() then return results end
  local titleDirs = luajava.astable(dir.listFiles() or {})
  for _, titleDir in ipairs(titleDirs) do
    if titleDir.isDirectory() then
      local titleName = titleDir.name
      local titlePath = tostring(titleDir)
      local authors = {}
      local authorDirs = luajava.astable(titleDir.listFiles() or {})
      for _, authorDir in ipairs(authorDirs) do
        if authorDir.isDirectory() then
          local htmlPath = tostring(authorDir) .. "/html.html"
          if Extensions.File.exists(htmlPath) then
            table.insert(authors, {
              name = authorDir.name,
              path = tostring(authorDir),
              timestamp = authorDir.lastModified(),
            })
          end
        end
      end
      if #authors > 0 then
        table.insert(results, {
          title = titleName,
          path = titlePath,
          timestamp = titleDir.lastModified(),
          authors = authors,
        })
      end
    end
  end
  return results
end

function LocalListFragment:deleteTitle(titleItem)
  if Extensions.File.exists(titleItem.path) then
    Extensions.File.delete(titleItem.path)
    self:loadData()
  end
end

function LocalListFragment:search(keyword)
  local results = {}
  keyword = keyword:lower()
  -- 全量列表独立于展示列表：搜索结果会替换 self.items，收窄后的列表不能作为下一次搜索的来源
  for _, item in ipairs(self.allItems) do
    if item.title:lower():find(keyword, 1, true) then
      table.insert(results, item)
    end
  end
  return results
end

function LocalListFragment:initListView()
  local views = self.views
  self.adapter = SimpleRecyclerAdapter.new({
    items = self.items,
    onCreateView = function() return SimpleRecyclerAdapter.inflate(Layouts.cards.local_list) end,
    onBind = function(views, item, position)
      views.title.text = item.title or ""
      views.count.text = string.format("%d个内容", #item.authors)
      views.time.text = os.date("%Y-%m-%d %H:%M", math.floor(item.timestamp / 1000))
      views.card.onClick = function() self:showAuthorsDialog(item) end
      views.card.onLongClick = function() self:confirmDeleteTitle(item) return true end
    end,
  })
  views.recycler_view.layoutManager = SafeLinearLayoutManager(activity)
  views.recycler_view.adapter = self.adapter
end

function LocalListFragment:showAuthorsDialog(titleItem)
  local authors = titleItem.authors
  if not authors or #authors == 0 then tip("该标题下暂无有效内容") return end
  local options = {}
  for _, a in ipairs(authors) do table.insert(options, { title = a.name, path = a.path }) end
  -- 直接保存对话框对象，用于后续更新
  local dialog
  dialog = BottomDialog.select(options,
  function(idx, author) Router.go("local_content", { savePath = author.path, title = titleItem.title, author = author.title }) end,
  titleItem.title,
  function(idx, author, view)
    MaterialAlertDialogBuilder(activity)
    .setTitle("删除")
    .setMessage(string.format("确定删除「%s」中的作者「%s」吗？", titleItem.title, author.title))
    .setPositiveButton("确定", function()
      if Extensions.File.exists(author.path) then Extensions.File.delete(author.path) end
      -- 从内存中移除该作者
      for i, a in ipairs(titleItem.authors) do
        if a.path == author.path then table.remove(titleItem.authors, i) break end
      end
      if #titleItem.authors == 0 then
        dialog.dismiss()
        for i, item in ipairs(self.items) do
          if item.path == titleItem.path then table.remove(self.items, i); break end
        end
        self.adapter.notifyDataSetChanged()
        self:updateEmptyState()
       else
        -- 更新对话框内容
        local newOptions = {}
        for _, a in ipairs(titleItem.authors) do table.insert(newOptions, { title = a.name, path = a.path }) end
        dialog.updateItems(newOptions)
        -- 更新外层列表的计数
        for i, item in ipairs(self.items) do
          if item.path == titleItem.path then
            self.adapter.notifyItemChanged(i - 1)
            break
          end
        end
      end
    end)
    .setNegativeButton("取消", nil)
    .show()
  end
  )
end

function LocalListFragment:confirmDeleteTitle(titleItem)
  MaterialAlertDialogBuilder(activity)
  .setTitle("删除")
  .setMessage(string.format("确定删除整个「%s」吗？", titleItem.title))
  .setPositiveButton("确定", function() self:deleteTitle(titleItem) end)
  .setNegativeButton("取消", nil)
  .show()
end

function LocalListFragment:updateEmptyState()
  local views = self.views
  local isEmpty = #self.items == 0
  -- 隐藏整个刷新层：它与 empty_view 是竖向容器里的兄弟且都是 fill，
  -- 只隐藏内层 recycler_view 时刷新层仍占满高度，空状态会被挤成 0 高
  views.swipe_refresh.visibility = isEmpty and View.GONE or View.VISIBLE
  views.empty_view.visibility = isEmpty and View.VISIBLE or View.GONE
end

function LocalListFragment:showSearchDialog()
  local dv = {}
  MaterialAlertDialogBuilder(activity)
  .setTitle("搜索本地内容")
  .setView(loadlayout(Layouts.common.search_input, dv))
  .setPositiveButton("搜索", function()
    local kw = dv.edit and dv.edit.text
    if kw and kw ~= "" then
      local results = self:search(kw)
      table.clear(self.items)
      for _, item in ipairs(results) do table.insert(self.items, item) end
      self.adapter.notifyDataSetChanged()
      self:updateEmptyState()
      tip(string.format("找到 %d 条结果", #results))
    end
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function LocalListFragment:clearAll()
  MaterialAlertDialogBuilder(activity)
  .setTitle("清空")
  .setMessage("确定清空所有本地内容吗？")
  .setPositiveButton("确定", function()
    Extensions.File.delete(self.downloadDir)
    Extensions.File.mkdir(self.downloadDir)
    self:loadData()
    tip("已清空")
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function LocalListFragment:onDestroy()
  self.adapter = nil
  self.items = nil
  self.allItems = nil
end

return LocalListFragment