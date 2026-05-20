-- extensions/class.lua
-- 轻量级 Lua 面向对象系统
-- author: huajiqaq
--
-- 功能：
--   • 单继承 class(super, default_args)
--   • final 方法/类 cls:final(...) / cls:final_class()
--   • 抽象方法 cls:abstract(...)
--   • 静态成员 cls:static(name, value)
--   • 混入 cls:mixin(t1, t2, ...)
--   • 默认构造参数（无参实例化时自动传入）
--   • 链式方法 cls:chainDown/chainUp("method")
--   • __call 语法糖 MyClass(...) -> MyClass:new(...)
--   • 动态扩展注入 cls:add(name, func)
-- ============================================================================

local _class_vtb = setmetatable({}, { __mode = "k" })
local _final_class = {}

---获取继承链上的方法列表
---@param cls table 类
---@param method string 方法名
---@param direction string "up" 或 "down"
---@return table 函数列表
local function get_chain_methods(cls, method, direction)
  local funcs = {}
  local cur = cls
  if direction == "down" then
    local list = {}
    while cur do
      local vtb = _class_vtb[cur]
      if vtb and vtb[method] then
        table.insert(list, 1, vtb[method])
      end
      cur = cur.super
    end
    funcs = list
   else
    while cur do
      local vtb = _class_vtb[cur]
      if vtb and vtb[method] then
        table.insert(funcs, vtb[method])
      end
      cur = cur.super
    end
  end
  return funcs
end

-- ========== 扩展函数定义 ==========

---注册链式调用
---@param method string 方法名
---@param direction string "up" 或 "down"
---@return table 返回自身
local function ext_chain(self, method, direction)
  self._chain_methods[method] = direction == "up" and "up" or "down"
  return self
end

---向上链式（子类→父类）
---@vararg string 方法名列表
---@return table 返回自身
local function ext_chainUp(self, ...)
  for i = 1, select('#', ...) do
    self._chain_methods[select(i, ...)] = "up"
  end
  return self
end

---向下链式（父类→子类）
---@vararg string 方法名列表
---@return table 返回自身
local function ext_chainDown(self, ...)
  for i = 1, select('#', ...) do
    self._chain_methods[select(i, ...)] = "down"
  end
  return self
end

---标记 final 方法（子类不可重写）
---@vararg string 方法名列表
---@return table 返回自身
local function ext_final(self, ...)
  local vtb = _class_vtb[self]
  if not vtb then error("不是有效类") end
  for i = 1, select('#', ...) do
    vtb._final[select(i, ...)] = true
  end
  return self
end

---标记 final 类（禁止继承）
---@return table 返回自身
local function ext_final_class(self)
  _final_class[self] = true
  return self
end

---标记抽象方法（子类必须实现）
---@vararg string 方法名列表
---@return table 返回自身
local function ext_abstract(self, ...)
  local vtb = _class_vtb[self]
  if not vtb then error("不是有效类") end
  for i = 1, select('#', ...) do
    vtb._abstract[select(i, ...)] = true
  end
  return self
end

---混入：将外部表的方法复制到类
---@vararg table 要混入的表
---@return table 返回自身
local function ext_mixin(self, ...)
  local vtb = _class_vtb[self]
  if not vtb then error("不是有效类") end
  for _, m in ipairs({...}) do
    for k, v in pairs(m) do
      if type(v) == "function" then
        vtb[k] = v
      end
    end
  end
  return self
end

---定义静态成员
---@param name string 名称
---@param value any 值
---@return table 返回自身
local function ext_static(self, name, value)
  rawset(self, name, value)
  return self
end

---动态添加实例方法
---@param key string|table 方法名或方法表
---@param value? function 当 key 为字符串时的函数
---@return table 返回自身
local function ext_add(self, key, value)
  local vtb = _class_vtb[self]
  if not vtb then error("不是有效类") end
  if type(key) == "table" then
    for k, v in pairs(key) do
      if type(v) == "function" then
        vtb[k] = v
      end
    end
   elseif type(key) == "string" and type(value) == "function" then
    vtb[key] = value
   else
    error("cls:add 需要 (name, func) 或 (table)")
  end
  return self
end

---构造函数（实例化入口）
---@vararg any 构造参数
---@return table 实例对象
local function ext_new(self, ...)
  local vtb = _class_vtb[self]
  if not vtb then error("不是有效类") end
  local obj = {}
  local args = { ... }

  -- 默认参数：仅无参时生效，原样传递给所有 ctor
  if #args == 0 and self._default_args then
    local def = self._default_args
    if type(def) == "function" then
      local d = def()
      args = type(d) == "table" and d or { d }
     else
      args = def
    end
  end

  setmetatable(obj, {
    __index = function(t, k)
      local method = vtb[k]
      if not method then return nil end
      local dir = self._chain_methods[k]
      if dir then
        local funcs = get_chain_methods(self, k, dir)
        if #funcs == 0 then return method end
        return function(...)
          local ret
          for _, fn in ipairs(funcs) do
            ret = fn(t, ...)
          end
          return ret
        end
      end
      return method
    end
  })
  obj.__class = self

  -- 向下调用所有 ctor，每个 ctor 收到相同的 args
  local ctor_funcs = get_chain_methods(self, "ctor", "down")
  for _, fn in ipairs(ctor_funcs) do
    fn(obj, table.unpack(args))
  end

  -- 抽象方法检查（递归所有父类抽象方法）
  local function collect_abstract(cls)
    local abs = {}
    local cur = cls
    while cur do
      local cur_vtb = _class_vtb[cur]
      if cur_vtb and cur_vtb._abstract then
        for name in pairs(cur_vtb._abstract) do
          abs[name] = true
        end
      end
      cur = cur.super
    end
    return abs
  end

  local all_abstract = collect_abstract(self)
  for name in pairs(all_abstract) do
    if not vtb[name] then
      error(string.format("类 '%s' 未实现抽象方法 '%s'", tostring(self), name))
    end
  end

  return obj
end

---注入所有扩展方法到类
---@param cls table 类
---@return table 返回自身
local function inject_extensions(cls)
  cls.chain = ext_chain
  cls.chainUp = ext_chainUp
  cls.chainDown = ext_chainDown
  cls.final = ext_final
  cls.final_class = ext_final_class
  cls.abstract = ext_abstract
  cls.mixin = ext_mixin
  cls.static = ext_static
  cls.add = ext_add
  cls.new = ext_new
  return cls
end

-- ========== class 函数 ==========

---创建一个新类
---@param super table|nil 父类（可选）
---@param default_args table|function|nil 默认构造参数（无参实例化时自动传入）
---@return table 新创建的类
local function class(super, default_args)
  local cls = {}
  local vtb = {}
  _class_vtb[cls] = vtb

  setmetatable(cls, {
    __index = function(t, k) return vtb[k] or (super and super[k]) end,
    __newindex = function(t, k, v) vtb[k] = v end,
    __call = function(t, ...) return t.new(t, ...) end,
  })

  vtb._final = vtb._final or {}
  vtb._abstract = vtb._abstract or {}
  cls._chain_methods = {}

  if super then
    local super_vtb = _class_vtb[super]
    if not super_vtb then error("父类不是由 class 创建的") end
    if _final_class[super] then error("不能继承 final 类") end

    setmetatable(vtb, {
      __index = function(t, k)
        local ret = super_vtb[k]
        if ret ~= nil then rawset(t, k, ret) end
        return ret
      end,
      __newindex = function(t, k, v)
        -- 向上遍历所有父类的 _final 表，检查该方法是否被标记为 final
        local cur = super
        while cur do
          local cur_vtb = _class_vtb[cur]
          if cur_vtb and cur_vtb._final and cur_vtb._final[k] then
            error(string.format("方法 '%s' 是祖先类 final 方法，不可重写", k))
          end
          cur = cur.super
        end
        rawset(t, k, v)
      end
    })

    cls.super = super
    cls._default_args = default_args

    if super._chain_methods then
      for k, v in pairs(super._chain_methods) do
        cls._chain_methods[k] = v
      end
    end
   else
    cls._default_args = default_args
  end

  inject_extensions(cls)
  return cls
end

return class