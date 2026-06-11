-- helpers/image.lua
-- 图片加载

local M = {}

local Glide = luajava.bindClass("com.bumptech.glide.Glide")
local srcLuaDir = luajava.luadir

-- 加载图片
function M.load(view, url, options)
  if not view or not url then return end
  local noImage = Extensions.Config.getBool(Constants.SharedDataKeys.NO_IMAGE)

  -- 无图模式：只显示占位图，不加载网络图片
  if noImage then
    -- 获取占位图：优先使用 options 中的，否则使用默认
    local placeholder = options and options.placeholder or Helpers.Static.image("logo")
    -- 使用 Glide 加载本地占位图（不会发起网络请求）
    Glide.with(activity)
    .load(placeholder)
    .into(view)
    return
  end

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

-- 清除内存缓存
function M.clearMemory()
  Glide.get(activity).clearMemory()
end

-- 清除磁盘缓存（异步）
function M.clearDisk()
  Helpers.UI.runDelayedOnBackground(function()
    Glide.get(activity).clearDiskCache()
  end)
end

return M