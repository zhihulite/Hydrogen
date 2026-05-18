-- components/dialogs/ConfirmDialog.lua
local M = {}

-- 确认对话框
function M.new()
    local self = {
        title = "提示",
        message = "",
        positiveText = "确定",
        negativeText = "取消",
        neutralText = nil,
        onPositive = nil,
        onNegative = nil,
        onNeutral = nil,
        cancelable = true,
    }
    setmetatable(self, { __index = M })
    return self
end

-- 设置标题
function M:setTitle(title)
    self.title = title
    return self
end

-- 设置消息
function M:setMessage(message)
    self.message = message
    return self
end

-- 设置确定按钮
function M:setPositiveButton(text, callback)
    self.positiveText = text
    self.onPositive = callback
    return self
end

-- 设置取消按钮
function M:setNegativeButton(text, callback)
    self.negativeText = text
    self.onNegative = callback
    return self
end

-- 设置中性按钮
function M:setNeutralButton(text, callback)
    self.neutralText = text
    self.onNeutral = callback
    return self
end

-- 设置是否可取消
function M:setCancelable(cancelable)
    self.cancelable = cancelable
    return self
end

-- 显示对话框
function M:show()
    local builder = AlertDialog.Builder(activity)
        .setTitle(self.title)
        .setMessage(self.message)
        .setCancelable(self.cancelable)
    
    if self.positiveText then
        builder.setPositiveButton(self.positiveText, function(dialog)
            if self.onPositive then
                self.onPositive(dialog)
            end
        end)
    end
    
    if self.negativeText then
        builder.setNegativeButton(self.negativeText, function(dialog)
            if self.onNegative then
                self.onNegative(dialog)
            end
        end)
    end
    
    if self.neutralText then
        builder.setNeutralButton(self.neutralText, function(dialog)
            if self.onNeutral then
                self.onNeutral(dialog)
            end
        end)
    end
    
    local dialog = builder.show()
    
    -- 让消息可选中
    pcall(function()
        local messageView = dialog.findViewById(android.R.id.message)
        if messageView then
            messageView.setTextIsSelectable(true)
        end
    end)
    
    return dialog
end

-- 静态方法：快速显示确认对话框
function M.confirm(message, onConfirm, onCancel)
    M.new()
        :setMessage(message)
        :setPositiveButton("确定", onConfirm)
        :setNegativeButton("取消", onCancel)
        :show()
end

-- 静态方法：快速显示提示对话框
function M.alert(message, onDismiss)
    M.new()
        :setMessage(message)
        :setPositiveButton("我知道了", onDismiss)
        :setCancelable(false)
        :show()
end

-- 静态方法：快速显示删除确认
function M.deleteConfirm(message, onDelete)
    M.new()
        :setTitle("删除")
        :setMessage(message or "删除该内容？该操作不可撤消！")
        :setPositiveButton("是的", onDelete)
        :setNegativeButton("点错了")
        :show()
end

-- 静态方法：快速显示双按钮对话框
function M.twoButton(title, message, positiveText, negativeText, onPositive, onNegative)
    M.new()
        :setTitle(title)
        :setMessage(message)
        :setPositiveButton(positiveText, onPositive)
        :setNegativeButton(negativeText, onNegative)
        :show()
end

-- 静态方法：快速显示三按钮对话框
function M.threeButton(title, message, positiveText, negativeText, neutralText, onPositive, onNegative, onNeutral)
    M.new()
        :setTitle(title)
        :setMessage(message)
        :setPositiveButton(positiveText, onPositive)
        :setNegativeButton(negativeText, onNegative)
        :setNeutralButton(neutralText, onNeutral)
        :show()
end

return M