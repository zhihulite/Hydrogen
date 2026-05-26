-- components/views/RecyclerViewHelper.lua
-- RecyclerView Header/Footer 辅助类

local M = {}

import "androidx.recyclerview.widget.ConcatAdapter"
import "com.hydrogen.adapter.LuaCustRecyclerAdapter"
import "com.hydrogen.adapter.LuaCustRecyclerHolder"

-- ============================================
-- 创建单个视图的适配器
-- ============================================

local function createViewAdapter(view, views, viewType)
  return LuaCustRecyclerAdapter(activity, LuaCustRecyclerAdapter.Creator({
    getItemCount = function()
      return 1
    end,

    getItemViewType = function()
      return viewType
    end,

    onCreateViewHolder = function(parent, vt)
      local holder = LuaCustRecyclerHolder(view)
      holder.views = views or {}
      return holder
    end,

    onBindViewHolder = function(holder, position)
      -- 静态视图不需要绑定数据
    end,
  }))
end

-- ============================================
-- 创建带 Header/Footer 的适配器包装器
-- ============================================

function M.new(adapter)
  local self = {
    adapter = adapter,
    headerAdapters = {},
    footerAdapters = {},
    concatAdapter = nil,
    recyclerView = nil,
  }

  setmetatable(self, { __index = M })

  if not adapter then
    error("adapter 必须绑定")
  end

  return self
end

-- ============================================
-- Header/Footer 管理
-- ============================================

--- 添加 Header
function M:addHeader(view, views)
  local index = #self.headerAdapters
  local viewType = -1000000 - index
  local adapter = createViewAdapter(view, views, viewType)
  table.insert(self.headerAdapters, adapter)

  if self.concatAdapter then
    -- 插入到头部位置（Headers 连续排列）
    self.concatAdapter.addAdapter(index, adapter)
  end

  return self
end

--- 添加 Footer
function M:addFooter(view, views)
  local index = #self.footerAdapters
  local viewType = -2000000 - index
  local adapter = createViewAdapter(view, views, viewType)
  table.insert(self.footerAdapters, adapter)

  if self.concatAdapter then
    -- Footer 在内容适配器之后
    local position = #self.headerAdapters + 1 + #self.footerAdapters - 1
    self.concatAdapter.addAdapter(position, adapter)
  end

  return self
end

--- 移除 Header
function M:removeHeader(index)
  local adapter = table.remove(self.headerAdapters, index)
  if self.concatAdapter and adapter then
    self.concatAdapter.removeAdapter(index - 1)
  end
  return self
end

--- 移除 Footer
function M:removeFooter(index)
  local adapter = table.remove(self.footerAdapters, index)
  if self.concatAdapter and adapter then
    local position = #self.headerAdapters + 1 + index - 1
    self.concatAdapter.removeAdapter(position)
  end
  return self
end

--- 清空所有 Header
function M:clearHeaders()
  for i = #self.headerAdapters, 1, -1 do
    self:removeHeader(i)
  end
  return self
end

--- 清空所有 Footer
function M:clearFooters()
  for i = #self.footerAdapters, 1, -1 do
    self:removeFooter(i)
  end
  return self
end

-- ============================================
-- 获取包装后的适配器
-- ============================================

function M:getAdapter()
  if self.concatAdapter then
    return self.concatAdapter
  end

  local adapters = {}

  -- Headers
  for _, adapter in ipairs(self.headerAdapters) do
    table.insert(adapters, adapter)
  end

  -- 内容
  table.insert(adapters, self.adapter)

  -- Footers
  for _, adapter in ipairs(self.footerAdapters) do
    table.insert(adapters, adapter)
  end

  self.concatAdapter = ConcatAdapter(adapters)

  return self.concatAdapter
end

-- ============================================
-- 设置到 RecyclerView（自动保存引用）
-- ============================================

function M:setup(recyclerView)
  self.recyclerView = recyclerView
  recyclerView.adapter = self:getAdapter()
  return self
end

-- ============================================
-- 获取原始适配器
-- ============================================

function M:getOriginalAdapter()
  return self.adapter
end

-- ============================================
-- 刷新 Header/Footer 内容（如果视图内容变化）
-- ============================================

function M:notifyHeaderChanged(index)
  if self.headerAdapters[index] then
    self.headerAdapters[index].notifyDataSetChanged()
  end
end

function M:notifyFooterChanged(index)
  if self.footerAdapters[index] then
    self.footerAdapters[index].notifyDataSetChanged()
  end
end

return M