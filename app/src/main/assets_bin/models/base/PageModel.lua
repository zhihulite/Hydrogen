-- models/base/PageModel.lua
-- 静态列表模型 - 适用于一次性加载或自定义分页的列表
-- 子类必须实现：createAdapter()、getFirstPageUrl()、parseResponse()
-- 子类可选实现：getNextPageUrl()（支持分页时实现）、enableLoadMore（默认 false）

local BaseModel = require("models.base.BaseModel")
import "androidx.recyclerview.widget.LinearLayoutManager"

local PageModel = Extensions.Class(BaseModel)
PageModel:chainUp("destroy")

function PageModel:ctor()
  self.items = {} -- 列表数据
  self.recyclerView = nil -- RecyclerView 实例
  self.adapter = nil -- 适配器实例
  self.swipeRefresh = nil -- 下拉刷新组件
  self.isLoading = false -- 是否正在加载
  self.hasLoaded = false -- 是否已加载过数据
  self.needCheckFullPage = true -- 是否需要检查不满屏自动加载更多
  self.enableLoadMore = false -- 是否允许上拉加载更多，默认 false
  self.hasNextPage = true -- 是否还有下一页
end

-- 子类必须实现：创建适配器
-- @return SimpleRecyclerAdapter 实例
function PageModel:createAdapter()
  error("子类必须实现 createAdapter()")
end

-- 子类必须实现：获取首页 URL（首次加载或下拉刷新时调用）
-- @param params table 请求参数（refresh=true 表示刷新）
-- @return string URL
function PageModel:getFirstPageUrl(params)
  error("子类必须实现 getFirstPageUrl()")
end

-- 子类可选实现：获取下一页 URL（上拉加载更多时调用，需要 enableLoadMore = true）
-- @param params table 请求参数（loadMore=true 表示加载更多）
-- @return string|nil 下一页 URL，返回 nil 表示没有更多数据
function PageModel:getNextPageUrl(params)
  return nil
end

-- 子类可选实现：解析响应数据
-- @param response table 解码后的 JSON 响应
-- @param params table 请求参数（包含 refresh、loadMore 等标识）
-- @return table 解析后的数据列表
function PageModel:parseResponse(response, params)
  return response.data or {}
end

-- 初始化视图
-- @param recyclerView RecyclerView 实例
-- @param swipeRefresh SwipeRefreshLayout 实例（可选）
function PageModel:init(recyclerView, swipeRefresh)
  self.recyclerView = recyclerView
  self.swipeRefresh = swipeRefresh

  self.recyclerView.setLayoutManager(LinearLayoutManager(activity))
  self.adapter = self:createAdapter()
  self.recyclerView.setAdapter(self.adapter)

  if self.swipeRefresh then
    Helpers.UI.setupSwipeRefresh(self.swipeRefresh, function()
      self:refresh()
    end)
  end

  if self.enableLoadMore then
    self.recyclerView.addOnScrollListener(RecyclerView.OnScrollListener{
      onScrolled = function(rv, dx, dy)
        if dy > 0 and not self.isLoading and self.hasNextPage then
          local lm = rv.getLayoutManager()
          if lm.findLastVisibleItemPosition() >= self.adapter.getItemCount() - 5 then
            self:loadMore()
          end
        end
      end
    })
  end
end

-- 确保数据已加载（无数据时自动刷新）
function PageModel:ensureLoaded()
  if self.hasLoaded and #self.items > 0 then
    return
  end
  self:refresh()
end

-- 加载数据
-- @param params table 参数
--   - refresh: true 表示下拉刷新，清空数据重新加载
--   - loadMore: true 表示上拉加载更多，追加数据
function PageModel:load(params)
  if self.isLoading then return end

  local isRefresh = params and params.refresh
  local isLoadingMore = params and params.loadMore
  local url

  if isRefresh or (not isLoadingMore and #self.items == 0) then
    url = self:getFirstPageUrl(params)
    if not url then return end
   elseif isLoadingMore then
    url = self:getNextPageUrl(params)
    if not url then
      self.hasNextPage = false
      return
    end
   else
    return
  end

  self.isLoading = true
  if self.swipeRefresh and isRefresh then
    self.swipeRefresh.setRefreshing(true)
  end

  self:fetch(url, params, function(success, data)
    self.isLoading = false
    self.hasLoaded = true

    if self.swipeRefresh then
      self.swipeRefresh.setRefreshing(false)
    end

    if success and data then
      if isRefresh then
        table.clear(self.items)
      end
      for _, item in ipairs(data) do
        table.insert(self.items, item)
      end

      if self.adapter then
        self.adapter.notifyDataSetChanged()
      end

      self.hasNextPage = self:getNextPageUrl(params) ~= nil

      if self.needCheckFullPage then
        self.recyclerView.postDelayed({
          run = function()
            if self:isLastItemVisible() then
              self:loadMore()
             else
              self.needCheckFullPage = false
            end
          end
        }, 50)

      end
    end
  end)
end

-- 下拉刷新
function PageModel:refresh()
  self.needCheckFullPage = true
  self:load({ refresh = true })
end

-- 上拉加载更多
function PageModel:loadMore()
  if self.isLoading or not self.hasNextPage then return end
  self:load({ loadMore = true, offset = #self.items })
end

-- 清空数据
function PageModel:clear()
  table.clear(self.items)
  if self.adapter then
    self.adapter.notifyDataSetChanged()
  end
  self.hasLoaded = false
  self.needCheckFullPage = true
  self.hasNextPage = true
end

-- 检查最后一项是否在屏幕上可见
function PageModel:isLastItemVisible()
  local lm = self.recyclerView.getLayoutManager()
  if not lm then return false end
  local lastVisible = lm.findLastVisibleItemPosition()
  local totalCount = self.adapter and self.adapter.getItemCount() or 0
  return lastVisible >= totalCount - 1
end

-- 获取数据列表
function PageModel:getItems()
  return self.items
end

--- 获取当前页面的 RecyclerView 实例
function PageModel:getCurrentRecyclerView()
  return self.recyclerView
end

--- 获取所有 RecyclerView 实例（兼容 PageToolModel 调用）
function PageModel:getAllRecyclerViews()
  local rvs = {}
  if self.recyclerView then
    table.insert(rvs, self.recyclerView)
  end
  return rvs
end

-- 销毁
function PageModel:destroy()
  self.adapter = nil
  self.recyclerView = nil
  self.swipeRefresh = nil
  self.items = nil
end

return PageModel