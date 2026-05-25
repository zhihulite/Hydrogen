-- components/adapter/SimpleBaseAdapter.lua
-- 用于 ListView 的通用适配器，提供类似于 SimpleRecyclerAdapter 的接口

import "com.google.android.material.textview.MaterialTextView"
import "android.widget.BaseAdapter"

local SimpleBaseAdapter = {}

--- 创建一个新的适配器实例
--- @param config table 配置项
---   - config.items table 数据列表
---   - config.onCreateView function 创建视图的函数 function() return layout end
---   - config.onBind function 绑定数据 function(views, item, position, view)
---   - config.getItemViewType function|nil 自定义视图类型 function(position, item) return 0 end
---   - config.getViewTypeCount number|nil 视图类型总数，默认 1
--- @return table 适配器对象（包含 items、notifyDataSetChanged 等方法）
function SimpleBaseAdapter.new(config)
  local items = config.items or {}
  local onCreateView = config.onCreateView
  local onBind = config.onBind
  local getItemViewType = config.getItemViewType or function() return 0 end
  local viewTypeCount = config.getViewTypeCount or 1

  -- 缓存每种 viewType 对应的布局，避免每次都调用 onCreateView
  local layoutCache = {}

  -- 创建适配器
  local adapter = luajava.override(BaseAdapter, {
    -- 必须返回 int
    getCount = function(super)
      return int(#items)
    end,

    getItem = function(super, position)
      return items[position + 1]
    end,
    -- 必须返回 long
    getItemId = function(super, position)
      return long(position)
    end,
    -- 必须返回 int
    getViewTypeCount = function(super)
      return int(viewTypeCount)
    end,
    -- 必须返回 int
    getItemViewType = function(super, position)
      local item = items[position + 1]
      return int(getItemViewType(position, item))
    end,

    getView = function(super, position, convertView, parent)
      local item = items[position + 1]
      if item == nil then
        local emptyView = MaterialTextView(activity)
        emptyView.setText("View 为空")
        return emptyView
      end

      local viewType = getItemViewType(position, item)
      local layout = layoutCache[viewType]
      if not layout then
        layout = onCreateView(viewType)
        layoutCache[viewType] = layout
      end

      local view, views
      if convertView == nil then
        -- 新视图
        views = {}
        view = loadlayout(layout, views)
        view.setTag(views) -- 存储绑定信息以便复用
       else
        view = convertView
        views = view.getTag()
      end

      if onBind then
        onBind(views, item, position, view)
      end

      return view
    end,
  })

  return adapter
end

--- 快捷方法：从布局表直接创建视图（与 SimpleRecyclerAdapter 用法一致）
--- @param layout table 布局表
--- @return View
function SimpleBaseAdapter.inflate(layout)
  return loadlayout(layout)
end

return SimpleBaseAdapter