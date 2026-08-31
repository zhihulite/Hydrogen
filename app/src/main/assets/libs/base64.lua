-- libs/base64.lua
-- Base64 编解码

local base64 = {}

local Base64 = luajava.bindClass("android.util.Base64")
local String = luajava.bindClass("java.lang.String")

--- 编码：任意字节（Lua 字符串即字节串，直传 byte[] 形参）
--- @param data string 字节串
--- @return string base64 文本
function base64.encode(data)
  return tostring(Base64.encodeToString(data, Base64.NO_WRAP))
end

--- 解码为文本（结果按 UTF-8 解读）
--- @param text string base64 文本
--- @return string 文本内容
function base64.decode(text)
  return tostring(String(Base64.decode(text, Base64.DEFAULT), "UTF-8"))
end

return base64