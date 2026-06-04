-- core/app_info.lua
-- app信息管理

local M = {}

M.name = "Hydrogen"
M.versionName = "new"
M.version = 0.613
M.packageName = activity.packageName

function M.getName()
  return M.name
end

function M.getVersionName()
  return M.versionName
end

function M.getVersion()
  return M.version
end

function M.getFullVersion()
  return M.versionName
end

function M.getPackageName()
  return M.packageName
end

function M.getIgnoredVersion()
  return Extensions.Config.getString(Constants.SharedDataKeys.IGNORED_VERSION, "")
end

function M.setIgnoredVersion(version)
  Extensions.Config.set(Constants.SharedDataKeys.IGNORED_VERSION, tostring(version))
end

function M.clearIgnoredVersion()
  Extensions.Config.delete(Constants.SharedDataKeys.IGNORED_VERSION)
end

local isChecking = false

function M.checkUpdate(callback)
  if isChecking then
    tip("正在检测中")
    return
  end

  isChecking = true

  local update_api = "https://gitee.com/api/v5/repos/huaji110/huajicloud/contents/zhihu_hydrogen.html?access_token=abd6732c1c009c3912cbfc683e10dc45"

  NetWork.get(update_api, nil, function(code, content)
    isChecking = false
    if code ~= 200 then
      tip(false, "检测更新失败，请检查网络连接", nil)
      return
    end

    local ok, data = pcall(json.decode, content)
    if not ok or not data or not data.content then
      tip("解析更新信息失败")
      return
    end

    local decoded = Extensions.Crypto.base64Decode(data.content)

    local updateVersion = decoded:match("updateversioncode=(%d+.%d+),updateversioncode")
    local updateVersionName = decoded:match("updateversionname=(.+),updateversionname")
    local updateInfo = decoded:match("updateinfo=(.+),updateinfo")
    local updateUrl = decoded:match("updateurl=(.+),updateurl")

    local currentVersion = M.getVersion()
    local hasNewVersion = updateVersion and tonumber(updateVersion) > currentVersion
    if callback then
      callback(hasNewVersion, hasNewVersion and "发现新版本" or "已是最新版本", {
        hasNew = hasNewVersion,
        version = updateVersion,
        versionName = updateVersionName,
        info = updateInfo,
        url = updateUrl,
      })
    end
  end)
end

function M.showUpdateDialog(force)
  M.checkUpdate(function(hasNew, msg, result)
    if hasNew then
      -- 有新版本
      if not force then
        local ignoredVersion = M.getIgnoredVersion()
        if ignoredVersion and ignoredVersion == result.version then
          return
        end
      end
      local versionStr = result.versionName and string.format("%s (%s)", result.versionName, result.version) or result.version
      local message = string.format("发现新版本 %s\n\n%s", versionStr, result.info or "")

      import "com.google.android.material.dialog.MaterialAlertDialogBuilder"
      local builder = MaterialAlertDialogBuilder(activity)
      .setTitle("发现新版本")
      .setMessage(message)
      .setPositiveButton("立即更新", { onClick = function()
          if result.url then
            Helpers.UI.openUrl(result.url)
          end
      end })
      .setNegativeButton("取消", nil)

      if not force then
        builder.setNeutralButton("忽略此版本", { onClick = function()
            M.setIgnoredVersion(result.version)
            tip("已忽略版本 " .. versionStr)
        end })
      end

      builder.show()
     else
      -- 已是最新版本
      if force then
        Helpers.BottomDialog.confirm("当前已是最新正式版\n\n是否前往 GitHub Actions 下载测试版？", function()
          Helpers.UI.openUrl("https://github.com/zhihulite/Hydrogen/actions")
        end)
       else
        tip(msg)
      end
    end
  end)
end

return M