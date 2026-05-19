-- pages/activity/blank/BlankActivity.lua
-- 空白容器 Activity，用于承载 Activity 模式的页面（独立虚拟机）
-- 说明：Activity 是单实例，不需要每次创建新实例

require("initApp")

local page_name, page_params = ...

if not page_name then
  print("BlankActivity: 未指定页面名称")
  activity.finish()
  return
end

local route = Router.get(page_name)
if not route then
  print("BlankActivity: 路由不存在 - " .. page_name)
  activity.finish()
  return
end

local PageClass = require(route.path)
local page = PageClass()
page:start(page_params)

-- 代理所有生命周期方法给 page
local activityMethods = {
  "onResume", "onResume", "onPause", "onDestroy",
  "onKeyDown", "onKeyUp", "onConfigurationChanged",
  "onActivityResult"
}

for _, method in ipairs(activityMethods) do
  if page[method] then
    _G[method] = function(...)
      return page[method](page, ...)
    end
  end
end