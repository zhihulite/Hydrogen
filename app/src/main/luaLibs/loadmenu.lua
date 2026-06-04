local Menu = luajava.bindClass("android.view.Menu")

local NONE = Menu.NONE
local type = type
local ipairs = ipairs
local pairs = pairs
local require = require
local loadbitmap = require("loadbitmap")

-- showAsAction 标志映射表
local ACTION_FLAGS = {
  never = 0,
  ifRoom = 1,
  always = 2,
  withText = 4,
  collapseActionView = 8,
}

--- 解析 showAsAction 属性
--- @param flags number|string 显示模式标志，支持数字或字符串，字符串可用 "|" 组合
--- @return number 解析后的整型标志
--- @usage parseActionFlags("always|withText")  -- 返回 2|4 = 6
--- @error 当 flags 类型非法或包含未知标志时抛出错误
local function parseActionFlags(flags)
  local flagsType = type(flags)
  if flagsType == "number" then
    return flags
  end
  if flagsType ~= "string" then
    error("showAsAction 必须是数字或字符串，当前类型：" .. flagsType)
  end
  local result = 0
  for word in string.gmatch(flags, "[^|]+") do
    local flagValue = ACTION_FLAGS[word]
    if not flagValue then
      error("未知的 showAsAction 标志：" .. word)
    end
    result = result | flagValue
  end
  return result
end

--- 设置菜单项图标
--- @param menuItem MenuItem 菜单项对象
--- @param icon string|Drawable 图标路径或 Drawable 对象
local function setIcon(menuItem, icon)
  if not icon then return end
  if type(icon) == "string" then
    local bitmap = loadbitmap(icon)
    if bitmap then
      menuItem.icon = bitmap
    end
   else
    menuItem.icon = icon
  end
end

--- 加载菜单
--- @param menu Menu 目标菜单对象
--- @param items table 菜单配置列表
--- @return table idMap，键为配置中的 id（字符串），值为对应的 MenuItem
---
--- 配置字段：
--- id, title, icon, asAction, group, order, enabled, visible, checkable, checked, click
--- items - 子菜单配置（存在时自动创建子菜单）
---
--- @usage
--- loadmenu(menu, {
--- -- 普通菜单
---   { id = "home", title = "主页", asAction = "always", click = function() end },
--- -- 子菜单
---   { id = "more", title = "更多", items = {
---     { id = "share", title = "分享", click = function() end }
---   }}
--- })
local function loadmenu(menu, items)
  if type(items) ~= "table" then
    error("菜单配置必须是表")
  end

  local idMap = {}

  for _, cfg in ipairs(items) do
    if type(cfg) ~= "table" then
      error("菜单项配置必须是表")
    end

    local hasSubMenu = type(cfg.items) == "table"
    local method = hasSubMenu and "addSubMenu" or "add"

    local menuItem = menu[method](
    cfg.group or NONE,
    cfg.itemId or NONE,
    cfg.order or NONE,
    cfg.title or ""
    )

    if hasSubMenu then
      local subMap = loadmenu(menuItem, cfg.items)
      for k, v in pairs(subMap) do
        idMap[k] = v
      end
    end

    setIcon(menuItem, cfg.icon)
    
    --addSubMenu 返回 SubMenuBuilder，仅用于构建菜单项，不进行相关设置。
    if not hasSubMenu then
      if cfg.asAction then
        menuItem.showAsActionFlags = parseActionFlags(cfg.asAction)
      end

      if cfg.click then
        menuItem.onMenuItemClick = function()
          cfg.click(menuItem)
          return true
        end
      end

      if cfg.id then
        idMap[cfg.id] = menuItem
      end
    end

    if cfg.enabled == false then
      menuItem.enabled = false
    end
    if cfg.visible == false then
      menuItem.visible = false
    end
    if cfg.checkable then
      menuItem.checkable = true
    end
    if cfg.checked then
      menuItem.checked = true
    end
  end

  return idMap
end

return loadmenu