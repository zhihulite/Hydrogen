-- helpers/image.lua
-- 图片加载

local M = {}

local Glide = luajava.bindClass("com.bumptech.glide.Glide")
local RequestOptions = luajava.bindClass("com.bumptech.glide.request.RequestOptions")

local srcLuaDir = luajava.luadir

-- 加载图片
function M.load(view, url, options)
  if not view or not url then return end

  local request = Glide.with(activity).load(url)

  if options then
    if options.placeholder then
      request = request.placeholder(options.placeholder)
    end
    if options.error then
      request = request.error(options.error)
    end
    if options.circle then
      request = request.circleCrop()
    end
    if options.size then
      request = request.override(options.size.width, options.size.height)
    end
    if options.centerCrop then
      request = request.centerCrop()
    end
  end

  request.into(view)
end

-- 加载圆形图片
function M.loadCircle(view, url)
  M.load(view, url, { circle = true })
end

-- 获取图标路径
function M.getIcon(name)
  return srcLuaDir .. "/res/icons/twotone_" .. name .. "_black_24dp.png"
end

-- 获取表情路径
function M.getEmoji(name)
  local cacheDir = activity.externalCacheDir.toString()
  return cacheDir .. "/zemoji/" .. name .. ".png"
end

-- 清除内存缓存
function M.clearMemory()
  Glide.get(activity).clearMemory()
end

-- 清除磁盘缓存（异步）
function M.clearDisk()
  task(function()
    Glide.get(activity).clearDiskCache()
  end)
end

return M