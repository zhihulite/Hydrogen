-- pages/fragment/search/SearchFragment.lua

import "android.widget.GridView"
import "android.widget.ListView"
import "androidx.appcompat.widget.SearchView"
import "com.google.android.material.chip.ChipGroup"
import "com.google.android.material.chip.Chip"
import "android.view.View"

local BaseFragment = require("pages.base.BaseFragment")
local SearchModel = require("models.search.SearchModel")
local SearchHistoryService = require("services.cache.search")

local SearchFragment = Extensions.Class(BaseFragment, {"search"})
SearchFragment:chainUp("onDestroy")

function SearchFragment:ctor()
  self.searchUrlTemplate = nil
  self.model = nil
  self.hotAdapter = nil
  self.suggestAdapter = nil
  self.searchView = nil
end

function SearchFragment:onCreate(params)
  self.searchUrlTemplate = self:getSearchUrlTemplate()
  self.model = SearchModel()

  self.model:addListener("hotSearchLoaded", function(items)
    if self.hotAdapter then self.hotAdapter.notifyDataSetChanged() end
  end)

  self.model:addListener("suggestLoaded", function(items)
    if self.suggestAdapter then self.suggestAdapter.notifyDataSetChanged() end
  end)
end

function SearchFragment:onResume()
  self:loadHistory()
end

function SearchFragment:onDestroy()
  if self.model then
    self.model:destroy()
    self.model = nil
  end
end

function SearchFragment:getSearchUrlTemplate()
  return Extensions.Config.getString(Constants.SharedDataKeys.SEARCH_URL_TEMPLATE)
end

function SearchFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.search.main, self.views)
end

function SearchFragment:initViews()
  self.searchView = self.views.search_view

  -- 懒得搞了，偷懒做法qaq
  self:setupEdgeToEdge({
    top = { self.views.main_container },
    bottom = { self.views.main_container },
  })

  self:setupToolbar()
  self:setupSearchView()

  -- 初始化自动对焦并弹出键盘
  self.searchView.focusable = true
  self.searchView.requestFocus()
  local InputMethodManager = luajava.bindClass("android.view.inputmethod.InputMethodManager")
  task(100, function()
    local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
    imm.toggleSoftInput(InputMethodManager.SHOW_IMPLICIT, InputMethodManager.HIDE_NOT_ALWAYS);
  end)

  self:setupAdapter("hot", self.views.hot_grid)
  self:setupAdapter("suggest", self.views.suggest_list)
  self:setupHistory()
  self.model:loadHotSearch()
end

function SearchFragment:setupToolbar()
  Helpers.UI.setupToolbar(self.views.toolbar, { title = "搜索" })
end

function SearchFragment:setupSearchView()
  if not self.searchView then return end

  -- 美化 SearchView
  local androidxR = luajava.bindClass("androidx.appcompat.R")

  -- 始终展开
  self.searchView.iconifiedByDefault = false

  -- 去掉下划线
  local searchPlate = self.searchView.findViewById(androidxR.id.search_plate)
  if searchPlate then searchPlate.backgroundColor = 0 end

  -- 去掉默认搜索图标
  local searchIcon = self.searchView.findViewById(androidxR.id.search_mag_icon)
  if searchIcon then searchIcon.parent.removeView(searchIcon) end

  -- 美化清除按钮
  local closeBtn = self.searchView.findViewById(androidxR.id.search_close_btn)
  if closeBtn then
    local primaryColor = AppTheme.colors.primary
    closeBtn.colorFilter = primaryColor

    local size = dp2px(32)
    local params = closeBtn.layoutParams
    params.width = size
    params.height = size
    local margin = dp2px(8)
    params.setMargins(margin, margin, margin, margin)
    closeBtn.layoutParams = params

    local padding = dp2px(4)
    closeBtn.setPadding(padding, padding, padding, padding)

    local closeBitmap = Helpers.Static.materialIcon("close")
    if closeBitmap then closeBtn.imageBitmap = closeBitmap end
  end

  -- 搜索监听
  self.searchView.setOnQueryTextListener({
    onQueryTextSubmit = function(query)
      local q = tostring(query):gsub(" ", "")
      if q ~= "" then self:performSearch(q) end
      return true
    end,
    onQueryTextChange = function(newText)
      local text = tostring(newText):gsub("[\n ]", "")
      if #text > 0 then
        self.views.main_content.visibility = View.GONE
        self.views.suggest_list.visibility = View.VISIBLE
        self.model:loadSuggest(text)
       else
        self.views.main_content.visibility = View.VISIBLE
        self.views.suggest_list.visibility = View.GONE
      end
      return false
    end
  })
end

function SearchFragment:performSearch(query)
  Router.go("browser", { url = self.searchUrlTemplate .. NetWork.urlEncode(query) })

  SearchHistoryService.add(query)
  self.searchView.setQuery("", false)
  -- 收起键盘
  local InputMethodManager = luajava.bindClass("android.view.inputmethod.InputMethodManager")
  local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
  local token = self.searchView.getWindowToken()
  if token then
    imm.hideSoftInputFromWindow(token, 0)
  end
end

function SearchFragment:setupAdapter(dataType, containerView)
  if not containerView then return end

  local getItems = dataType == "hot"
  and function() return self.model:getHotItems() end
  or function() return self.model:getSuggestItems() end

  local adapterKey = dataType == "hot" and "hotAdapter" or "suggestAdapter"

  local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")
  local adapter = SimpleRecyclerAdapter.new({
    items = getItems(),
    getItemViewType = function(position, item)
      return 0
    end,
    onCreateView = function(viewType)
      return SimpleRecyclerAdapter.inflate(Layouts.cards.search_suggestion)
    end,
    onBind = function(views, item, position, holder)
      views.text.text = tostring(item)
    end,
  })

  self[adapterKey] = adapter
  containerView.adapter = adapter

  if adapterKey == "hotAdapter" then
    local hotGridLayoutManager = GridLayoutManager(activity, 2)
    containerView.layoutManager = hotGridLayoutManager
   else
    local suggestLayoutManager = LinearLayoutManager(activity, RecyclerView.VERTICAL, false)
    containerView.layoutManager = suggestLayoutManager
  end

  -- GridView/RecyclerView 的点击处理
  import "android.view.GestureDetector"
  local gestureDetector = GestureDetector(activity, {
    onSingleTapUp = function(e)
      local child = containerView.findChildViewUnder(e.X, e.Y)
      if child then
        local pos = containerView.getChildAdapterPosition(child)
        if pos ~= -1 then
          local item = getItems()[pos + 1]
          if item then self:performSearch(item) end
          return true
        end
      end
      return false
    end,
  })

  containerView.addOnItemTouchListener({
    onInterceptTouchEvent = function(rv, e)
      return gestureDetector.onTouchEvent(e)
    end,
    onTouchEvent = function(rv, e) end,
    onRequestDisallowInterceptTouchEvent = function(disallow) end
  })
end

function SearchFragment:setupHistory()
  self.views.clear_btn.onClick = function()
    SearchHistoryService.clearAll()
    self.views.chip_group.removeAllViews()
  end
end

function SearchFragment:loadHistory()
  local chipGroup = self.views.chip_group
  if not chipGroup then return end
  chipGroup.removeAllViews()
  for _, item in ipairs(SearchHistoryService.getAll()) do
    chipGroup.addView(self:createChip(item.value(), item.id()))
  end
end

function SearchFragment:createChip(text, id)
  local chip = Chip(activity)
  chip.text = text
  chip.checkable = false
  chip.closeIconVisible = true
  chip.ensureMinTouchTargetSize = false
  chip.onClick = function()
    self:performSearch(text)
  end
  chip.setOnCloseIconClickListener({ onClick = function()
      SearchHistoryService.remove(id)
      self:loadHistory()
  end })
  return chip
end

return SearchFragment