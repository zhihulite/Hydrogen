-- initApp.lua
-- 全局初始化文件，每个页面都需要 require("initApp")

if _G.INIT_APP_PATCHED then
  return
end

-- 标记已初始化，防止重复加载
_G.INIT_APP_PATCHED = true

local function detectEnvironment()
  local isAndroLua = pcall(function() luajava.bindClass("com.luajava.LuaJavaAPI") end)
  local isLuaJ = pcall(function() luajava.bindClass("org.luaj.Lua") end)
  return isAndroLua, isLuaJ
end

-- AndroLua 补丁
local function patchAndroLua()
  -- 导入 import 在LuaJ++无需导入，默认全局变量
  require("import")

  -- 查找项目根目录（向上查找 files 或 assets 或 assets_bin 目录，最多递归10层）
  local function findRoot(startPath, depth)
    depth = (depth or 0) + 1
    if depth > 10 then error("findRoot: 超过最大递归层数（10层）") end

    local path = startPath:match("(.+)/$") or startPath
    for _, dir in ipairs({"files","assets","assets_bin"}) do
      if path:match('/' .. dir .. '$') then return path end
    end

    local parent = path:match("(.+)/[^/]+$")
    if parent then return findRoot(parent, depth) end
    print(parent)
    error("findRoot: 未找到 files 或 assets 或 assets_bin 目录")
  end

  -- 设置全局根目录为项目绝对目录
  _G.ROOT = findRoot(activity.luaDir)

  -- 将根目录添加到模块搜索路径
  local scriptDir = activity.luaDir
  if _G.ROOT ~= scriptDir then
    package.path = _G.ROOT .. "/?.lua;" .. _G.ROOT .. "/?/init.lua;" .. package.path
  end
end

-- LuaJ 补丁
local function patchLuaJ()
  -- 深拷贝表格
  function table.clone(datatable)
    if type(datatable) ~= "table" then return datatable end
    local res = {}
    for k, v in pairs(datatable) do
      res[k] = table.clone(v)
    end
    return res
  end

  -- 检测 string.pack 是否需要修复
  local function isNeedPatchStringPack()
    local isNormal = (string.pack("z", "lua") == "lua\0")
    return not isNormal
  end

  -- 检测 string.unpack 是否需要修复（LuaJ++ 可能未完全支持第三个参数）
  local function isNeedPatchStringUnpack()
    local v1, p1 = string.unpack("<h", "\x64\x00\xC8\x00", 3)
    local isNormal = (v1 == 200 and p1 == 5)
    return not isNormal
  end

  -- 为 string.pack/string.unpack 添加警告提示
  local function patchStringFunc(funcName)
    local old_func = string[funcName]
    _G.string[funcName]=function(...)
      print(string.format("警告: 不建议使用 string.%s，该函数在 LuaJ 中实现不完善", funcName))
      return old_func(...)
    end
  end

  if isNeedPatchStringPack() then
    patchStringFunc("pack")
  end

  if isNeedPatchStringUnpack() then
    patchStringFunc("unpack")
  end

  -- 设置全局根目录为项目绝对目录
  _G.ROOT = activity.luaDir

  -- 将当前脚本所在目录添加到模块搜索路径
  local scriptDir = activity.luaPath:match("(.+)/[^/]+$")
  if scriptDir and not package.path:find(scriptDir) then
    package.path = package.path .. ";" .. scriptDir .. "/?.lua;" .. scriptDir .. "/?/init.lua"
  end
end

-- 根据环境执行对应的补丁
local isAndroLua, isLuaJ = detectEnvironment()
if isAndroLua then
  patchAndroLua()
 elseif isLuaJ then
  patchLuaJ()
 else
  error("不支持的运行环境，本程序只支持在 AndroLua+ 或 LuaJ++ 环境中运行。")
end

if activity then
  local MaterialAlertDialogBuilder = luajava.bindClass("com.google.android.material.dialog.MaterialAlertDialogBuilder")
  local androidR = luajava.bindClass("android.R")
  local message_id = androidR.id.message

  local function alert(title, msg)
    title = title or "提示"
    activity.runOnUiThread(function()
      local dialog = MaterialAlertDialogBuilder(activity)
      .setTitle(title)
      .setMessage(tostring(msg))
      .setPositiveButton("确定", nil)
      .show()
      dialog.window.findViewById(message_id).textIsSelectable = true
    end)
  end

  -- 禁用默认 Toast 行为
  activity.debug = false
  _G.print = function(...)
    -- 没有开启就退出
    if Extensions.Config.getBool(Constants.SharedDataKeys.DEBUG_MODE) == false then return end
    local buf = {}
    for i = 1, select("#", ...) do
      table.insert(buf, tostring(select(i, ...)))
    end
    local msg = table.concat(buf, "\t\t")
    alert("Print", msg)
  end

  local crashDir = activity.getExternalFilesDir(nil).absolutePath .. "/crash"
  local dir = luajava.bindClass("java.io.File")(crashDir)
  local path = crashDir .. "/" .. activity.packageName .. ".txt"

  if not dir.exists() then
    dir.mkdirs()
  end

  _G.onError = function(title, message)
    local content = tostring(title) .. os.date(" %Y-%m-%d %H:%M:%S") .. "\n" .. tostring(message) .. "\n\n"
    io.open(path, "a"):write(content):close()
    alert(title, message)
    return true
  end

end

-- 加载核心初始化模块
require("core/init")