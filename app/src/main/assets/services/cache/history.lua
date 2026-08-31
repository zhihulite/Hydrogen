-- services/cache/history.lua
-- 记录历史记录

local M = {}

local HistoryManagerClass = luajava.bindClass("com.hydrogen.history.HistoryManager")

local HistoryManager = nil
local initialized = false

-- 初始化
function M.init()
  if initialized then return end

  HistoryManager = HistoryManagerClass.instance
  HistoryManager.init(activity)
  initialized = true
end

-- 添加历史记录
-- @param id string 内容ID
-- @param title string 标题
-- @param preview string 预览文本
-- @param type string 规范类型（answer/pin/article/question/people/zvideo 等）
-- @return boolean 是否已写入；类型不在支持列表中时跳过并返回 false
function M.add(id, title, preview, type)
  -- 调用点多处于网络回调内，未登记的类型只跳过，保证回调后续逻辑继续执行
  if not HistoryManagerClass.isKnownType(type) then
    print("跳过不支持的历史记录类型: " .. tostring(type))
    return false
  end

  M.init()
  HistoryManager.add(tostring(id), title, HistoryManagerClass.truncatePreview(preview), type)
  M.syncToServer(id, type)
  return true
end

-- 服务器提交历史记录
-- @param id string 内容ID (content_token)
-- @param type string 规范类型
-- @param readProgress number|nil 阅读进度（可选）
-- @param options table|nil 可选参数 { listen_progress, read_time, custom_content_data, callback }
function M.syncToServer(id, type, readProgress, options)
  if not HistoryManagerClass.isKnownType(type) then
    if options and options.callback then
      options.callback(false, "不支持服务器提交的类型: " .. type)
    end
    return false
  end

  if not id or not type then
    if options and options.callback then
      options.callback(false, "id和type参数不能为空")
    end
    return false
  end

  options = options or {}

  readProgress = readProgress or 0
  local listenProgress = options.listen_progress or 0
  local readTime = options.read_time or os.time()
  local customContentData = options.custom_content_data

  -- 服务器的类型串与本地规范类型不完全同名（people 对应 profile）
  local serverType = HistoryManagerClass.toServerType(type)

  local jsonData = string.format(
  '{"content_token":"%s","content_type":"%s","read_progress":%d,"listen_progress":%d,"read_time":%d,"custom_content_data":%s}',
  tostring(id),
  serverType,
  readProgress,
  listenProgress,
  readTime,
  customContentData and json.encode(customContentData) or "null"
  )

  NetWork.post(
  "https://api.zhihu.com/read_history/add",
  jsonData,
  nil,
  function(code, content)
    if code == 200 then
      if options.callback then
        options.callback(true)
      end
     else
      if options.callback then
        options.callback(false, "请求失败，状态码：" .. tostring(code))
      end
    end
  end
  )

  return true
end

-- 获取所有历史记录（新->旧，类型已转规范类型，预览已截断）
function M.getAll()
  M.init()
  return luajava.astable(HistoryManager.recentFirst)
end

-- 删除历史记录
-- @param id string 内容ID
-- @param type string 规范类型
function M.remove(id, type)
  M.init()
  HistoryManager.remove(id, type)
end

-- 清除所有历史记录
function M.clearAll()
  M.init()
  HistoryManager.clearAll()
end

-- 获取数量
function M.getCount()
  M.init()
  return HistoryManager.size()
end

-- 搜索历史记录
-- @param keyword string 搜索关键词
-- @param type string|nil 规范类型（可选，指定后只搜索该类型）
function M.search(keyword, type)
  M.init()
  if type then
    local results = {}
    for _, item in ipairs(luajava.astable(HistoryManager.search(keyword))) do
      if item.type == type then
        table.insert(results, item)
      end
    end
    return results
  end
  return luajava.astable(HistoryManager.search(keyword))
end

-- 按类型筛选
-- @param type string 规范类型
function M.filterByType(type)
  M.init()
  return luajava.astable(HistoryManager.filterByType(type))
end

return M