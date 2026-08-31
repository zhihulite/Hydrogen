-- pages/activity/blank/blank_activity.lua
-- 空白容器 Activity，用于承载 Activity 模式的页面（独立虚拟机）
-- 说明：Activity 是单实例，不需要每次创建新实例

require("init_app")

local page_name, page_params_key = ...

-- 通用清理：释放本次跳转的路由参数。onDestroy 统一经此清理，start 抛错时
-- 页面已不可用、无人保证 onDestroy 会被调，也直接调用
local function cleanup()
  Router.releaseParams(page_params_key)
end

if not page_name then
  print("BlankActivity: 未指定页面名称，跳转主页面")
  cleanup()
  Router.go("main")
  return
end

local route = Router.get(page_name)
if not route then
  print("BlankActivity: 路由不存在 - " .. page_name .. "，跳转主页面")
  cleanup()
  Router.go("main")
  return
end

local page

-- 生命周期代理：onDestroy 在页面真正结束（isFinishing）时先清理再转发给页面；
-- recreate 销毁不释放参数，重建后的页面还要靠同一 key 重放取参
local function proxyLifecycle()
  local activityMethods = {
    "onResume", "onPause", "onKeyDown", "onKeyUp",
    "onConfigurationChanged", "onNewIntent",
  }
  for _, method in ipairs(activityMethods) do
    if page[method] then
      _G[method] = function(...)
        return page[method](page, ...)
      end
    end
  end

  _G.onDestroy = function(...)
    if activity.isFinishing() then
      cleanup()
    end
    return page:onDestroy(...)
  end
end

-- 生命周期代理先于 start 挂载：start 抛错时引擎销毁依旧经 _G.onDestroy 走到
-- page:onDestroy，EdgeToEdge 移除等基类清理不因报错脱钩。
-- 任一环节失败：立即清理（recreate 重放走空参降级而非重复报错），
-- xpcall 保 traceback 后原样上抛，错误页与 onError 弹窗照常出现
local success, err = xpcall(function()
  local PageClass = require(route.path)
  page = PageClass()
  proxyLifecycle()
  page:start(page_params_key)
end, debug.traceback)
if not success then
  cleanup()
  error(err, 0)
end
