-- services/api/network.lua
-- 通用请求模块

local M = {}

local CookieManager = luajava.bindClass("android.webkit.CookieManager")
local MaterialAlertDialogBuilder = luajava.bindClass("com.google.android.material.dialog.MaterialAlertDialogBuilder")

-- 全局控制变量
local canLoad = true
local tipDialog = nil

-- 辅助函数
local function showTip(msg)
  tip(msg)
end

-- 触发安全验证后 canLoad 置 false，请求全部暂停到重启应用为止；
-- 并发请求会各自撞上这道闩，用秒级时间戳把提示压成每 5 秒一条
local blockedTipAt = 0
local function isBlocked()
  if canLoad ~= false then return false end
  local now = os.time()
  if now - blockedTipAt >= 5 then
    blockedTipAt = now
    showTip("请求已暂停，完成安全验证后请重启应用")
  end
  return true
end

local function clearLoginState()
  CookieManager.instance.removeAllCookies(nil)
  CookieManager.instance.flush()
  Extensions.Config.delete(Constants.SharedDataKeys.SIGN_IN_DATA)
  Extensions.Config.delete(Constants.SharedDataKeys.USER_ID)
  Extensions.Config.delete(Constants.SharedDataKeys.UDID)
  -- 凭证清空后重建 _G.Headers：Authorization 取自 sign_in_data，
  -- 不重建则后续请求仍带着失效令牌
  buildHeaders()
end

-- 响应处理
local function handleResponse(result, url, reqHeaders, callback, method, data)
  local code = result.code
  local content = result.text

  if code == 403 then
    local ok, decoded = pcall(json.decode, content)
    if ok and decoded.error then
      if decoded.error.message and decoded.error.redirect then
        if not tipDialog or not tipDialog.isShowing() then
          canLoad = false
          tipDialog = MaterialAlertDialogBuilder(activity)
          .setTitle("提示")
          .setMessage(decoded.error.message)
          -- 请求已全部暂停，需经「立即跳转」完成验证并重启应用才能恢复
          .setCancelable(false)
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
    local ok, decoded = pcall(json.decode, content)
    if ok and decoded.error and decoded.error.message then
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
   elseif method == "head" then
    M.head(url, headers, callback)
   elseif method == "post" then
    M.post(url, data, headers, callback)
   elseif method == "put" then
    M.put(url, data, headers, callback)
   elseif method == "delete" then
    M.delete(url, headers, callback)
  end
end

-- ZSE96 加密（如果存在）
local zse96Encrypt = nil
pcall(function()
  zse96Encrypt = require("services.api.zse96").encrypt
end)

--- 归位可选参数：headers 省略时它的位置上是 callback，据类型归一两个可选参数。
--- fallbackKey 传 Headers 的身份 key 而非头表本身：_G.Headers 的 defaultHead / post
--- 经 __index 每次读取都重新构建并现取 cookie，只有真的缺省时才该触发这次构建
--- @param headers table|function|nil
--- @param callback function|nil
--- @param fallbackKey string|nil headers 缺省时取用的 Headers 身份 key
--- @return table|nil headers, function|nil callback
local function resolveArgs(headers, callback, fallbackKey)
  if type(headers) == "function" then
    return fallbackKey and _G.Headers[fallbackKey], headers
  end
  if headers then
    return headers, callback
  end
  return fallbackKey and _G.Headers[fallbackKey], callback
end

--- 给 zhihu.com 的请求补 zse96 签名（skipZse96 为真时跳过）。
--- 触发范围：M.get / M.getRaw 中 URL 含 https://www.zhihu.com 的请求。
--- zse96.encrypt 只产出 cookie 与 x-zse-96 等签名头，返回的 headers 在此整体替换
--- 调用方传入的 headers、返回的 URL 替换原 URL——对这些请求 headers 参数不生效，
--- model 经 requestHeadKey 选出的身份头同样被丢弃
--- 未登录（无 d_c0 cookie）时 zse96.encrypt 会 error——捕获并提示登录、以 401 回调收尾，
--- 避免 LuaError 冒泡到 UI 线程导致崩溃/卡死（热榜等需签名接口在未登录下的预期行为）
--- @return string url, table|nil headers, boolean ok 为 false 时调用方应立即返回
local function signIfNeeded(url, headers, callback, skipZse96)
  if skipZse96 or not zse96Encrypt or not url:find("https://www.zhihu.com") then
    return url, headers, true
  end
  local okZ, newUrl, newHeaders = pcall(zse96Encrypt, url)
  if not okZ then
    showTip("请先登录")
    if callback then callback(401, nil) end
    return url, headers, false
  end
  return newUrl, newHeaders, true
end

-- GET请求
function M.get(url, headers, callback, skipZse96)
  if isBlocked() then return false end
  headers, callback = resolveArgs(headers, callback, Constants.RequestHeadKeys.DEFAULT_HEAD)

  local okSign
  url, headers, okSign = signIfNeeded(url, headers, callback, skipZse96)
  if not okSign then return false end

  Http.get(url, headers, function(result)
    handleResponse(result, url, headers, callback, "get")
  end)
end

-- GET请求（返回原始字节）
function M.getRaw(url, headers, callback, skipZse96)
  if isBlocked() then return false end
  headers, callback = resolveArgs(headers, callback, Constants.RequestHeadKeys.DEFAULT_HEAD)

  local okSign
  url, headers, okSign = signIfNeeded(url, headers, callback, skipZse96)
  if not okSign then return false end

  -- 第三个回参是引擎抽好的 Content-Type（已去掉 charset 部分）
  Http.get(url, headers, function(result)
    callback(result.code, result.bytes, result.contentType)
  end)
end

function M.head(url, headers, callback)
  headers, callback = resolveArgs(headers, callback)

  -- 第三个回参是引擎抽好的 Content-Type（已去掉 charset 部分），
  -- result.headers 里取到的是 Java List 包装，Lua 侧不能直接当字符串用
  Http.head(url, headers, function(result)
    if callback then
      callback(result.code, result.headers, result.contentType)
    end
end)end

function M.post(url, data, headers, callback)
  if isBlocked() then return false end
  headers, callback = resolveArgs(headers, callback, Constants.RequestHeadKeys.POST)

  Http.post(url, data, headers, function(result)
    handleResponse(result, url, headers, callback, "post", data)
  end)
end

function M.put(url, data, headers, callback)
  if isBlocked() then return false end
  headers, callback = resolveArgs(headers, callback, Constants.RequestHeadKeys.POST)

  Http.put(url, data, headers, function(result)
    handleResponse(result, url, headers, callback, "put", data)
  end)
end

function M.delete(url, headers, callback)
  if isBlocked() then return false end
  headers, callback = resolveArgs(headers, callback, Constants.RequestHeadKeys.DEFAULT_HEAD)

  Http.delete(url, headers, function(result)
    handleResponse(result, url, headers, callback, "delete")
  end)
end

-- 获取Cookie
function M.getCookie(url)
  return CookieManager.instance.getCookie(url)
end

-- 设置Cookie
function M.setCookie(url, cookie)
  CookieManager.instance.setCookie(url, cookie)
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