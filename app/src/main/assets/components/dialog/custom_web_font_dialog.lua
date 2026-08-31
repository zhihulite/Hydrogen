-- components/dialog/custom_web_font_dialog.lua
-- 自定义网页字体弹窗：开关自定义字体、选用 App 字体或从文件导入字体

local M = {}

import "com.google.android.material.dialog.MaterialAlertDialogBuilder"
import "android.widget.CompoundButton"
import "android.view.View"

local SharedDataKeys = Constants.SharedDataKeys

--- 显示自定义网页字体弹窗，字体路径写入 CUSTOM_WEB_FONT 配置
function M.show()
  local views = {}
  local hasFont = Extensions.Config.getString(SharedDataKeys.CUSTOM_WEB_FONT, "") ~= ""

  MaterialAlertDialogBuilder(activity)
  .setTitle("自定义网页字体")
  .setView(loadlayout(Layouts.pages.settings.dialogs.custom_font, views))
  .setPositiveButton("关闭", nil)
  .show()

  views.font_switch.checked = hasFont
  views.font_container.visibility = hasFont and View.VISIBLE or View.GONE

  -- 关闭开关即清掉缓存的字体文件与配置，容器同步隐藏
  views.font_switch.setOnCheckedChangeListener(luajava.createProxy(CompoundButton.OnCheckedChangeListener, {
    onCheckedChanged = function(switchView, isChecked)
      views.font_container.visibility = isChecked and View.VISIBLE or View.GONE
      if not isChecked then
        local fontDir = Extensions.File.getAppDir("fonts")
        if Extensions.File.exists(fontDir) then
          Extensions.File.delete(fontDir)
        end
        Extensions.Config.delete(SharedDataKeys.CUSTOM_WEB_FONT)
        tip("已关闭自定义字体，重启生效")
      end
    end
  }))

  views.app_font_btn.onClick = function()
    Extensions.Config.set(SharedDataKeys.CUSTOM_WEB_FONT, "appfont")
    tip("已使用软件默认字体，重启生效")
  end

  -- 选中的字体拷进软件目录后再落配置，配置里存的是拷贝后的路径
  views.choose_file_btn.onClick = function()
    Extensions.File.pickFile("font/ttf", function(uri, name)
      if uri then
        local destDir = Extensions.File.getAppDir("fonts")
        Extensions.File.mkdir(destDir)
        local destPath = destDir .. "/" .. name

        if Extensions.File.copyFromUri(uri, destPath) then
          Extensions.Config.set(SharedDataKeys.CUSTOM_WEB_FONT, destPath)
          tip("字体已选择，重启生效")
         else
          tip("保存失败")
        end
      end
    end)
  end
end

return M
