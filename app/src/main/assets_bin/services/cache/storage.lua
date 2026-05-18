-- services/cache/storage.lua
-- 存储数据

local M = {}

-- 存储目录
local STORAGE_DIR = nil

-- 初始化存储目录
function M.init()
  if STORAGE_DIR then return end
  STORAGE_DIR = Extensions.File.getAppDir("storage")
  if not Extensions.File.exists(STORAGE_DIR) then
    Extensions.File.mkdir(STORAGE_DIR)
  end
end

-- 获取文件路径
local function getFilePath(key)
  M.init()
  return STORAGE_DIR .. "/" .. key:gsub("[^%w]", "_") .. ".json"
end

-- 保存数据
function M.set(key, value)
  local path = getFilePath(key)
  local content = json.encode(value)
  Extensions.File.write(path, content)
  return true
end

-- 读取数据
function M.get(key, defaultValue)
  local path = getFilePath(key)
  if not Extensions.File.exists(path) then
    return defaultValue
  end

  local content = Extensions.File.read(path)
  if content == "" then
    return defaultValue
  end

  local success, result = pcall(json.decode, content)
  if success then
    return result
  end
  return defaultValue
end

-- 删除数据
function M.delete(key)
  local path = getFilePath(key)
  if Extensions.File.exists(path) then
    Extensions.File.delete(path)
  end
  return true
end

-- 检查是否存在
function M.has(key)
  local path = getFilePath(key)
  return Extensions.File.exists(path)
end

-- 获取所有键
function M.keys()
  M.init()
  local files = Extensions.File.list(STORAGE_DIR, false)
  local keys = {}
  for _, file in ipairs(files) do
    local name = file:match("([^/]+)%.json$")
    if name then
      table.insert(keys, name)
    end
  end
  return keys
end

-- 清除所有数据
function M.clear()
  M.init()
  local files = Extensions.File.list(STORAGE_DIR, false)
  for _, file in ipairs(files) do
    Extensions.File.delete(file)
  end
  return true
end

-- 获取存储大小
function M.getSize()
  M.init()
  return Extensions.File.getDirSize(STORAGE_DIR)
end

-- 保存用户设置
function M.saveSettings(settings)
  return M.set("user_settings", settings)
end

-- 读取用户设置
function M.loadSettings(defaults)
  local settings = M.get("user_settings", {})
  if defaults then
    for k, v in pairs(defaults) do
      if settings[k] == nil then
        settings[k] = v
      end
    end
  end
  return settings
end

-- 保存应用状态
function M.saveState(state)
  return M.set("app_state", state)
end

-- 读取应用状态
function M.loadState()
  return M.get("app_state", {})
end

return M