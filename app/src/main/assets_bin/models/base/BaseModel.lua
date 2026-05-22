-- models/base/BaseModel.lua
-- 纯数据层基类，提供网络请求、数据缓存、事件监听能力

local BaseModel = Extensions.Class()

function BaseModel:ctor()
  self.data = nil -- 解析后的数据
  self.isLoading = false -- 是否正在加载
  self.isLoaded = false -- 是否已加载过
  self.error = nil -- 错误信息
  self.listeners = {} -- 事件监听器
  self.needLogin = false -- 是否需要登录
  self.requestHeadKey = "defaultHead" -- 请求头 key (对应 _G.Headers)
  self.urlProcessor = nil -- URL/Headers 预处理函数 function(url, headers) return newUrl, newHeaders end
  self.isDestroyed = false -- 新增：销毁标志，防止销毁后回调执行
end

--- 检测 Model 是否未被销毁
--- @return boolean
function BaseModel:isAlive()
  return not self.isDestroyed
end

--- 安全执行回调（如果 Model 已销毁则不执行）
--- @param callback function 需要安全执行的回调函数
--- @return function 包装后的函数
function BaseModel:runIfAlive(callback)
  if type(callback) ~= "function" then
    error("BaseModel:runIfAlive 必须为 function 类型")
  end
  return function(...)
    if self:isAlive() then
      return callback(...)
    end
  end
end

--- 子类必须实现：自定义加载逻辑（一般不直接调用，由 fetch 或子类实现）
--- @param params table 加载参数（自定义，如 offset, refresh 等）
--- @param callback function 回调函数 function(success, data, code)
function BaseModel:load(params, callback)
  error("子类必须实现 load(params, callback) 方法")
end

--- 获取请求 URL（子类可重写，供 fetch 使用）
--- @param params table 请求参数
--- @return string|nil URL
function BaseModel:getUrl(params)
  return nil
end

--- 获取请求头（子类可重写）
--- @param params table 请求参数
--- @return table headers
function BaseModel:getHeaders(params)
  local headers = Headers[self.requestHeadKey] or {}

  if not params then
    return headers
  end

  if params.json == true then
    local jsonHeaders = {}
    for k, v in pairs(headers) do
      jsonHeaders[k] = v
    end
    jsonHeaders["content-type"] = "application/json; charset=UTF-8"
    return jsonHeaders
  end

  return headers
end

--- 解析响应数据（子类可重写）
--- @param response table 解码后的 JSON 响应
--- @param params table 请求参数
--- @return any 解析后的数据
function BaseModel:parseResponse(response, params)
  return response
end

--- 加载成功回调（子类可重写）
--- @param data any 解析后的数据
function BaseModel:onLoadSuccess(data) end

--- 加载失败回调（子类可重写）
--- @param error string 错误信息
function BaseModel:onLoadError(error) end

--- 统一检查响应码
--- @param code number 响应码
--- @return boolean success 是否成功
--- @return string|nil errorMsg 错误信息
function BaseModel:checkResponseCode(code)
  -- 网络请求失败
  if code < 0 then
    return false, string.format("网络请求失败 (%d)", code)
  end

  -- HTTP 错误状态码
  if code == 400 then
    return false, "请求参数错误"
   elseif code == 401 then
    return false, "未授权，请重新登录"
   elseif code == 403 then
    return false, "权限不足"
   elseif code == 404 then
    return false, "请求的资源不存在"
   elseif code >= 500 then
    return false, "服务器错误"
  end

  -- 其他状态码（200、201、204等）放行
  return true, nil
end

--- 通用 GET 请求（使用 getUrl/getHeaders/urlProcessor）
--- @param url string 请求地址（若提供则优先，否则使用 getUrl(params)）
--- @param params table 请求参数（会传递给 getHeaders 和 parseResponse）
--- @param callback function 回调函数 function(success, data, code)
function BaseModel:fetch(url, params, callback)
  if not self:isAlive() then return end
  if self.needLogin and not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    self:setError("请登录后使用")
    if callback then callback(false, nil, -1) end
    return
  end

  self.isLoading = true
  self:notifyListeners("loading", true)

  local headers = self:getHeaders(params)
  if self.urlProcessor then
    url, headers = self.urlProcessor(url, headers)
  end

  -- 使用 runIfAlive 包装网络回调
  local wrappedCallback = self:runIfAlive(function(code, content)
    self.isLoading = false
    self:notifyListeners("loading", false)

    local success, errorMsg = self:checkResponseCode(code)
    if not success then
      self:setError(errorMsg)
      self:onLoadError(errorMsg)
      if callback then callback(false, nil, code) end
      return
    end

    local ok, response = pcall(json.decode, content)
    if not ok then
      self:setError("数据解析失败")
      self:onLoadError("数据解析失败")
      if callback then callback(false, nil, code) end
      return
    end

    self.data = self:parseResponse(response, params)
    self.isLoaded = true
    self.error = nil

    self:onLoadSuccess(self.data)
    self:notifyListeners("dataChanged", self.data)

    if callback then callback(true, self.data, code) end
  end)

  NetWork.get(url, headers, wrappedCallback)
end

--- 通用 POST 请求
--- @param url string 请求地址
--- @param postData string|table POST 数据
--- @param params table 额外参数（传递给 getHeaders）
--- @param callback function 回调 function(success, data, code)
function BaseModel:post(url, postData, params, callback)
  if not self:isAlive() then return end
  if self.needLogin and not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    self:setError("请登录后使用")
    if callback then callback(false, nil, -1) end
    return
  end

  self.isLoading = true
  self:notifyListeners("loading", true)

  local headers = self:getHeaders(params)
  headers = headers or {}

  if self.urlProcessor then
    url, headers = self.urlProcessor(url, headers)
  end

  -- 使用 runIfAlive 包装网络回调
  local wrappedCallback = self:runIfAlive(function(code, content)
    self.isLoading = false
    self:notifyListeners("loading", false)

    local success, errorMsg = self:checkResponseCode(code)
    if not success then
      self:setError(errorMsg)
      self:onLoadError(errorMsg)
      if callback then callback(false, nil, code) end
      return
    end

    -- 尝试解析 JSON
    local ok, response = pcall(json.decode, content)
    if ok then
      if callback then callback(true, response, code) end
     else
      if callback then callback(true, content, code) end
    end
  end)

  NetWork.post(url, postData, headers, wrappedCallback)
end

--- 通用 PUT 请求
--- @param url string 请求地址
--- @param putData string|table PUT 数据
--- @param params table 额外参数
--- @param callback function 回调 function(success, data, code)
function BaseModel:put(url, putData, params, callback)
  if not self:isAlive() then return end
  if self.needLogin and not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    self:setError("请登录后使用")
    if callback then callback(false, nil, -1) end
    return
  end

  self.isLoading = true
  self:notifyListeners("loading", true)

  local headers = self:getHeaders(params)
  headers = headers or {}

  if self.urlProcessor then
    url, headers = self.urlProcessor(url, headers)
  end

  -- 使用 runIfAlive 包装网络回调
  local wrappedCallback = self:runIfAlive(function(code, content)
    self.isLoading = false
    self:notifyListeners("loading", false)

    local success, errorMsg = self:checkResponseCode(code)
    if not success then
      self:setError(errorMsg)
      self:onLoadError(errorMsg)
      if callback then callback(false, nil, code) end
      return
    end

    -- 尝试解析 JSON
    local ok, response = pcall(json.decode, content)
    if ok then
      if callback then callback(true, response, code) end
     else
      if callback then callback(true, content, code) end
    end
  end)

  NetWork.put(url, putData, headers, wrappedCallback)
end

--- 通用 DELETE 请求
--- @param url string 请求地址
--- @param params table 额外参数
--- @param callback function 回调 function(success, data, code)
function BaseModel:delete(url, params, callback)
  if not self:isAlive() then return end
  if self.needLogin and not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    self:setError("请登录后使用")
    if callback then callback(false, nil, -1) end
    return
  end

  self.isLoading = true
  self:notifyListeners("loading", true)

  local headers = self:getHeaders(params)
  if self.urlProcessor then
    url, headers = self.urlProcessor(url, headers)
  end

  -- 使用 runIfAlive 包装网络回调
  local wrappedCallback = self:runIfAlive(function(code, content)
    self.isLoading = false
    self:notifyListeners("loading", false)

    local success, errorMsg = self:checkResponseCode(code)
    if not success then
      self:setError(errorMsg)
      self:onLoadError(errorMsg)
      if callback then callback(false, nil, code) end
      return
    end

    -- 尝试解析 JSON
    local ok, response = pcall(json.decode, content)
    if ok then
      if callback then callback(true, response, code) end
     else
      if callback then callback(true, content, code) end
    end
  end)

  NetWork.delete(url, headers, wrappedCallback)
end

--- 设置错误并通知监听器
--- @param error string 错误信息
function BaseModel:setError(error)
  self.error = error
  self:notifyListeners("error", error)
end

--- 清除错误信息
function BaseModel:clearError()
  self.error = nil
end

--- 重置数据状态（不清除监听器）
function BaseModel:reset()
  self.data = nil
  self.isLoaded = false
  self.error = nil
end

--- 获取当前数据
function BaseModel:getData()
  return self.data
end

--- 判断是否有数据
function BaseModel:hasData()
  return self.data ~= nil
end

--- 添加事件监听
--- @param event string 事件名 (loading, dataChanged, error)
--- @param listener function|table 监听器（函数或包含事件方法的表）
function BaseModel:addListener(event, listener)
  if not self.listeners[event] then
    self.listeners[event] = {}
  end
  table.insert(self.listeners[event], listener)
end

--- 移除事件监听
--- @param event string 事件名
--- @param listener function|table 监听器
function BaseModel:removeListener(event, listener)
  if self.listeners[event] then
    for i, l in ipairs(self.listeners[event]) do
      if l == listener then
        table.remove(self.listeners[event], i)
        break
      end
    end
  end
end

--- 通知所有监听器
--- @param event string 事件名
--- @param ... any 参数
function BaseModel:notifyListeners(event, ...)
  -- 已销毁则不再通知
  if self.isDestroyed then return end

  if self.listeners[event] then
    for _, listener in ipairs(self.listeners[event]) do
      if type(listener) == "function" then
        listener(...)
       elseif listener[event] then
        listener[event](...)
      end
    end
  end
end

--- 清除所有监听器
function BaseModel:clearListeners()
  self.listeners = {}
end

--- 销毁实例
function BaseModel:destroy()
  self.isDestroyed = true
  self:clearListeners()
  self.data = nil
  self.error = nil
end

return BaseModel