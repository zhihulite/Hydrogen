-- utils/permission.lua
-- 权限申请

local M = {}

import "androidx.core.app.ActivityCompat"
import "android.content.pm.PackageManager"
import "androidx.activity.result.contract.ActivityResultContracts"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

local launcher = nil
local pendingCallback = nil

function M.check(permission)
  return ActivityCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
end

-- 必须在 onCreate 里调用一次，提前注册 launcher
function M.init()
  if not launcher then
    launcher = activity.registerForActivityResult(
    ActivityResultContracts.RequestPermission(),
    function(granted)
      if pendingCallback then
        pendingCallback(granted)
        pendingCallback = nil
      end
    end
    )
  end
end

function M.request(permission, callback, rationale)
  if M.check(permission) then
    if callback then callback(true) end
    return
  end

  if rationale then
    MaterialAlertDialogBuilder(activity)
    .setTitle(rationale.title or "权限说明")
    .setMessage(rationale.message or "需要此权限才能继续使用该功能")
    .setPositiveButton("授权", function()
      M.launch(permission, callback)
    end)
    .setNegativeButton("取消", function()
      if callback then callback(false) end
    end)
    .show()
   else
    M.launch(permission, callback)
  end
end

function M.launch(permission, callback)
  pendingCallback = callback
  if not launcher then
    error("必须在 onCreate 或 onStart 前调用一次 permission 的 init 方法")
  end
  launcher.launch(permission)
end

return M