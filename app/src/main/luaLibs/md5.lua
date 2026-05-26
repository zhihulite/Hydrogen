local MessageDigest = luajava.bindClass("java.security.MessageDigest")
local String = luajava.bindClass("java.lang.String")

local function md5(data)
  local md = MessageDigest.getInstance("MD5")
  local bytes = md.digest(String(data).bytes)
  local result = {}
  for i = 0, #bytes - 1 do
    result[i+1] = string.format("%02x", bytes[i] & 0xff)
  end
  return table.concat(result)
end

return md5