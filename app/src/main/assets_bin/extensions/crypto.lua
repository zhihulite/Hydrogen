-- extensions/crypto.lua
local M = {}

local md5 = require("md5")
local base64 = require("base64")

-- MD5加密
function M.md5(str)
  return md5(str)
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
    table.insert(result, string.char(bit32.bxor(sc, kc)))
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