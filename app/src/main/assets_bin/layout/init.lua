-- layout/init.lua
local MaterialTextView = luajava.bindClass("com.google.android.material.textview.MaterialTextView")

-- 判断是否被 loadlayout 调用
local function isLoadlayoutCall()
  for level = 2, 10 do
    local info = debug.getinfo(level, "S")
    if not info then break end
    local source = info.source
    if source and source:find("loadlayout", 1, true) then
      return true
    end
  end
  return false
end

-- 懒加载模块或返回回退布局
local function loadOrFallback(path, key)
  if isLoadlayoutCall() then
    return nil
  end

  local fullPath = path .. "." .. key
  local ok, mod = pcall(require, fullPath)
  if ok then
    return mod
  end 
  return setmetatable({
    MaterialTextView,
    text = fullPath .. "为空",
    }, {
    __index = function(t, k)
      return loadOrFallback(fullPath, k)
    end
  })
end

-- 直接创建全局代理表
local M = setmetatable({}, {
  __index = function(_, key)
    return loadOrFallback("layout", key)
  end
})

return M