-- components/dialogs/MenuDialog.lua
local M = {}

-- 菜单项样式
local menuItemLayout = {
    LinearLayout,
    layout_width = -1,
    layout_height = "48dp",
    orientation = "horizontal",
    gravity = "center_vertical",
    {
        ImageView,
        id = "icon",
        layout_width = "23dp",
        layout_height = "23dp",
        layout_marginLeft = "16dp",
        colorFilter = "#757575",
    },
    {
        TextView,
        id = "text",
        textSize = "14sp",
        textColor = "#212121",
        layout_width = -1,
        layout_height = -1,
        gravity = "left|center",
        paddingLeft = "16dp",
        typeface = "product",
    }
}

-- 创建菜单弹窗
function M.new(items, title)
    local self = {
        items = items or {},
        title = title,
        popup = nil,
        onItemClick = nil,
    }
    setmetatable(self, { __index = M })
    return self
end

-- 设置菜单项
function M:setItems(items)
    self.items = items
    return self
end

-- 设置标题
function M:setTitle(title)
    self.title = title
    return self
end

-- 设置点击回调
function M:setOnItemClickListener(callback)
    self.onItemClick = callback
    return self
end

-- 创建PopupWindow
function M:createPopup()
    local colors = AppTheme.getColors()
    
    -- 创建布局
    local layout = {
        LinearLayout,
        orientation = "vertical",
        {
            CardView,
            cardElevation = "6dp",
            cardBackgroundColor = colors.background,
            radius = "8dp",
            layout_width = "200dp",
            layout_height = -2,
            layout_margin = "8dp",
            {
                LinearLayout,
                orientation = "vertical",
                {
                    TextView,
                    id = "titleView",
                    text = self.title or "",
                    gravity = "left",
                    padding = "12dp",
                    paddingTop = "12dp",
                    typeface = "product-Bold",
                    textColor = colors.primary,
                    layout_width = -1,
                    layout_height = -1,
                    textSize = "13sp",
                    visibility = self.title and View.VISIBLE or View.GONE,
                },
                {
                    ListView,
                    id = "listView",
                    layout_marginTop = self.title and "0dp" or "8dp",
                    layout_height = -1,
                    layout_width = -1,
                    dividerHeight = 0,
                }
            }
        }
    }
    
    local views = {}
    local contentView = loadlayout(layout, views)
    
    -- 创建适配器
    local adapter = LuaAdapter(activity, self.items, menuItemLayout)
    views.listView.setAdapter(adapter)
    
    -- 设置图标
    adapter.setAdapterInterface({
        onBindViewHolder = function(holder, position)
            local item = self.items[position + 1]
            if item.icon and holder.tag.icon then
                local iconPath = Helpers.Image.getIcon(item.icon)
                local drawable = Drawable.createFromPath(iconPath)
                if drawable then
                    holder.tag.icon.setImageDrawable(drawable)
                end
            end
            if holder.tag.text then
                holder.tag.text.setText(item.title or item.text or "")
            end
        end
    })
    
    -- 点击事件
    views.listView.onItemClick = function(parent, view, position, id)
        if self.onItemClick then
            self.onItemClick(position, self.items[position + 1])
        end
        self.dismiss()
    end
    
    -- 创建PopupWindow
    self.popup = PopupWindow(contentView)
    self.popup.setWidth(dp2px(200))
    self.popup.setHeight(WindowManager.LayoutParams.WRAP_CONTENT)
    self.popup.setFocusable(true)
    self.popup.setOutsideTouchable(true)
    self.popup.setBackgroundDrawable(ColorDrawable(0x00000000))
    
    return self
end

-- 显示在锚点下方
function M:showAsDropDown(anchorView, x, y)
    if not self.popup then
        self:createPopup()
    end
    x = x or 0
    y = y or 0
    self.popup.showAsDropDown(anchorView, x, y)
end

-- 显示在指定位置
function M:showAtLocation(parent, gravity, x, y)
    if not self.popup then
        self:createPopup()
    end
    self.popup.showAtLocation(parent, gravity, x, y)
end

-- 关闭
function M:dismiss()
    if self.popup then
        self.popup.dismiss()
        self.popup = nil
    end
end

-- 静态方法：快速显示菜单
function M.show(items, anchorView, callback)
    local dialog = M.new(items)
    dialog:setOnItemClickListener(callback)
    dialog:showAsDropDown(anchorView)
    return dialog
end

-- 静态方法：快速显示带标题的菜单
function M.showWithTitle(items, title, anchorView, callback)
    local dialog = M.new(items, title)
    dialog:setOnItemClickListener(callback)
    dialog:showAsDropDown(anchorView)
    return dialog
end

return M