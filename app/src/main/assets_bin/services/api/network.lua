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

-- 将 Lua String 转为 Java byte[]
-- 
-- 背景说明：
-- 1. Lua 字符串底层可存储原始字节
-- 2. 当 Lua 字符串作为参数传给 Java 方法时，LuaJava 根据目标参数类型决定转换方式
--    - 目标为 String 时：LuaJava 调用 LuaState.toString(idx)，不传入 idx 该方法按 UTF-8 解码 byte[] 为 Java String（数据可能损坏）
--    - 目标为 byte[] 时：LuaJava 直接传递原始字节数组（安全）
-- 
-- 拓展说明：LuaJava 将 Java 对象转为 Lua 对象的机制
-- - Java byte[] → Lua string：通过 lua_pushlstring 直接传递原始字节（安全，保留 \0）
-- - Java String → Lua string：按 UTF-8 编码（二进制数据会损坏）
-- - Java 其他对象 → Lua userdata：包装为 userdata 对象
-- 
-- 拓展说明：跨虚拟机传递 LuaObject（LuaTable/LuaFunction 等）变成 userdata 的原因
-- 1. LuaObject 内部持有原 LuaState 引用
-- 2. 反序列化后，该引用指向原虚拟机而非当前虚拟机
-- 3. pushObjectValue 判断 ref.getLuaState() == this 为 false
-- 4. 执行 pushJavaObject(ref)，作为普通 Java 对象推入 Lua
-- 5. 结果：type(obj) 返回 "userdata" 而非原生的 table/function
-- 
-- 拓展说明：compareTypes 中参数为 Object 时的行为
-- 当 Java 方法参数类型为 Object 时，Lua 原生 table 传入时：
-- compareTypes 内执行 Object.class.isAssignableFrom(LuaTable.class)，结果为 true
-- 此时 Lua table 被包装为 LuaTable 对象传入 Java 方法
-- 该对象后续若传回 Lua，其行为取决于是否与当前虚拟机绑定（同虚拟机保持原生，跨虚拟机变 userdata）
-- 
-- 因此需要此方法手动转换，避免依赖自动类型转换导致的数据损坏或类型丢失
local byte = luajava.bindClass("java.lang.Byte").TYPE
local function toByteArray(content)
  if not content then return nil end
  local len = #content
  if len == 0 then return luajava.newArray(byte, 0) end

  local bytes = luajava.newArray(byte, len)
  for i = 0, len - 1 do
    local b = content:byte(i + 1)
    if b > 127 then b = b - 256 end
    bytes[i] = b
  end
  return bytes
end

-- GET请求（原始字节，手动转换为 byte[]）
function M.getRaw(url, headers, callback, skipZse96)
  if canLoad == false then return false end

  if type(headers) == "function" then
    callback = headers
    headers = nil
  end
  headers = headers or _G.Headers.defaultHead

  if not skipZse96 and url:find("https://www.zhihu.com") and zse96Encrypt then
    url, headers = zse96Encrypt(url)
  end

  Http.get(url, headers, function(code, content, raw, respHeaders)
    local bytes = toByteArray(content)
    callback(code, bytes)
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