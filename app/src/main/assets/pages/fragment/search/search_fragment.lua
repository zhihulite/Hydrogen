-- pages/fragment/search/search_fragment.lua
-- 搜索页面 Fragment

import "androidx.appcompat.widget.SearchView"
import "com.google.android.material.chip.Chip"
import "android.view.View"
import "androidx.recyclerview.widget.RecyclerView"
import "android.content.Context"
import "android.view.GestureDetector"

local InputMethodManager = luajava.bindClass("android.view.inputmethod.InputMethodManager")
local androidxR = luajava.bindClass("androidx.appcompat.R")
local GridLayoutManager = luajava.bindClass("androidx.recyclerview.widget.GridLayoutManager")
local SafeLinearLayoutManager = luajava.bindClass("com.hydrogen.SafeLinearLayoutManager")

local BaseFragment = require("pages.base.base_fragment")
local SearchModel = require("models.search.search_model")
local SearchHistoryService = require("services.cache.search")

local SearchFragment = Extensions.Class(BaseFragment, {"search"})

function SearchFragment:ctor()
  self.searchUrlTemplate = nil
  self.model = nil
  self.hotAdapter = nil
  self.suggestAdapter = nil
  self.searchView = nil
  self.suggestSeq = 0
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
  local views = self.views
  self.searchView = views.search_view

  -- 状态栏与导航栏的 inset 都由 main_container 承接
  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = { views.main_container },
  })

  self:setupToolbar()
  self:setupSearchView()
  self:setupRefreshButton()
  self:setupClearHistoryButton()

  -- 初始化自动对焦并弹出键盘
  self.searchView.focusable = true
  self.searchView.requestFocus()
  Helpers.UI.runDelayed(100, self:runIfAlive(function()
    local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
    imm.toggleSoftInput(InputMethodManager.SHOW_IMPLICIT, InputMethodManager.HIDE_NOT_ALWAYS);
  end))

  self:setupAdapter("hot", views.hot_grid)
  self:setupAdapter("suggest", views.suggest_list)

  -- 判断是否关闭热门搜索
  local closeHotSearch = Extensions.Config.getBool(Constants.SharedDataKeys.CLOSE_HOT_SEARCH)
  if not closeHotSearch then
    self.model:loadHotSearch()
   else
    -- 隐藏热门搜索区域
    views.hot_section.visibility = View.GONE
  end
end

function SearchFragment:setupToolbar()
  Helpers.UI.setupToolbar(self.views.toolbar, { title = "搜索" })
end

function SearchFragment:setupSearchView()
  if not self.searchView then return end

  -- 美化 SearchView

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

    local closeBitmap = Helpers.Static.materialIcon("twotone_close")
    if closeBitmap then closeBtn.imageBitmap = closeBitmap end
  end

  -- 搜索监听
  self.searchView.setOnQueryTextListener(luajava.createProxy(SearchView.OnQueryTextListener, {
    onQueryTextSubmit = function(query)
      local q = tostring(query):match("^%s*(.-)%s*$")
      if q ~= "" then self:performSearch(q) end
      return true
    end,
    onQueryTextChange = function(newText)
      local text = tostring(newText):match("^%s*(.-)%s*$")
      if #text > 0 then
        self.views.main_content.visibility = View.GONE
        self.views.suggest_list.visibility = View.VISIBLE
        -- 输入防抖：序号自增，延迟到期时只有仍是最新序号的那次输入才发请求
        self.suggestSeq = (self.suggestSeq or 0) + 1
        local seq = self.suggestSeq
        Helpers.UI.runDelayed(250, self:runIfAlive(function()
          if seq == self.suggestSeq and self.model then
            self.model:loadSuggest(text)
          end
        end))
       else
        self.views.main_content.visibility = View.VISIBLE
        self.views.suggest_list.visibility = View.GONE
      end
      return false
    end
  }))
end

function SearchFragment:performSearch(query)
  Router.go("browser", { url = self.searchUrlTemplate .. NetWork.urlEncode(query) })

  SearchHistoryService.add(query)
  self:loadHistory()
  self.searchView.setQuery("", false)
  -- 收起键盘
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

  local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
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
    local suggestLayoutManager = SafeLinearLayoutManager(activity, RecyclerView.VERTICAL, false)
    containerView.layoutManager = suggestLayoutManager
  end

  -- GridView/RecyclerView 的点击处理
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

  containerView.addOnItemTouchListener(luajava.createProxy(RecyclerView.OnItemTouchListener, {
    onInterceptTouchEvent = function(rv, e)
      return gestureDetector.onTouchEvent(e)
    end,
    onTouchEvent = function(rv, e) end,
    onRequestDisallowInterceptTouchEvent = function(disallow) end
  }))
end

-- 初始化刷新按钮
function SearchFragment:setupRefreshButton()
  if not self.views.refresh_btn then return end

  self.views.refresh_btn.onClick = function()
    self.model:loadHotSearch()
  end
end

function SearchFragment:setupClearHistoryButton()
  self.views.clear_btn.onClick = function()
    local BottomDialog = require("helpers.bottom_dialog")
    BottomDialog.confirm("确定清空所有搜索历史吗？", function()
      SearchHistoryService.clearAll()
      self:loadHistory()
    end)
  end
end

function SearchFragment:loadHistory()
  local chipGroup = self.views.chip_group
  if not chipGroup then return end
  chipGroup.removeAllViews()
  for _, item in ipairs(SearchHistoryService.getAll()) do
    chipGroup.addView(self:createChip(item.value, item.id))
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
  chip.setOnCloseIconClickListener(luajava.createProxy(View.OnClickListener, { onClick = function()
      SearchHistoryService.remove(id)
      self:loadHistory()
  end }))
  return chip
end

return SearchFragment