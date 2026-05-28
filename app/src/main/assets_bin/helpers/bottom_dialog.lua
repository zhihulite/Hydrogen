-- helpers/bottom_dialog.lua
-- 底部弹窗

local M = {}

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.core.widget.NestedScrollView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.bottomsheet.BottomSheetDialog"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"
import "android.view.View"
import "androidx.coordinatorlayout.widget.CoordinatorLayout"
import "com.google.android.material.bottomsheet.BottomSheetDragHandleView"
import "android.util.TypedValue"
import "com.google.android.material.divider.MaterialDivider"

--- 构建列表项的辅助函数
---@param container LinearLayoutCompat
---@param items table
---@param onItemClick function|nil
---@param onItemLongClick function|nil
---@param autoDismiss boolean
---@param dialog BottomSheetDialog
local function buildListItems(container, items, onItemClick, onItemLongClick, autoDismiss, dialog)
  if not container then return end
  container.removeAllViews()
  local colors = AppTheme.colors
  for i, item in ipairs(items) do
    -- 构建单个项布局
    local itemLayout = {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        paddingLeft = "24dp",
        paddingRight = "24dp",
        paddingTop = "6dp",
        paddingBottom = "0dp",
        gravity = "center_vertical",
        {
          MaterialTextView,
          id = "text",
          layout_width = 0,
          layout_weight = 1,
          text = item.title or item,
          textSize = AppTextStyle.bodyMedium.size,
          textColor = AppTextStyle.bodyMedium.color,
          typeface = AppTextStyle.bodyMedium.font,
        },
      },
    }
    -- 如果不是最后一项，添加分割线（左右留白）
    if i < #items then
      table.insert(itemLayout, {
        MaterialDivider,
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_marginLeft = "24dp",
        layout_marginRight = "24dp",
      })
    end

    local views = {}
    local itemView = loadlayout(itemLayout, views)

    -- 绑定点击事件
    itemView.onClick = function()
      if onItemClick then onItemClick(i, item) end
      if autoDismiss ~= false then dialog.dismiss() end
    end
    -- 绑定长按事件
    itemView.onLongClick = function()
      if onItemLongClick then
        return onItemLongClick(i, item, itemView)
      end
      return false
    end

    container.addView(itemView)
  end
end

--- 显示底部对话框
---@param opts table
---@return table { dialog, updateItems, dismiss }
function M.show(opts)
  opts = opts or {}
  local colors = AppTheme.colors

  local btns = {}
  if opts.neutralText then table.insert(btns, { text = opts.neutralText, type = "outline", cb = opts.onNeutral }) end
  if opts.negativeText then table.insert(btns, { text = opts.negativeText, type = "outline", cb = opts.onNegative }) end
  if opts.positiveText then table.insert(btns, { text = opts.positiveText, type = "filled", cb = opts.onPositive }) end

  local contentView
  if opts.contentView then
    contentView = opts.contentView
   else
    contentView = {
      MaterialTextView,
      layout_width = "match_parent",
      layout_height = "wrap_content",
      layout_marginLeft = "24dp",
      layout_marginRight = "24dp",
      layout_marginBottom = "16dp",
      text = opts.content or "",
      textSize = AppTextStyle.bodyMedium.size,
      typeface = AppTextStyle.bodyMedium.font,
      textColor = AppTextStyle.bodyMedium.color,
    }
  end

  local scrollContentItems = {
    { BottomSheetDragHandleView, layout_width = "match_parent", layout_height = "wrap_content" },
    opts.title and {
      MaterialTextView, layout_width = "match_parent", layout_height = "wrap_content",
      layout_marginLeft = "24dp", layout_marginRight = "24dp",
      layout_marginTop = "8dp", layout_marginBottom = "12dp",
      text = opts.title, textSize = AppTextStyle.titleSmall.size,
      textColor = colors.primary,
      typeface = AppTextStyle.titleSmall.font,
    } or nil,
    { LinearLayoutCompat, orientation = "vertical", layout_width = "match_parent", layout_height = "wrap_content", contentView },
    opts.listItems and {
      LinearLayoutCompat, id = "list_container", orientation = "vertical",
      layout_width = "match_parent", layout_height = "wrap_content",
      layout_marginTop = "0dp",
    } or nil,
  }

  local layoutItems = {
    {
      NestedScrollView, layout_width = "match_parent", layout_height = 0, layout_weight = 1,
      { LinearLayoutCompat, orientation = "vertical", layout_width = "match_parent", layout_height = "wrap_content", unpack(scrollContentItems) }
    },
    #btns > 0 and {
      LinearLayoutCompat, id = "button_container", orientation = "horizontal",
      layout_width = "match_parent", layout_height = "wrap_content",
      layout_margin = "16dp", gravity = "end",
    } or nil,
  }

  local layout = { LinearLayoutCompat, orientation = "vertical", layout_width = "match_parent", layout_height = "wrap_content", unpack(layoutItems) }
  local views = {}
  local root = loadlayout(layout, views)

  if #btns > 0 and views.button_container then
    for i, btn in ipairs(btns) do
      local btnView = btn.type == "outline" and Helpers.MaterialWidgets.Button_Outlined(activity) or Helpers.MaterialWidgets.Button_Text(activity)
      btnView.text = btn.text
      btnView.setPadding(dp2px(20), dp2px(10), dp2px(20), dp2px(10))
      local params = LinearLayoutCompat.LayoutParams(LinearLayoutCompat.LayoutParams.WRAP_CONTENT, LinearLayoutCompat.LayoutParams.WRAP_CONTENT)
      if i > 1 then params.leftMargin = dp2px(8) end
      btnView.layoutParams = params
      views.button_container.addView(btnView)
    end
  end

  local sheet = BottomSheetDialog(activity)
  sheet.contentView = root
  local dialog = sheet.show()
  sheet.cancelable = opts.cancelable ~= false

  if #btns > 0 and views.button_container then
    local children = views.button_container.childCount
    for i = 0, children - 1 do
      local btnView = views.button_container.getChildAt(i)
      local btn = btns[i + 1]
      if btnView and btn then
        btnView.onClick = function()
          local autoDismiss = true
          if btn.cb then
            local ret = btn.cb(dialog)
            if ret == false then autoDismiss = false end
          end
          if opts.autoDismiss ~= false and autoDismiss then dialog.dismiss() end
        end
      end
    end
  end

  if opts.listItems and views.list_container then
    buildListItems(views.list_container, opts.listItems, opts.onItemClick, opts.onItemLongClick, opts.autoDismiss, dialog)
  end

  local wrapper = {
    dialog = dialog,
    updateItems = function(newItems)
      if views.list_container then
        buildListItems(views.list_container, newItems, opts.onItemClick, opts.onItemLongClick, opts.autoDismiss, dialog)
      end
    end,
    dismiss = function() dialog.dismiss() end
  }
  return wrapper
end

---@param msg string
---@param cb function
function M.alert(msg, cb)
  return M.show({ content = msg, positiveText = "确定", onPositive = cb })
end

---@param msg string
---@param onYes function
---@param onNo function
function M.confirm(msg, onYes, onNo)
  return M.show({ title = "确认", content = msg, positiveText = "确定", negativeText = "取消", onPositive = onYes, onNegative = onNo })
end

---@param msg string
---@param onYes function
function M.delete(msg, onYes)
  local colors = AppTheme.colors
  return M.show({ title = "删除", content = msg or "确定删除吗？", positiveText = "删除", negativeText = "取消", buttonColor = colors.error, onPositive = onYes })
end

--- 列表选择对话框
---@param items table 列表项
---@param callback function
---@param title string|nil
---@param onItemLongClick function|nil
function M.select(items, callback, title, onItemLongClick)
  return M.show({
    title = title,
    listItems = items,
    onItemClick = callback,
    onItemLongClick = onItemLongClick,
    negativeText = "取消",
  })
end

--- 单选列表对话框
---@param items table
---@param selectedIndex number
---@param callback function
---@param title string|nil
---@param onItemLongClick function|nil
function M.selectSingle(items, selectedIndex, callback, title, onItemLongClick)
  local enhancedItems = {}
  for i, item in ipairs(items) do
    local titleText = type(item) == "table" and item.title or item
    enhancedItems[i] = { title = titleText, selected = (i == selectedIndex) }
  end
  local onItemClick = function(index, item)
    for i, it in ipairs(enhancedItems) do it.selected = (i == index) end
    wrapper.updateItems(enhancedItems)
    if callback then callback(index, item) end
  end
  local wrapper = M.show({
    title = title,
    listItems = enhancedItems,
    onItemClick = onItemClick,
    onItemLongClick = onItemLongClick,
    negativeText = "取消",
  })
  return wrapper
end

return M