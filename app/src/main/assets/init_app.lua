-- init_app.lua
-- 入口脚本的环境初始化，带幂等标记只生效一次

if _G.INIT_APP_PATCHED then
  return
end

-- 标记已初始化，防止重复加载
_G.INIT_APP_PATCHED = true


if activity then

  _G.ROOT = activity.rootDir

  local MaterialAlertDialogBuilder = luajava.bindClass("com.google.android.material.dialog.MaterialAlertDialogBuilder")
  local Environment = luajava.bindClass("android.os.Environment")
  local File = luajava.bindClass("java.io.File")

  local resources = activity.resources
  local message_id = resources.getIdentifier("message", "id", "android")

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

  -- print 打补丁：先走引擎原 print（写 logcat，tag LuaJVM），再按调试开关补弹窗。
  -- 判据惰性读：init_app 在 core/init 与 Extensions 之前执行，此刻 Extensions 尚不存在。
  local enginePrint = print
  _G.print = function(...)
    enginePrint(...)

    local Config = Extensions and Extensions.Config
    local keys = Constants and Constants.SharedDataKeys
    if not Config or not keys then
      return
    end
    if not Config.getBool(keys.DEBUG_MODE) then
      return
    end

    local buf = {}
    for i = 1, select("#", ...) do
      table.insert(buf, tostring(select(i, ...)))
    end
    alert("Print", table.concat(buf, "\t\t"))
  end

  local state = Environment.getExternalStorageState()
  local MEDIA_MOUNTED = Environment.MEDIA_MOUNTED

  if state ~= MEDIA_MOUNTED then
    error("外部存储未挂载，请检查SD卡或内部存储")
  end

  local externalFilesDir = activity.getExternalFilesDir(nil)
  if externalFilesDir == nil then
    error("无法获取外部存储目录，请检查存储权限或系统状态")
  end

  local crashDir = externalFilesDir.absolutePath .. "/crash"
  local dir = File(crashDir)
  local path = crashDir .. "/" .. activity.packageName .. ".txt"

  if not dir.exists() then
    -- mkdirs 失败不中断启动：onError 写日志时 io.open 已有 nil 兜底，此处仅输出诊断
    if not dir.mkdirs() then
      print("crash 目录创建失败: " .. crashDir)
    end
  end

  _G.onError = function(title, message)
    local content = tostring(title) .. os.date(" %Y-%m-%d %H:%M:%S") .. "\n" .. tostring(message) .. "\n\n"
    local f = io.open(path, "a")
    if f then
      f:write(content)
      f:close()
    end
    alert(title, message)
    return true
  end

end

-- 加载核心初始化模块
require("core/init")