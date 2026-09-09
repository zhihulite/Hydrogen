-- extensions/stdlib_ext.lua
-- 标准库扩展：require 即自动挂到 table 全局

local M = {}

--- 合并两个表（浅合并，t2 覆盖 t1 同名键）
--- @param t1 table|nil
--- @param t2 table|nil
--- @return table 合并结果（新表）
function M.merge(t1, t2)
  local result = {}
  if t1 then
    for k, v in pairs(t1) do result[k] = v end
  end
  if t2 then
    for k, v in pairs(t2) do result[k] = v end
  end
  return result
end

--- 深克隆表
--- @param t table
--- @return table 克隆结果（嵌套表递归复制）
function M.clone(t)
  local result = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      result[k] = M.clone(v)
     else
      result[k] = v
    end
  end
  return result
end

--- 统计键数量
--- @param t table
--- @return number
function M.size(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

local DUMP_INF = math.huge

local function fmtValue(v)
  local ty = type(v)
  if ty == "string" then return string.format("%q", v)
  elseif ty == "number" or ty == "boolean" then return tostring(v)
  elseif ty == "nil" then return "nil"
  else return tostring(v)
  end
end

--- 单行内联 dump（深度截断时用），循环引用标 <cycle>
--- @param t table
--- @param seen table|nil 已访问表集合
--- @return string
function M.inline(t, seen)
  seen = seen or {}
  if seen[t] then return "<cycle>" end
  seen[t] = true

  local parts = {}
  local n = #t
  for i = 1, n do
    local v = t[i]
    parts[#parts + 1] = type(v) == "table" and M.inline(v, seen) or fmtValue(v)
  end
  local keys = {}
  for k, v in pairs(t) do
    if type(k) ~= "number" or k > n or k < 1 or k % 1 ~= 0 then
      local ks = type(k) == "number" and ("[" .. k .. "]") or tostring(k)
      local vs = type(v) == "table" and M.inline(v, seen) or fmtValue(v)
      keys[#keys + 1] = ks .. " = " .. vs
    end
  end
  table.sort(keys)
  local all = {}
  for i = 1, #parts do all[#all + 1] = "[" .. i .. "] = " .. parts[i] end
  for i = 1, #keys do all[#all + 1] = keys[i] end
  return "{" .. table.concat(all, ", ") .. "}"
end

--- 递归打印表结构：数组部分按序，其余键数字优先、字符串次之
--- @param t table 目标表
--- @param maxDepth number|nil 深度上限（超出单行内联全量展开），默认不限
--- @param label string|nil 输出前缀
--- @return string 同时 print 到日志
function M.dump(t, maxDepth, label)
  maxDepth = (maxDepth == nil or maxDepth < 0) and DUMP_INF or maxDepth

  local lines = {}
  local seen = {}

  local function keyStr(k)
    if type(k) == "number" then return "[" .. k .. "]"
    elseif type(k) == "string" then return k
    else return "[" .. tostring(k) .. "]"
    end
  end

  local function dumpTable(t, depth, prefix)
    if seen[t] then
      lines[#lines + 1] = prefix .. "<cycle>"
      return
    end
    seen[t] = true

    -- 数组部分：按序（布局表子节点的真实顺序）
    local n = #t
    for i = 1, n do
      local v = t[i]
      if type(v) == "table" then
        if depth >= maxDepth then
          lines[#lines + 1] = string.format("%s[%d] = %s", prefix, i, M.inline(v, seen))
         else
          lines[#lines + 1] = string.format("%s[%d] = {", prefix, i)
          dumpTable(v, depth + 1, prefix .. "  ")
        end
       else
        lines[#lines + 1] = string.format("%s[%d] = %s", prefix, i, fmtValue(v))
      end
    end

    -- 哈希部分：数字键先（按值排序），字符串键后（按字典序）
    local hashNum, hashStr = {}, {}
    for k, v in pairs(t) do
      if type(k) ~= "number" or k > n or k < 1 or k % 1 ~= 0 then
        if type(k) == "number" then hashNum[#hashNum + 1] = k
        else hashStr[#hashStr + 1] = k end
      end
    end
    table.sort(hashNum)
    table.sort(hashStr)

    local function dumpKV(k, v)
      if type(v) == "table" then
        if depth >= maxDepth then
          lines[#lines + 1] = string.format("%s%s = %s", prefix, keyStr(k), M.inline(v, seen))
         else
          lines[#lines + 1] = string.format("%s%s = {", prefix, keyStr(k))
          dumpTable(v, depth + 1, prefix .. "  ")
        end
       else
        lines[#lines + 1] = string.format("%s%s = %s", prefix, keyStr(k), fmtValue(v))
      end
    end
    for _, k in ipairs(hashNum) do dumpKV(k, t[k]) end
    for _, k in ipairs(hashStr) do dumpKV(k, t[k]) end
  end

  local out
  if type(t) == "table" then
    lines[#lines + 1] = (label or "table") .. " = {"
    dumpTable(t, 1, "  ")
    lines[#lines + 1] = "}"
    out = table.concat(lines, "\n")
   else
    out = (label or "value") .. " = " .. fmtValue(t)
  end
  print(out)
  return out
end

-- require 即自动挂到 table 全局
table.merge = M.merge
table.clone = M.clone
table.size = M.size
table.dump = M.dump

return M
