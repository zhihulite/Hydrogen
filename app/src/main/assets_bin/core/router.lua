-- core/router.lua
-- 路由模块

local M = {}

local routes = {}
local fragmentLoader = nil

local PageType = {
  ACTIVITY = 1,
  FRAGMENT = 2,
}

-- 大数据缓存（使用 Storage，基于文件，可跨虚拟机）
local Storage = require("services.cache.storage")

-- 存储参数，返回 key
function M.storeParams(data)
  local key = "router_params_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
  Storage.set(key, data)
  return key
end

-- 根据 key 获取参数并删除
function M.takeParams(key)
  if not key or type(key) ~= "string" then
    return nil
  end
  local data = Storage.get(key)
  if data then
    Storage.delete(key)
  end
  return data
end

-- 解析参数
function M.resolveParams(data)
  if type(data) == "table" then
    return data
  end
  if type(data) == "string" then
    return M.takeParams(data) or {}
  end
  return {}
end

-- 基础路由

function M.register(name, path, pageType, replace)
  routes[name] = {
    path = path,
    pageType = pageType or PageType.FRAGMENT,
    replace = replace or false,
  }
end

function M.registerActivity(name, path, replace)
  return M.register(name, path, PageType.ACTIVITY, replace)
end

function M.registerFragment(name, path)
  return M.register(name, path, PageType.FRAGMENT)
end

-- 分发路由

function M.registerDispatch(name, resolver)
  routes[name] = {
    dispatch = true,
    resolver = resolver,
  }
end

-- Fragment 加载器

function M.setFragmentLoader(loader)
  fragmentLoader = loader
end

function M.hasFragmentLoader()
  return fragmentLoader ~= nil
end

function M.get(name)
  return routes[name]
end

local function getBlankActivityPath()
  return _G.ROOT .. "/pages/activity/blank/BlankActivity.lua"
end

-- 核心跳转

function M.go(name, params, options)
  params = params or {}
  options = options or {}

  local route = routes[name]
  if not route then
    print("路由不存在: " .. name)
    return false
  end

  -- 处理分发路由
  if route.dispatch then
    local result = route.resolver(params, options)

    if result == false then
      return false
    end

    if type(result) == "string" then
      name = result
     elseif type(result) == "table" then
      name = result.name
      params = result.params or params
      options = result.options or options
    end

    route = routes[name]
    if not route then
      print("路由不存在: " .. name)
      return false
    end
  end

  -- 只存储 params 到 Storage，options 直接传递
  local paramsKey = M.storeParams(params)

  -- 跳转
  if route.pageType == PageType.ACTIVITY then
    local blankPath = getBlankActivityPath()
    local arg = { name, paramsKey, options }
    if route.replace then
      activity.replaceActivity(blankPath, arg)
     else
      activity.startDocumentActivity(blankPath, arg)
    end
    return true
   else
    if not fragmentLoader then
      print("错误: Fragment 模式需要先调用 router.setFragmentLoader()")
      return false
    end
    return fragmentLoader({
      name = name,
      paramsKey = paramsKey,
      options = options,
      path = route.path,
      noBackStack = options.noBackStack == true,
      sharedElement = options.sharedElement
    })
  end
end

-- 返回栈

function M.back()
  local fm = activity.supportFragmentManager
  if fm and fm.backStackEntryCount > 0 then
    fm.popBackStack()
   else
    activity.finish()
  end
end

function M.clearBackStack()
  local fm = activity.supportFragmentManager
  if fm and fm.backStackEntryCount > 0 then
    fm.popBackStack(nil, FragmentManager.POP_BACK_STACK_INCLUSIVE)
  end
end

function M.getBackStackCount()
  local fm = activity.supportFragmentManager
  return fm and fm.backStackEntryCount or 0
end

function M.exists(name)
  return routes[name] ~= nil
end

function M.unregister(name)
  routes[name] = nil
end

return M