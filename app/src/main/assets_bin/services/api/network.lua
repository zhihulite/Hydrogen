-- /services/api/network.lua
-- 通用请求类

local M = {}

local Http = luajava.bindClass "com.androlua.Http"
local CookieManager = luajava.bindClass("android.webkit.CookieManager")
local MaterialAlertDialogBuilder = luajava.bindClass("com.google.android.material.dialog.MaterialAlertDialogBuilder")

-- 全局请求头（在init.lua中设置）
_G.Headers = _G.Headers or {
  defaultHead = {},
  post = {},
}

-- 全局控制变量
local canLoad = true
local tipDialog = nil

-- 辅助函数
local function showTip(msg)
  tip(msg)
end

local function clearLoginState()
  CookieManager.instance.removeAllCookies(nil)
  CookieManager.instance.flush()
  Extensions.Config.delete(Constants.SharedDataKeys.SIGN_IN_DATA)
  Extensions.Config.delete(Constants.SharedDataKeys.USER_ID)
  Extensions.Config.delete(Constants.SharedDataKeys.UDID)
end

-- 响应处理
local function handleResponse(code, content, raw, headers, url, reqHeaders, callback, method, data)
  if code == 403 then
    local success, decoded = pcall(json.decode, content)
    if success and decoded.error then
      if decoded.error.message and decoded.error.redirect then
        if not tipDialog or not tipDialog.isShowing() then
          canLoad = false
          tipDialog = MaterialAlertDialogBuilder(activity)
          .setTitle("提示")
          .setMessage(decoded.error.message)
          .setCancelable(true)
          .setPositiveButton("立即跳转", { onClick = function()
              Router.go("browser", { url = decoded.error.redirect })
              showTip("已跳转，成功后请自行退出")
          end })
          .show()
        end
       elseif decoded.error.message then
        showTip(decoded.error.message)
      end
    end
   elseif code == 401 then
    if Extensions.Config.get(Constants.SharedDataKeys.USER_ID) then
      if not tipDialog or not tipDialog.isShowing() then
        tipDialog = MaterialAlertDialogBuilder(activity)
        .setTitle("提示")
        .setMessage("登录状态已失效，已自动帮你清除失效的登录状态。你可以点击下方我知道了来跳转登录")
        .setCancelable(false)
        .setPositiveButton("我知道了", { onClick = function()
            clearLoginState()
            Router.go("login")
        end })
        .show()
      end
    end
   elseif code == 400 then
    local success, decoded = pcall(json.decode, content)
    if success and decoded.error and decoded.error.message then
      showTip("知乎提示：" .. decoded.error.message)
    end
  end

  if callback then
    callback(code, content)
  end
end

-- 统一请求方法
function M.request(url, method, data, headers, callback)
  method = string.lower(method or "get")
  if method == "get" then
    M.get(url, headers, callback)
   elseif method == "delete" then
    M.delete(url, headers, callback)
   elseif method == "post" then
    M.post(url, data, headers, callback)
   elseif method == "put" then
    M.put(url, data, headers, callback)
  end
end

-- ZSE96 加密（如果存在）
local zse96Encrypt = nil
pcall(function()
  zse96Encrypt = require("services.api.zse96").encrypt
end)

-- GET请求
function M.get(url, headers, callback, skipZse96)
  if canLoad == false then return false end

  if type(headers) == "function" then
    callback = headers
    headers = nil
  end
  headers = headers or _G.Headers.defaultHead

  -- ZSE96 加密（可通过 skipZse96 参数跳过）
  if not skipZse96 and url:find("https://www.zhihu.com") and zse96Encrypt then
    url, headers = zse96Encrypt(url)
  end

  Http.get(url, headers, function(code, content, raw, respHeaders)
    handleResponse(code, content, raw, respHeaders, url, headers, callback, "get")
  end)
end

-- POST请求
function M.post(url, data, headers, callback)
  if canLoad == false then return false end

  if type(headers) == "function" then
    callback = headers
    headers = nil
  end
  headers = headers or _G.Headers.post

  Http.post(url, data, headers, function(code, content, raw, respHeaders)
    handleResponse(code, content, raw, respHeaders, url, headers, callback, "post", data)
  end)
end

-- PUT请求
local HttpTask = luajava.bindClass("com.androlua.Http$HttpTask")
local Object = luajava.bindClass("java.lang.Object")
function M.put(url, data, headers, callback)
  if canLoad == false then return false end

  if type(headers) == "function" then
    callback = headers
    headers = nil
  end
  headers = headers or _G.Headers.post
  local task = HttpTask(url, "PUT", nil, nil, headers, function(code, content, raw, respHeaders)
    handleResponse(code, content, raw, respHeaders, url, headers, callback, "put", data)
  end);
  local array = luajava.newArray(Object,1)
  array[0] = data
  task.execute(array);
  return task;

end

-- DELETE请求
function M.delete(url, headers, callback)
  if canLoad == false then return false end

  if type(headers) == "function" then
    callback = headers
    headers = nil
  end
  headers = headers or _G.Headers.defaultHead

  Http.delete(url, headers, function(code, content, raw, respHeaders)
    handleResponse(code, content, raw, respHeaders, url, headers, callback, "delete")
  end)
end

-- head请求
function M.head(url, headers, callback)
  if type(headers) == "function" then
    callback = headers
    headers = nil
  end

  Helpers.UI.runDelayedOnBackground(function()
    local conn = luajava.newInstance("java.net.URL", url).openConnection()
    conn.setRequestMethod("HEAD")
    conn.setConnectTimeout(5000)
    conn.setReadTimeout(5000)

    if headers then
      for k, v in pairs(headers) do
        conn.setRequestProperty(k, v)
      end
    end

    conn.connect()

    local code = conn.getResponseCode()
    local content = {}
    local fields = conn.getHeaderFields()
    local iter = fields.entrySet().iterator()

    while iter.hasNext() do
      local entry = iter.next()
      local key = entry.getKey()
      if key then
        content[key] = entry.getValue().get(0)
      end
    end

    conn.disconnect()
    return code, content
  end, callback)
end

-- 获取Cookie
function M.getCookie(url)
  return CookieManager.instance.getCookie(url)
end

-- 设置Cookie
function M.setCookie(url, cookie)
  CookieManager.instance.Cookie = url, cookie
  CookieManager.instance.flush()
end

-- 清除所有Cookie
function M.clearCookies()
  CookieManager.instance.removeAllCookies(nil)
  CookieManager.instance.flush()
end

-- URL编码
function M.urlEncode(str)
  if not str then return "" end
  return string.gsub(str, "([^%w%-%.%_%~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

-- URL解码
function M.urlDecode(str)
  if not str then return "" end
  return string.gsub(str, "%%(%x%x)", function(h)
    return string.char(tonumber(h, 16))
  end)
end

-- 设置全局加载状态
function M.setCanLoad(load)
  canLoad = load
end

-- 获取全局加载状态
function M.getCanLoad()
  return canLoad
end

return M