-- layout/init.lua
-- 布局命名空间：按 Layouts.<目录>.<文件> 懒加载布局模块，加载不到时回退成提示文本
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
  -- 目录路径的 require 必然报 module not found，属正常分支；
  -- 其余错误说明布局模块自身有问题，打印原因方便定位
  if not tostring(mod):find("not found", 1, true) then
    print("[layout] " .. fullPath .. " 加载失败: " .. tostring(mod))
  end
  -- 缓存放在闭包里；回退表本身要作为布局表传给 loadlayout，属性键必须保持干净
  local cache = {}
  return setmetatable({
    MaterialTextView,
    text = fullPath .. "为空",
    }, {
    __index = function(_, k)
      local v = cache[k]
      if v == nil then
        v = loadOrFallback(fullPath, k)
        if v ~= nil then
          cache[k] = v
        end
      end
      return v
    end
  })
end

-- 直接创建全局代理表
local M = setmetatable({}, {
  __index = function(t, key)
    local v = loadOrFallback("layout", key)
    if v ~= nil then
      rawset(t, key, v)
    end
    return v
  end
})

return M