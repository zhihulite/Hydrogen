-- extensions/config.lua
local M = {}

-- 必须这么写，否则直接赋值报错。
local getSharedData = function(key)
  return activity.getSharedData(key)
end

local setSharedData = function(key, value)
  return activity.setSharedData(key, value)
end

local defaultConfig = {}

-- 判断值是否有效（非 nil 且非空字符串）
local function isValidValue(val)
  return val ~= nil and val ~= ""
end

-- 初始化默认配置
function M.init(defaults)
  defaultConfig = defaults or {}
  for key, defaultVal in pairs(defaultConfig) do
    -- 只有默认值有效才继续
    if isValidValue(defaultVal) then
      -- 只有当存储值无效（nil或空字符串）时才设置默认值
      if not isValidValue(M.getRaw(key)) then
        M.set(key, defaultVal)
      end
    end
  end
end

-- 获取原始存储值（不经过默认值处理）
function M.getRaw(key)
  return getSharedData(key)
end

-- 获取配置
function M.get(key)
  local val = getSharedData(key)
  if isValidValue(val) then return val end
  local defaultValue = defaultConfig[key]
  return isValidValue(defaultValue) and defaultValue or nil
end


-- 设置配置
function M.set(key, value)
  if value == nil then
    setSharedData(key, nil)
   else
    setSharedData(key, tostring(value))
  end
end

-- 获取布尔值
function M.getBool(key, defaultValue)
  local val = M.get(key)
  if not isValidValue(val) then
    return defaultValue or false
  end
  return val == "true"
end

-- 获取数字（整数或浮点数）
function M.getNumber(key, defaultValue)
  local val = M.get(key)
  if not isValidValue(val) then
    return defaultValue
  end
  local num = tonumber(val)
  return num ~= nil and num or defaultValue
end

-- 判断配置是否存在（是否有有效值）
function M.has(key)
  local val = getSharedData(key)
  if isValidValue(val) then
    return true
  end
  return isValidValue(defaultConfig[key])
end

-- 获取字符串（空字符串返回默认值）
function M.getString(key, defaultValue)
  local val = M.get(key)
  return isValidValue(val) and tostring(val) or defaultValue
end

-- 删除配置
function M.delete(key)
  setSharedData(key, nil)
end

-- 清除所有配置
function M.clear()
  for key in pairs(defaultConfig) do
    M.delete(key)
  end
end

return M