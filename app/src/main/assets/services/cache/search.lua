-- services/cache/search.lua
-- 搜索历史

local M = {}

local SearchHistoryManagerClass = luajava.bindClass("com.hydrogen.history.SearchHistoryManager")

local SearchHistoryManager = nil
local initialized = false

-- 初始化
function M.init()
  if initialized then return end
  SearchHistoryManager = SearchHistoryManagerClass.instance
  SearchHistoryManager.init(activity)
  initialized = true
end

-- 添加搜索历史
function M.add(content)
  M.init()
  SearchHistoryManager.add(tostring(content))
end

-- 获取所有搜索历史
function M.getAll()
  M.init()
  return luajava.astable(SearchHistoryManager.recentFirst)
end

-- 删除搜索历史
function M.remove(id)
  M.init()
  SearchHistoryManager.remove(id)
end

-- 清除所有搜索历史
function M.clearAll()
  M.init()
  SearchHistoryManager.clearAll()
end

-- 获取数量
function M.getCount()
  M.init()
  return SearchHistoryManager.size()
end

-- 获取最近N条
function M.getRecent(limit)
  M.init()
  return luajava.astable(SearchHistoryManager.getRecent(limit or 10))
end

-- 搜索建议（匹配历史；空关键词返回最近10条）
function M.suggest(keyword)
  M.init()
  if not keyword or keyword == "" then
    return M.getRecent(10)
  end
  return luajava.astable(SearchHistoryManager.search(keyword))
end

return M
