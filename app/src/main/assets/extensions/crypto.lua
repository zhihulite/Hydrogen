-- extensions/crypto.lua
-- crypto 模块
local M = {}

local md5 = require("libs.md5")
local base64 = require("libs.base64")

--- MD5 摘要（小写 32 位十六进制）
--- @param data any Lua 字符串或 Java byte[]（userdata）
--- @return string
function M.md5(data)
  return md5(data)
end

-- Base64编码
function M.base64Encode(str)
  return base64.encode(str)
end

-- Base64解码
function M.base64Decode(str)
  return base64.decode(str)
end

-- 简单异或加密
function M.xorEncrypt(str, key)
  local result = {}
  key = key or "Hydrogen"
  for i = 1, #str do
    local sc = string.byte(str, i)
    local kc = string.byte(key, ((i - 1) % #key) + 1)
    table.insert(result, string.char(sc ~ kc))
  end
  return table.concat(result)
end

-- 异或解密（同加密）
M.xorDecrypt = M.xorEncrypt

-- 生成随机字符串
function M.randomStr(length)
  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  local result = {}
  for i = 1, length do
    local idx = math.random(1, #chars)
    table.insert(result, chars:sub(idx, idx))
  end
  return table.concat(result)
end

return M