-- core/init.lua
-- core 导出：模块装载、全局注册与启动序列

local M = {}

--- 全大写缩写键（ui -> UI）；新缩写往这里加
local ACRONYMS = { ui = "UI" }

--- 把模块表按 snake_case 键转 PascalCase 挂到全局命名空间。
--- 新模块只需在各自 init.lua 里加一行；挂载处与全局名由同一条注册语句派生，
--- 不存在挂载处写了而全局名漏写的情况。
--- @param globalName string 全局命名空间名（Helpers/Extensions/Services）
--- @param mod table 各目录 init.lua 返回的模块表
local function exportAll(globalName, mod)
  local g = {}
  _G[globalName] = g
  for k, v in pairs(mod) do
    local name = ACRONYMS[k]
    if not name then
      local parts = {}
      for w in k:gmatch("[^_]+") do
        parts[#parts + 1] = w:sub(1, 1):upper() .. w:sub(2)
      end
      name = table.concat(parts)
    end
    g[name] = v
  end
end

-- 基础模块
local extensions = require("extensions.init")
local helpers = require("helpers.init")
local services = require("services.init")

exportAll("Extensions", extensions)
exportAll("Helpers", helpers)
exportAll("Services", services)

-- 需要初始化的模块
Extensions.File.init()
Services.Permission.init()

-- 全局短名（使用面广，保留既有拼写）
_G.NetWork = services.api.network
_G.HistoryService = services.cache.history

_G.json = require("json")
_G.Constants = require("core.constants")
-- 配置默认值：需先于启动期读配置的模块（AppTheme 等）执行，保证 get/getBool 能取到默认值
Extensions.Config.init(Constants.defaults)
_G.AppTheme = require("core.app_theme")
AppTheme.init()
_G.AppInfo = require("core.app_info")

_G.Layouts = require("layout.init")

-- 常用函数
_G.tip = helpers.ui.tip
_G.dp2px = helpers.ui.dp2px
_G.sp2px = helpers.ui.sp2px
_G.px2sp = helpers.ui.px2sp
_G.px2dp = helpers.ui.px2dp
local Html = luajava.bindClass("android.text.Html")
_G.fromHtml = function(text)
  return Html.fromHtml(text)
end

-- 工具函数
function table.merge(t1, t2)
  local result = {}
  if t1 then
    for k, v in pairs(t1) do result[k] = v end
  end
  if t2 then
    for k, v in pairs(t2) do result[k] = v end
  end
  return result
end

function table.clone(t)
  local result = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      result[k] = table.clone(v)
     else
      result[k] = v
    end
  end
  return result
end

function table.size(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

-- 设备 ID 与请求头
local headers = require("services.api.headers")
_G.DEVICE_ID = headers.deviceId
--- 重建 _G.Headers：登录状态变化后调用，让 cookie 与 Authorization 换成当前凭证
_G.buildHeaders = function()
  _G.Headers = headers.build()
end
buildHeaders()

-- 屏幕信息、字体、文字样式与卡片样式
require("core.app_text_style")

-- 路由
_G.Router = require("core.router")
require("pages.init").registerToRouter(Router)

return M
