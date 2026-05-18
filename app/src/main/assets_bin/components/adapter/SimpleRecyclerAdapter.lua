-- components/adapter/SimpleRecyclerAdapter.lua
-- 简洁的 RecyclerView 适配器

local M = {}

import "com.hydrogen.adapter.LuaCustRecyclerAdapter"
import "com.hydrogen.adapter.LuaCustRecyclerHolder"

-- 创建适配器
function M.new(config)
  local items = config.items or {}
  local onBind = config.onBind
  local getItemViewType = config.getItemViewType or function() return 0 end
  local onCreateView = config.onCreateView

  if not onCreateView then
    error("必须提供 onCreateView 参数")
  end

  local adapter = LuaCustRecyclerAdapter(activity, LuaCustRecyclerAdapter.Creator({
    getItemCount = function()
      return #items
    end,

    getItemViewType = function(position)
      return getItemViewType(position, items[position + 1])
    end,

    onCreateViewHolder = function(parent, viewType)
      local view, views = onCreateView(viewType)
      local holder = LuaCustRecyclerHolder(view)
      holder.views = views or {}
      return holder
    end,

    onBindViewHolder = function(holder, position)
      local item = items[position + 1]

      if onBind then
        onBind(holder.views, item, position, holder)
       else
        M.defaultBind(holder.views, item)
      end
    end,
  }))

  return adapter
end

-- 辅助方法：从 layout 模板创建 view 和 views
function M.inflate(layout)
  local views = {}
  local view = loadlayout(layout, views)
  return view, views
end

return M