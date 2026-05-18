local require = require
local luajava = luajava
local type = type
local table = table

local stringMatch = string.match
local stringFind = string.find
local stringSub = string.sub
local stringGsub = string.gsub
local stringFormat = string.format
local stringRep = string.rep

local loaded = {}
local imported = {}
local importedSet = {}

local _G = _G
local insert = table.insert
local concat = table.concat
local bindClass = luajava.bindClass

local _M = {}
local luacontext = activity or service

local dexes = luajava.astable(luacontext.getClassLoaders())
local libs = luacontext.getLibrarys()

--- 加载原生库
---@param path string 库路径
---@return function|string
local function libsloader(path)
  local libName = stringMatch(path, "^%a+")
  local libPath = libs[libName]
  if libPath then
    local funcName = "luaopen_" .. (stringGsub(path, "%.", "_"))
    return assert(package.loadlib(libPath, funcName)), libPath
  end
  return "\n\tno file ./libs/lib" .. path .. ".so"
end
table.insert(package.searchers, libsloader)

--- 类名转换：下划线转美元符
---@param classname string
---@return string
local function massage_classname(classname)
  return stringGsub(classname, '_', '$')
end

--- 绑定普通 Java 类
---@param packagename string
---@return class|nil
local function bind_class(packagename)
  local success, class = pcall(bindClass, packagename)
  if success then
    loaded[packagename] = class
    return class
  end
  return nil
end

--- 导入普通类（带缓存）
---@param packagename string
---@return class|nil
local function import_class(packagename)
  packagename = massage_classname(packagename)
  local class = loaded[packagename]
  if class then return class end
  return bind_class(packagename)
end

--- 绑定 Dex 中的类
---@param packagename string
---@return class|nil
local function bind_dex_class(packagename)
  packagename = massage_classname(packagename)
  for i = 1, #dexes do
    local success, class = pcall(dexes[i].loadClass, packagename)
    if success then
      loaded[packagename] = class
      return class
    end
  end
  return nil
end

--- 导入 Dex 中的类（带缓存）
---@param packagename string
---@return class|nil
local function import_dex_class(packagename)
  packagename = massage_classname(packagename)
  local class = loaded[packagename]
  if class then return class end
  return bind_dex_class(packagename)
end

--- 包元表，支持链式访问
local packageMT = {
  __index = function(T, classname)
    local prefix = rawget(T, "__name")
    local fullName = prefix .. classname
    local success, class = pcall(luajava.bindClass, fullName)
    if success then
      rawset(T, classname, class)
      return class
    end
    error("类 " .. classname .. " 不存在于包 " .. fullName, 2)
  end
}

--- 导入包（返回可链式访问的表）
---@param packagename string
---@return table
local function import_package(packagename)
  return setmetatable({ __name = packagename }, packageMT)
end

--- 尝试用 require 导入
---@param name string
---@return any
local function try_require(name)
  local success, result = pcall(require, name)
  if not success and not stringFind(result, "no file") then
    error(result, 2)
  end
  return success and result
end

--- 添加到已导入列表（O(1) 去重）
---@param package string
local function add_to_imported(package)
  if not importedSet[package] then
    importedSet[package] = true
    insert(imported, package)
  end
end

-- 获取类的短名（最后一个点或美元符之后的部分）
---@param package string
---@return string
local function get_short_name(package)
  local shortName = stringMatch(package, '([^%.$]+)$')
  return shortName or package
end

--- 核心加载逻辑：先尝试 require，再尝试 Java 类（不报错，只返回 nil）
---@param name string
---@return any
local function load_module_or_class(name)
  -- 检查缓存
  if loaded[name] then
    return loaded[name]
  end

  -- 尝试 Lua 模块
  local lua_module = try_require(name)
  if lua_module then
    loaded[name] = lua_module
    return lua_module
  end

  -- 尝试 Java 类
  local java_class = import_class(name)
  if java_class then
    loaded[name] = java_class
    return java_class
  end

  -- 尝试 Dex 类
  local dex_class = import_dex_class(name)
  if dex_class then
    loaded[name] = dex_class
    return dex_class
  end

  return nil
end

--- 本地导入核心逻辑
---@param env table 目标环境
---@param package string 要导入的包/类名
---@return any
local function local_import(env, package)
  -- 处理 dex:class 语法
  local colonPos = stringFind(package, ':', 1, true)
  if colonPos then
    local dexname = stringSub(package, 1, colonPos - 1)
    local classname = stringSub(package, colonPos + 1)
    local dex = luacontext.loadDex(dexname)
    if not dex then
      error("无法加载 Dex 文件: " .. dexname, 2)
    end
    local class = dex.loadClass(classname)
    if not class then
      error("Dex 中不存在类: " .. classname, 2)
    end
    local shortName = get_short_name(package)
    env[shortName] = class
    add_to_imported(package)
    return class
  end

  -- 处理通配符导入
  if stringFind(package, '%*$') then
    local prefix = stringSub(package, 1, -2)
    add_to_imported(package)
    return import_package(prefix)
  end

  -- 普通类/模块导入
  local shortName = get_short_name(package)
  local result = load_module_or_class(package)

  if result then
    if type(result) ~= "table" then
      add_to_imported(package)
    end
    env[shortName] = result
    return result
  end

  -- 什么都找不到才报错
  error("无法导入: " .. package, 2)
end

--- 导入函数
---@param package string|table 完整包名或包名列表
---@param env table|nil 目标环境，默认为 _G
---@return any
local function import_function(package, env)
  env = env or _G
  if type(package) == "string" then
    return local_import(env, package)
   elseif type(package) == "table" then
    local results = {}
    for i = 1, #package do
      results[i] = local_import(env, package[i])
    end
    return results
  end
end

--- 创建导入环境
---@param env table 目标环境
---@return table
local function env_import(env)
  -- 挂载 import 函数
  env["import"] = import_function

  -- 挂载工具函数
  for k, v in pairs(_M) do
    if env[k] == nil then
      env[k] = v
    end
  end

  -- 自动导入常用模块
  import_function("loadlayout", env)
  import_function("loadbitmap", env)
  import_function("loadmenu", env)

  return env
end

--- 枚举迭代器
---@param e Enumeration
---@return function
function _M.enum(e)
  return function()
    if e.hasMoreElements() then
      return e.nextElement()
    end
  end
end

--- 集合迭代器
---@param o Iterable
---@return function
function _M.each(o)
  local iter = o.iterator()
  return function()
    if iter.hasNext() then
      return iter.next()
    end
  end
end

local NIL = setmetatable({}, { __tostring = function() return "nil" end })

--- 将 Lua 值转为字符串（用于调试）
---@param o any
---@return string
function _M.dump(o)
  local t = {}
  local visited = {}
  local space = stringRep(' ', 2)
  local deep = 0

  local function toString(val, keyPath)
    local valType = type(val)
    if valType == 'number' then
      insert(t, val)
     elseif valType == 'string' then
      insert(t, stringFormat('%q', val))
     elseif valType == 'table' then
      local mt = getmetatable(val)
      if mt and mt.__tostring then
        insert(t, tostring(val))
       else
        deep = deep + 2
        insert(t, '{')

        for k, v in pairs(val) do
          if v == _G then
            insert(t, stringFormat('\r\n%s%s\t=\t_G ;', stringRep(space, deep - 1), k))
           elseif v ~= package.loaded then
            local key = tonumber(k) and stringFormat('[%s]', k) or stringFormat('["%s"]', k)
            insert(t, stringFormat('\r\n%s%s\t=\t', stringRep(space, deep - 1), key))

            if v == NIL then
              insert(t, 'nil ;')
             elseif type(v) == 'table' then
              if not visited[tostring(v)] then
                visited[tostring(v)] = keyPath .. key
                toString(v, keyPath .. key)
               else
                insert(t, visited[tostring(v)])
                insert(t, ';')
              end
             else
              toString(v, keyPath)
            end
          end
        end
        insert(t, stringFormat('\r\n%s}', stringRep(space, deep - 1)))
        deep = deep - 2
      end
     else
      insert(t, tostring(val))
    end
    insert(t, " ;")
  end

  toString(o, '')
  return concat(t)
end

--- 打印调用栈（调试用）
function _M.printstack()
  local stacks = {}
  for level = 2, 16 do
    local info = debug.getinfo(level)
    if not info then break end

    local frame = { info = info, upvalues = {}, localvalues = {} }

    for i = 1, info.nups or 0 do
      local name, value = debug.getupvalue(info.func, i)
      if value == nil then value = NIL end
      frame.upvalues[name] = value
    end

    for i = -1, -255, -1 do
      local name, value = debug.getlocal(level, i)
      if not name then break end
      if value == nil then value = NIL end
      if not frame.localvalues.vararg then frame.localvalues.vararg = {} end
      insert(frame.localvalues.vararg, value)
    end

    for i = 1, 255 do
      local name, value = debug.getlocal(level, i)
      if not name then break end
      if value == nil then value = NIL end
      frame.localvalues[name] = value
    end

    insert(stacks, frame)
  end
  print(_M.dump(stacks))
end

local LuaAsyncTask = luajava.bindClass("com.androlua.LuaAsyncTask")
local LuaThread = luajava.bindClass("com.androlua.LuaThread")
local LuaTimer = luajava.bindClass("com.androlua.LuaTimer")
local Object = luajava.bindClass("java.lang.Object")

--- 检查并补全文件路径
---@param path string
---@return string
local function checkPath(path)
  if stringFind(path, "^[^/][%w%./_%-]+$") then
    if not stringFind(path, "%.lua$") then
      path = stringFormat("%s/%s.lua", activity.luaDir, path)
     else
      path = stringFormat("%s/%s", activity.luaDir, path)
    end
  end
  return path
end

--- 创建新线程
---@param src string|function 脚本路径或函数
---@param ... any 线程参数
---@return LuaThread
function _M.thread(src, ...)
  if type(src) == "string" then
    src = checkPath(src)
  end
  local thread
  if select("#", ...) > 0 then
    thread = LuaThread(activity or service, src, true, Object { ... })
   else
    thread = LuaThread(activity or service, src, true)
  end
  thread.start()
  return thread
end

--- 创建异步任务
---@param src string|function
---@param ... any 参数，最后一个参数为回调函数
---@return LuaAsyncTask
function _M.task(src, ...)
  local args = { ... }
  local callback = args[select("#", ...)]
  args[select("#", ...)] = nil
  local task = LuaAsyncTask(activity or service, src, callback)
  task.executeOnExecutor(LuaAsyncTask.THREAD_POOL_EXECUTOR, args)
  return task
end

--- 创建定时器
---@param f function 回调函数
---@param d number 延迟时间（毫秒）
---@param p number 周期（毫秒），0 表示只执行一次
---@param ... any 回调参数
---@return LuaTimer
function _M.timer(f, d, p, ...)
  local timer = LuaTimer(activity or service, f, Object { ... })
  if p == 0 then
    timer.start(d)
   else
    timer.start(d, p)
  end
  return timer
end

-- 全局初始化
env_import(_G)

return true