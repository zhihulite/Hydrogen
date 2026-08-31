-- libs/md5.lua
-- MD5 摘要

local LuaUtil = luajava.bindClass("org.luajvm.android.util.LuaUtil")

--- @param data any Lua 字符串（字节串）或 Java byte[]（userdata），直传 Java byte[] 形参
--- @return string 小写 32 位十六进制
local function md5(data)
  return LuaUtil.md5(data)
end

return md5