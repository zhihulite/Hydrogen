-- helpers/resources.lua
-- 极简 Android 资源访问工具
-- 使用方式：
--   local color = resource.app.attr.colorPrimary          -- 自动返回颜色值
--   local size = resource.android.attr.actionBarSize      -- 自动返回尺寸（px）
--   local flag = resource.android.attr.windowNoTitle      -- 自动返回布尔值
--   local text = resource.app.string.app_name             -- 静态字符串
--   local icon = resource.app.drawable.ic_launcher        -- 静态图片

import "androidx.core.content.ContextCompat"
import "android.util.TypedValue"

local resources = activity.resources -- 获取资源管理器
local theme = activity.theme -- 获取当前主题

-- 静态资源类型的获取方法映射表
local staticGetters = {
  color = function(id) return ContextCompat.getColor(activity, id) end,
  drawable = function(id) return ContextCompat.getDrawable(activity, id) end,
  string = function(id) return resources.getString(id) end,
  dimen = function(id) return resources.getDimension(id) end,
  integer = function(id) return resources.getInteger(id) end,
  bool = function(id) return resources.getBoolean(id) end,
  id = function(id) return id end,
  anim = function(id) return resources.getAnimation(id) end,
  animator = function(id) return resources.getAnimator(id) end,
  array = function(id) return resources.getStringArray(id) end,
  fraction = function(id) return resources.getFraction(id, 1, 1) end,
}

-- 获取静态资源（字符串、颜色、图片等）
local function getStatic(rClass, type, name)
  local id = rClass[type] and rClass[type][name]
  if not id then error(string.format("Resource not found: %s.%s.%s", rClass, type, name)) end
  return staticGetters[type](id)
end

-- 获取主题属性（?attr/xxx 的值），自动识别类型并转换
local function getThemeAttr(rClass, attrName, styleId)
  local attrId = rClass.attr and rClass.attr[attrName]
  if not attrId then error(string.format("Attribute not found: %s.attr.%s", rClass, attrName)) end
  local arr = theme.obtainStyledAttributes(styleId or 0, { attrId })
  local tv = TypedValue()
  local success = arr.getValue(0, tv)
  arr.recycle()
  if not success then return nil end
  -- 根据类型自动转换
  if tv.type == TypedValue.TYPE_DIMENSION then
    return tv.getDimension(resources.displayMetrics)
   elseif tv.type == TypedValue.TYPE_FLOAT then
    return tv.float
   elseif tv.type >= TypedValue.TYPE_FIRST_COLOR_INT and tv.type <= TypedValue.TYPE_LAST_COLOR_INT then
    return tv.data
   elseif tv.type == TypedValue.TYPE_STRING then
    return tostring(tv.string)
   elseif tv.type == TypedValue.TYPE_INT_BOOLEAN then
    return tv.data ~= 0
   elseif tv.type == TypedValue.TYPE_INT_DEC or tv.type == TypedValue.TYPE_INT_HEX then
    return tv.data
   else
    return tv.resourceId
  end
end

--- 构建访问器，通过元表实现直接访问
local function buildAccessor(rClass)
  return setmetatable({}, {
    __index = function(_, key)
      -- 处理 attr 主题属性
      if key == "attr" then
        return setmetatable({}, {
          __index = function(_, attrName)
            -- 直接返回属性值
            return getThemeAttr(rClass, attrName)
          end
        })
      end
      -- 处理静态资源类型（string、color、drawable 等）
      if staticGetters[key] then
        return setmetatable({}, {
          __index = function(_, name) return getStatic(rClass, key, name) end
        })
      end
      return nil
    end
  })
end

-- 获取应用自己的 R 类
local appR = luajava.bindClass(activity.packageName .. ".R")
-- 获取 Android 系统的 R 类
local androidR = luajava.bindClass("android.R")

-- 返回两个命名空间的访问器
return {
  app = buildAccessor(appR), -- 访问应用资源：resource.app.xxx
  android = buildAccessor(androidR), -- 访问系统资源：resource.android.xxx
}