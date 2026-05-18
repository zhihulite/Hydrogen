local context = activity or service

local LuaBitmap = luajava.bindClass "com.androlua.LuaBitmap"

local HTTP_PATTERN = "^https*://" -- 匹配 http:// 或 https://
local EXTENSION_PATTERN = "%.%a%a%a%a?$" -- 匹配扩展名如 .png .jpg .jpeg

--- 加载图片
---@param path string 图片路径（支持本地路径、网络URL、或文件名）
---@return Bitmap
local function loadbitmap(path)
  -- 网络图片
  if path:find(HTTP_PATTERN) then
    return LuaBitmap.getHttpBitmap(context, path)
  end

  -- 自动补全 .png 扩展名
  if not path:find(EXTENSION_PATTERN) then
    path = path .. ".png"
  end

  -- 本地图片（绝对路径或相对路径）
  local isAbsolute = path:find("^/")
  local fullPath = isAbsolute and path or string.format("%s/%s", luajava.luadir, path)

  return LuaBitmap.getLocalBitmap(context, fullPath)
end

return loadbitmap