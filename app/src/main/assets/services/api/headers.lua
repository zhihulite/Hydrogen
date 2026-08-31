-- services/api/headers.lua
-- 设备 ID 与请求头构造（依赖 NetWork / Extensions.Config / json / table.merge 已就绪）

local M = {}

-- UDID 首次运行时随机生成并落盘，之后固定复用
local udid = Extensions.Config.getString(Constants.SharedDataKeys.UDID)
if not udid or udid == "" then
  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
  local id = {}
  for i = 1, 35 do
    local idx = math.random(1, #chars)
    table.insert(id, chars:sub(idx, idx))
  end
  udid = table.concat(id) .. "="
  Extensions.Config.set(Constants.SharedDataKeys.UDID, udid)
end

--- 设备 ID，core/init.lua 挂为 _G.DEVICE_ID
M.deviceId = udid

--- 构建请求头表，core/init.lua 挂为 _G.Headers、并由 _G.buildHeaders 重建
--- 四个 key 的身份语义：app 走 app 接口（Authorization Bearer），defaultHead 走网页
--- 接口（cookie），post / postApp 是各自加 json content-type 的 POST 版本，
--- key 常量与合法值白名单见 Constants.RequestHeadKeys / Constants.ValidRequestHeadKeys；
--- 发往 www.zhihu.com 的 GET 请求头会被 zse96 签名结果整体替换（见 network.lua signIfNeeded），
--- requestHeadKey 对这类请求不生效
--- defaultHead / post 在字段被读取时才向 CookieManager 取 cookie：
--- 模块加载期不触发 CookieManager 首次访问引发的 Chromium 内核同步初始化，
--- 登录/登出后每次请求取到的也是当前 cookie
--- @return table 请求头表，app / postApp 为实体键，defaultHead / post 经 __index 懒构建
function M.build()
  local function buildBaseHeaders()
    local baseHeaders = {
      ["x-udid"] = M.deviceId,
      ["User-Agent"] = "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36",
      ["Accept"] = "application/json, text/plain, */*",
    }

    local cookie = NetWork.getCookie("https://www.zhihu.com/")

    if cookie then
      baseHeaders["cookie"] = cookie
    end

    return baseHeaders
  end

  local appHeaders = {
    ["x-udid"] = M.deviceId,
    ["User-Agent"] = "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36",
    ["Accept"] = "application/json, text/plain, */*",
    ["x-api-version"] = "3.1.8",
    ["x-app-za"] = "OS=Android&VersionName=10.12.0&VersionCode=21210",
    ["x-app-version"] = "10.12.0",
    ["x-app-bundleid"] = "com.zhihu.android",
    ["user-agent"] = "com.zhihu.android/Futureve/10.12.0",
  }

  local sign_in_data = Extensions.Config.getString(Constants.SharedDataKeys.SIGN_IN_DATA)
  if sign_in_data then
    -- 存储值来自 WebView oauth 响应体原文，可能不是合法 JSON 或缺 access_token
    local ok, decoded = pcall(json.decode, sign_in_data)
    local token = ok and type(decoded) == "table" and decoded.access_token
    if token then
      appHeaders["Authorization"] = "Bearer " .. token
    end
  end

  return setmetatable({
    app = appHeaders,
    postApp = table.merge(appHeaders, {
      ["content-type"] = "application/json",
    }),
    }, {
    __index = function(_, key)
      if key == "defaultHead" then
        return buildBaseHeaders()
       elseif key == "post" then
        return table.merge(buildBaseHeaders(), {
          ["content-type"] = "application/json",
        })
      end
      return nil
    end,
  })
end

return M