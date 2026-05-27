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
--- 配置项字段说明：
--- @field id string|nil 菜单项标识，用作返回映射的键（可选）
--- @field itemId number|nil 菜单项数字 ID，传给 add() 方法（可选，不设置则使用 NONE）
--- @field title string 菜单项标题（必填）
--- @field icon string|Drawable|nil 图标路径或 Drawable 对象（可选）
--- @field asAction string|number|nil showAsAction 标志，如 "always"、"never"、"ifRoom"、"always|withText"（可选）
--- @field group number|nil 菜单组 ID（可选）
--- @field order number|nil 排序（可选）
--- @field enabled boolean|nil 是否启用，默认 true（可选）
--- @field visible boolean|nil 是否可见，默认 true（可选）
--- @field checkable boolean|nil 是否可勾选（可选）
--- @field checked boolean|nil 是否已勾选（可选）
--- @field click function|nil 点击回调，参数为 menuItem（可选）
---
--- 子菜单：如果配置项的第一个元素是子表，则视为子菜单，子菜单配置同该表
---
--- @error 当 items 不是表或菜单项配置不是表时抛出错误
---
--- @usage
--- -- 普通菜单
--- local ids = loadmenu(menu, {
---   { id = "home", title = "主页", icon = "ic_home.png", asAction = "always", click = function(item) print("主页") end },
---   { id = "settings", title = "设置", asAction = "never", click = function() print("设置") end }
--- })
---
--- -- 子菜单
--- local ids = loadmenu(menu, {
---   { id = "more", title = "更多", {
---     { id = "share", title = "分享", click = function() end },
---     { id = "copy", title = "复制", click = function() end }
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

    local isSubMenu = type(cfg[1]) == "table"
    local method = isSubMenu and "addSubMenu" or "add"

    -- 创建菜单项
    local menuItem = menu[method](
    cfg.group or NONE,
    cfg.itemId or NONE,
    cfg.order or NONE,
    cfg.title or ""
    )

    -- 子菜单递归加载
    if isSubMenu then
      local subMap = loadmenu(menuItem, cfg[1])
      for k, v in pairs(subMap) do
        idMap[k] = v
      end
    end

    -- 设置图标
    setIcon(menuItem, cfg.icon)

    -- 设置显示模式（仅普通菜单有效）
    if cfg.asAction and not isSubMenu then
      menuItem.showAsActionFlags = parseActionFlags(cfg.asAction)
    end

    -- 设置属性
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

    -- 设置点击事件
    if cfg.click then
      menuItem.onMenuItemClick = function()
        cfg.click(menuItem)
        return true
      end
    end

    -- 存储 id 映射
    if cfg.id then
      idMap[cfg.id] = menuItem
    end
  end

  return idMap
end

return loadmenu