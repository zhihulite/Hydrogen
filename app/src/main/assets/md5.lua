-- md5.lua
-- MD5 摘要（zse96 签名使用）

local MessageDigest = luajava.bindClass("java.security.MessageDigest")
local String = luajava.bindClass("java.lang.String")

local function md5(data)
  local md = MessageDigest.getInstance("MD5")
  local bytes = md.digest(String(data).bytes)
  local result = {}
  for i = 1, #bytes do
    result[i] = string.format("%02x", string.byte(bytes, i))
  end
  return table.concat(result)
end

return md5
