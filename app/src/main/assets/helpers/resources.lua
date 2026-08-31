-- helpers/resources.lua
-- 极简 Android 资源访问工具
-- 使用方式：
--   local color = resources.app.attr.colorPrimary          -- 自动返回颜色值
--   local size = resources.android.attr.actionBarSize      -- 自动返回尺寸（px）
--   local flag = resources.android.attr.windowNoTitle      -- 自动返回布尔值
--   local text = resources.app.string.app_name             -- 静态字符串
--   local icon = resources.app.drawable.ic_launcher        -- 静态图片

import "androidx.core.content.ContextCompat"
import "android.util.TypedValue"

local resources = activity.resources
local theme = activity.theme
local packageName = activity.packageName

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

-- 通过资源名称获取资源 ID
local function getResourceId(type, name, isSystem)
  local pkg = isSystem and "android" or packageName
  return resources.getIdentifier(name, type, pkg)
end

-- 获取静态资源
local function getStatic(type, name, isSystem)
  local id = getResourceId(type, name, isSystem)
  if id == 0 then
    error(string.format("Resource not found: %s.%s", type, name))
  end
  return staticGetters[type](id)
end

-- 获取主题属性，自动识别类型并转换
local function getThemeAttr(attrName, isSystem)
  local attrId = getResourceId("attr", attrName, isSystem)
  if attrId == 0 then
    error(string.format("Attribute not found: %s", attrName))
  end
  local arr = theme.obtainStyledAttributes(0, { attrId })
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

-- 构建访问器，通过元表实现直接访问
local function buildAccessor(isSystem)
  return setmetatable({}, {
    __index = function(_, key)
      if key == "attr" then
        return setmetatable({}, {
          __index = function(_, attrName)
            return getThemeAttr(attrName, isSystem)
          end
        })
      end
      if staticGetters[key] then
        return setmetatable({}, {
          __index = function(_, name)
            return getStatic(key, name, isSystem)
          end
        })
      end
      return nil
    end
  })
end

-- 返回两个命名空间的访问器
return {
  app = buildAccessor(false),
  android = buildAccessor(true),
}