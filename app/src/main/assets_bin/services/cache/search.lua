-- services/cache/search.lua
-- 搜索历史

local M = {}

local SearchHistoryManager = nil
local initialized = false

-- 初始化
function M.init()
    if initialized then return end
    
    local SearchHistoryManagerClass = luajava.bindClass("com.hydrogen.HistoryUtils.SearchHistoryManager")
    SearchHistoryManager = SearchHistoryManagerClass.getInstance()
    SearchHistoryManager.init(activity)
    initialized = true
end

-- 添加搜索历史
function M.add(content)
    M.init()
    content = tostring(content)
    SearchHistoryManager.add(content)
end

-- 获取所有搜索历史
function M.getAll()
    M.init()
    return luajava.astable(SearchHistoryManager.getRecentFirst())
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
    return #M.getAll()
end

-- 获取最近N条
function M.getRecent(limit)
    M.init()
    local all = M.getAll()
    limit = limit or 10
    local results = {}
    for i = 1, math.min(limit, #all) do
        table.insert(results, all[i])
    end
    return results
end

-- 搜索建议（匹配历史）
function M.suggest(keyword)
    M.init()
    if not keyword or keyword == "" then
        return M.getRecent(10)
    end
    
    local all = M.getAll()
    local results = {}
    for _, item in ipairs(all) do
        if item.value:find(keyword) then
            table.insert(results, item)
        end
    end
    return results
end

return M