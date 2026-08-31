-- pages/activity/blank/blank_activity.lua
-- 空白容器 Activity，用于承载 Activity 模式的页面（独立虚拟机）
-- 说明：Activity 是单实例，不需要每次创建新实例

require("init_app")

local page_name, page_params_key = ...

if not page_name then
  print("BlankActivity: 未指定页面名称，跳转主页面")
  Router.go("main")
  return
end

local route = Router.get(page_name)
if not route then
  print("BlankActivity: 路由不存在 - " .. page_name .. "，跳转主页面")
  Router.go("main")
  return
end

local PageClass = require(route.path)
local page = PageClass()
page:start(page_params_key)

-- 代理所有生命周期方法给 page
local activityMethods = {
  "onResume", "onPause", "onDestroy",
  "onKeyDown", "onKeyUp", "onConfigurationChanged",
  "onNewIntent"
}

for _, method in ipairs(activityMethods) do
  if page[method] then
    _G[method] = function(...)
      return page[method](page, ...)
    end
  end
end
