-- components/dialog/CollectionEditSheet.lua
-- 创建/编辑收藏夹表单弹窗

local M = {}

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.appcompat.widget.AppCompatEditText"
import "com.google.android.material.bottomsheet.BottomSheetDialog"
import "com.google.android.material.bottomsheet.BottomSheetBehavior"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.materialswitch.MaterialSwitch"
import "android.view.View"

local MaterialWidgets = Helpers.MaterialWidgets

--- 显示收藏夹弹窗（自动判断创建/编辑）
--- @param opts table
--- @param opts.collectionId string|nil 收藏夹ID（有则为编辑，无则为创建）
--- @param opts.name string 收藏夹名称
--- @param opts.description string 收藏夹描述
--- @param opts.isPublic boolean 是否公开
--- @param opts.isDefault boolean|nil 是否设为默认收藏夹
--- @param opts.onSuccess function(collectionId, name) 成功回调
--- @param opts.onError function(err) 失败回调
function M.show(opts)
  local self = {}
  setmetatable(self, { __index = M })

  self.opts = opts
  self.views = {}
  self.isSaving = false
  local isEdit = opts.collectionId ~= nil and opts.collectionId ~= ""

  local colors = AppTheme.getColors()

  local layout = {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      padding = "16dp",
      {
        MaterialTextView,
        text = isEdit and "编辑收藏夹" or "创建收藏夹",
        textSize = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface = AppTextStyle.titleSmall.font,
        layout_marginBottom = "16dp",
      },
      {
        MaterialTextView,
        text = "收藏夹名称",
        textSize = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface = AppTextStyle.bodySmall.font,
        layout_marginBottom = "4dp",
      },
      {
        AppCompatEditText,
        id = "name_input",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        text = opts.name or "",
        textSize = AppTextStyle.bodyMedium.size,
        textColor = AppTextStyle.bodyMedium.color,
        hint = "请输入收藏夹名称",
        layout_marginBottom = "16dp",
      },
      {
        MaterialTextView,
        text = "描述（选填）",
        textSize = AppTextStyle.bodySmall.size,
        textColor = AppTextStyle.bodySmall.color,
        typeface = AppTextStyle.bodySmall.font,
        layout_marginBottom = "4dp",
      },
      {
        AppCompatEditText,
        id = "desc_input",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        text = opts.description or "",
        textSize = AppTextStyle.bodyMedium.size,
        textColor = AppTextStyle.bodyMedium.color,
        hint = "请输入描述",
        maxLines = 3,
        layout_marginBottom = "16dp",
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        gravity = "center_vertical",
        layout_marginBottom = "16dp",
        {
          MaterialTextView,
          layout_width = "0dp",
          layout_weight = 1,
          text = "仅自己可见",
          textSize = AppTextStyle.bodyMedium.size,
          textColor = AppTextStyle.bodyMedium.color,
        },
        {
          MaterialSwitch,
          id = "public_switch",
          checked = opts.isPublic == nil or opts.isPublic,
        }
      },
      {
        LinearLayoutCompat,
        id = "default_layout",
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        gravity = "center_vertical",
        layout_marginBottom = "16dp",
        {
          MaterialTextView,
          layout_width = "0dp",
          layout_weight = 1,
          text = "设为默认收藏夹",
          textSize = AppTextStyle.bodyMedium.size,
          textColor = AppTextStyle.bodyMedium.color,
        },
        {
          MaterialSwitch,
          id = "default_switch",
          checked = opts.isDefault or false,
        }
      },
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        gravity = "end",
        {
          MaterialWidgets.Button_Text,
          id = "cancel_btn",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
          text = "取消",
          layout_marginRight = "8dp",
        },
        {
          MaterialWidgets.Button_Text,
          id = "save_btn",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
          text = isEdit and "保存" or "创建",
        }
      }
    }
  }

  self.root = loadlayout(layout, self.views)

  self.bottomSheet = BottomSheetDialog(activity)
  self.bottomSheet.setContentView(self.root)

  local behavior = self.bottomSheet.getBehavior()
  behavior.setSkipCollapsed(true)
  behavior.setPeekHeight(-1)

  self.views.cancel_btn.onClick = function()
    self.bottomSheet.dismiss()
  end

  self.views.save_btn.onClick = function()
    if self.isSaving then return end

    local name = self.views.name_input and self.views.name_input.getText().toString() or ""
    if name == "" then
      tip("请输入收藏夹名称")
      return
    end
    local description = self.views.desc_input and self.views.desc_input.getText().toString() or ""
    local isPublic = self.views.public_switch and self.views.public_switch.isChecked() or true
    local isDefault = self.views.default_switch and self.views.default_switch.isChecked() or false

    self.isSaving = true
    self.views.save_btn.setEnabled(false)

    local function doRequest(url, postData)
      if isEdit then
        NetWork.put(url, postData, Headers.defaultHead, function(code)
          self.isSaving = false
          self.views.save_btn.setEnabled(true)
          if code == 200 then
            tip("保存成功")
            if opts.onSuccess then opts.onSuccess(opts.collectionId, name) end
            self.bottomSheet.dismiss()
           else
            tip("保存失败")
            if opts.onError then opts.onError("保存失败") end
          end
        end)
       else

        NetWork.post(url, postData, Headers.post, function(code, content)
          self.isSaving = false
          self.views.save_btn.setEnabled(true)
          if code == 200 then
            local data = json.decode(content)
            local newId = tostring(data.collection and data.collection.id or "")
            tip("创建成功")
            if opts.onSuccess then opts.onSuccess(newId, name) end
            self.bottomSheet.dismiss()
           else
            tip("创建失败")
            if opts.onError then opts.onError("创建失败") end
          end
        end)
      end
    end

    local postData = json.encode({
      title = name,
      description = description,
      is_public = isPublic,
      is_default = isDefault
    })

    if isEdit then
      doRequest("https://api.zhihu.com/collections/" .. opts.collectionId, postData)
     else
      doRequest("https://api.zhihu.com/collections", postData)
    end
  end

  self.bottomSheet.show()
end

return M