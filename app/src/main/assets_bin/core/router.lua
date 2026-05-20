-- core/router.lua
-- 路由

local M = {}

local routes = {}
local history = {}
local fragmentLoader = nil

local PageType = {
  ACTIVITY = 1,
  FRAGMENT = 2,
}

function M.register(name, path, pageType, title)
  routes[name] = {
    path = path,
    title = title or name,
    pageType = pageType or PageType.FRAGMENT,
    instance = nil,
  }
end

function M.registerActivity(name, path, title)
  return M.register(name, path, PageType.ACTIVITY, title)
end

function M.registerFragment(name, path, title)
  return M.register(name, path, PageType.FRAGMENT, title)
end

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

-- 内部实现
-- @param name string 路由名称
-- @param params table 参数
-- @param options table|nil 选项
--   options.noBackStack: boolean 是否不添加到返回栈
--   options.sharedElement: view 共享元素视图
function M.go(name, params, options)
  local route = routes[name]
  if not route then
    print("路由不存在: " .. name)
    return false
  end

  options = options or {}
  params = params or {}

  table.insert(history, { name = name, params = params, time = os.time() })

  if route.pageType == PageType.ACTIVITY then
    local blankActivityPath = getBlankActivityPath()
    activity.newActivity(blankActivityPath, { name, params })
    return true
   else
    if not fragmentLoader then
      print("错误: Fragment 模式需要先调用 router.setFragmentLoader() 注册加载器")
      return false
    end

    local loaderData = {
      name = name,
      params = params,
      path = route.path,
      noBackStack = options.noBackStack == true,
      sharedElement = options.sharedElement
    }

    return fragmentLoader(loaderData)
  end
end

-- 返回上一页
function M.back()
  local fm = activity.getSupportFragmentManager()

  if fm.getBackStackEntryCount() > 0 then
    fm.popBackStack()
    if #history > 0 then
      table.remove(history)
    end
   else
    activity.finish()
    history = {}
  end
end

-- 清空 Fragment 返回栈
function M.clearBackStack()
  local fm = activity.getSupportFragmentManager()
  if fm.getBackStackEntryCount() > 0 then
    fm.popBackStack(nil, FragmentManager.POP_BACK_STACK_INCLUSIVE)
  end
end

function M.clearHistory()
  history = {}
end

function M.getHistory()
  return history
end

function M.getBackStackCount()
  local fm = activity.getSupportFragmentManager()
  return fm.getBackStackEntryCount()
end

return M