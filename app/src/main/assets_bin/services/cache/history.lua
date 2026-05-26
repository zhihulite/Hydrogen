-- services/cache/history.lua
-- 记录历史记录

local M = {}

local HistoryManager = nil
local initialized = false

-- 类型统一配置（规范类型 -> 本地存储中文 / 服务器英文）
local TYPE_CONFIG = {
  answer = { localStr = "回答", serverStr = "answer" },
  pin = { localStr = "想法", serverStr = "pin" },
  article = { localStr = "文章", serverStr = "article" },
  question = { localStr = "问题", serverStr = "question" },
  people = { localStr = "用户", serverStr = "profile" },
  zvideo = { localStr = "视频", serverStr = "zvideo" },
  roundtable = { localStr = "圆桌", serverStr = "roundtable" },
  special = { localStr = "专题", serverStr = "special" },
  collection = { localStr = "收藏", serverStr = "collection" },
  column = { localStr = "专栏", serverStr = "column" },
  podcast_channel = { localStr = "播客频道", serverStr = "podcast_channel" },
  podcast_episode = { localStr = "播客单集", serverStr = "podcast_episode" },
}

-- 反向映射：中文 -> 规范类型
local typeReverseMap = {}
for k, v in pairs(TYPE_CONFIG) do
  typeReverseMap[v.localStr] = k
end

-- 类型列表（供外部使用）
M.TYPES = {}
for k, v in pairs(TYPE_CONFIG) do
  M.TYPES[string.upper(k)] = k
end

--- 将规范类型转换为存储类型（中文）
--- @param type string 规范类型
--- @return string|nil 存储类型，若类型不支持则返回 nil
local function toStorageType(type)
  local cfg = TYPE_CONFIG[type]
  return cfg and cfg.localStr
end

--- 将存储类型（中文）转换为规范类型（英文）
--- @param storageType string 存储类型（中文）
--- @return string|nil 规范类型，若类型不支持则返回 nil
local function toStandardType(storageType)
  return typeReverseMap[storageType]
end

--- 将规范类型转换为服务器提交类型（英文）
--- @param type string 规范类型
--- @return string|nil 服务器类型，若类型不支持则返回 nil
local function toServerType(type)
  local cfg = TYPE_CONFIG[type]
  return cfg and cfg.serverStr
end

--- 截取预览文本前100字符
--- @param preview string 原始预览文本
--- @return string 截取后的文本
local String = luajava.bindClass("java.lang.String")
local function truncatePreview(preview)
  if not preview or preview == "" then
    return ""
  end

  local javaStr = String(preview)
  if javaStr.length() > 100 then
    return javaStr.substring(0, 100) .. "..."
  end
  return preview
end

-- 初始化
function M.init()
  if initialized then return end

  local HistoryManagerClass = luajava.bindClass("com.hydrogen.HistoryUtils.HistoryManager")
  HistoryManager = HistoryManagerClass.instance
  HistoryManager.init(activity)
  initialized = true
end

-- 添加历史记录
-- @param id string 内容ID
-- @param title string 标题
-- @param preview string 预览文本
-- @param type string 规范类型（answer/pin/article/question/people/video）
-- @error 当类型不在支持列表中时抛出错误
function M.add(id, title, preview, type)
  if not TYPE_CONFIG[type] then
    error("不支持的历史记录类型: " .. type)
  end

  M.init()
  id = tostring(id)
  preview = truncatePreview(preview)
  HistoryManager.add(id, title, preview, toStorageType(type))
  M.syncToServer(id, type)
end

-- 服务器提交历史记录
-- @param id string 内容ID (content_token)
-- @param type string 规范类型 (answer/pin/article/question/people/video)
-- @param readProgress number|nil 阅读进度（可选，第三个参数）
-- @param options table|nil 可选参数 { listen_progress, read_time, custom_content_data, callback }
function M.syncToServer(id, type, readProgress, options)
  if not TYPE_CONFIG[type] then
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

  local serverType = toServerType(type)
  readProgress = readProgress or 0
  local listenProgress = options.listen_progress or 0
  local readTime = options.read_time or os.time()
  local customContentData = options.custom_content_data

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

-- 获取所有历史记录（过滤并转换类型为英文，预览截取100字符）
function M.getAll()
  M.init()
  local rawData = luajava.astable(HistoryManager.recentFirst)
  local results = {}

  for _, item in ipairs(rawData) do
    local standardType = toStandardType(item.type)
    if standardType and TYPE_CONFIG[standardType] then
      table.insert(results, {
        id = item.id,
        title = item.title,
        preview = item.preview or "",
        type = standardType,
      })
    end
  end

  return results
end

-- 删除历史记录
-- @param id string 内容ID
-- @param type string 规范类型（answer/pin/article/question/people/video）
function M.remove(id, type)
  M.init()
  HistoryManager.remove(id, toStorageType(type))
end

-- 清除所有历史记录
function M.clearAll()
  M.init()
  HistoryManager.clearAll()
end

-- 获取数量
function M.getCount()
  M.init()
  return #M.getAll()
end

-- 搜索历史记录
-- @param keyword string 搜索关键词
-- @param type string|nil 规范类型（可选，指定后只搜索该类型）
function M.search(keyword, type)
  M.init()
  local all = M.getAll()
  local results = {}

  for _, item in ipairs(all) do
    local content = (item.title or "") .. " " .. (item.preview or "")
    if content:find(keyword) then
      if type then
        if item.type == type then
          table.insert(results, item)
        end
       else
        table.insert(results, item)
      end
    end
  end
  return results
end

-- 按类型筛选
-- @param type string 规范类型（answer/pin/article/question/people/video）
function M.filterByType(type)
  M.init()
  if not TYPE_CONFIG[type] then
    return {}
  end

  local all = M.getAll()
  local results = {}
  for _, item in ipairs(all) do
    if item.type == type then
      table.insert(results, item)
    end
  end
  return results
end

return M