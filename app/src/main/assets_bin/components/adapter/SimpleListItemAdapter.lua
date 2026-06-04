-- components/adapter/SimpleListItemAdapter.lua
-- 基于 LuaListItemAdapter 的 Material 3 列表适配器
-- 自动处理分段圆角，分组逻辑由外部传入

import "com.hydrogen.adapter.LuaListItemAdapter"

local M = {}

-- 创建适配器
function M.new(config)
  local items = config.items or {}
  local onCreateView = config.onCreateView
  local onBind = config.onBind
  local getItemViewType = config.getItemViewType or function(item, position) return 0 end
  -- 外部传入的分组函数：返回 sectionId
  local getSectionId = config.getSectionId
  
  -- 如果没有传入分组函数，所有 item 属于同一个段落
  local hasSectionId = getSectionId ~= nil

  -- 计算指定位置在段落中的位置
  local function computeSectionInfo(position)
    if not hasSectionId then
      -- 没有分组，整个列表作为一个段落
      return position, #items
    end
    
    local currentId = getSectionId(position, items[position + 1])
    local sectionStart = position
    local sectionEnd = position

    -- 向前找段落开始
    for i = position - 1, 0, -1 do
      local itemId = getSectionId(i, items[i + 1])
      if itemId == currentId then
        sectionStart = i
      else
        break
      end
    end

    -- 向后找段落结束
    for i = position + 1, #items - 1 do
      local itemId = getSectionId(i, items[i + 1])
      if itemId == currentId then
        sectionEnd = i
      else
        break
      end
    end

    return position - sectionStart, sectionEnd - sectionStart + 1
  end

  local creator = luajava.createProxy("com.hydrogen.adapter.LuaListItemAdapter$Creator", {
    getItemCount = function()
      return #items
    end,

    getItemViewType = function(position)
      return getItemViewType(position, items[position + 1])
    end,

    onCreateViewHolder = function(parent, viewType)
      local view, views = onCreateView(viewType)
      local holder = LuaListItemAdapter.LuaListItemHolder(view)
      holder.views = views or {}
      return holder
    end,

    onBindViewHolder = function(holder, position)
      local item = items[position + 1]
      local views = holder.views

      -- 计算分段位置
      local posInSection, sectionSize = computeSectionInfo(position)
      
      -- 调用 holder.bind 自动处理圆角
      holder.bind(posInSection, sectionSize)
      
      if onBind then
        onBind(views, item, position, posInSection, sectionSize)
      end
    end,
  })

  local adapter = LuaListItemAdapter(activity, creator)
  return adapter
end

-- 辅助方法：从 layout 模板创建 view 和 views
function M.inflate(layout)
  local views = {}
  local view = loadlayout(layout, views)
  return view, views
end

return M