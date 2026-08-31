-- helpers/static.lua
-- 静态目录获取

local M = {}

local ROOT = _G.ROOT
local STATIC_DIR = ROOT .. "/static/"

M.ICON_DIR = STATIC_DIR .. "/icons/"
M.FONT_DIR = STATIC_DIR .. "/fonts/"
M.IMAGE_DIR = STATIC_DIR .. "/images/"
M.JS_DIR = STATIC_DIR .. "/js/"
M.ZEMOJI_DIR = STATIC_DIR .. "/zemoji/"

local cache = {}

-- 缩放后 Bitmap 缓存，键为 目录+名称+像素尺寸
-- Drawable 实例持有 tint/bounds 状态且各调用方独立修改，因此只缓存 Bitmap、Drawable 每次新建
local scaledCache = {}

import "android.graphics.Typeface"
import "android.graphics.drawable.BitmapDrawable"
import "android.graphics.Bitmap"
import "java.io.File"

local function fileExists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

-- 内部通用函数：获取路径（支持多种扩展名）
local function getPathWithExts(dir, name, exts)
  for _, ext in ipairs(exts) do
    local path = dir .. name .. ext
    if fileExists(path) then
      return path
    end
  end
  return nil
end

-- 内部通用函数：获取路径（默认 .png）
local function getPath(dir, name)
  return getPathWithExts(dir, name, {".png"})
end

-- 内部通用函数：获取 Bitmap
-- 缓存键带目录前缀并以 false 记录缺失名，避免跨目录同名撞图与重复探测文件系统
local function getBitmap(dir, name, useExts)
  local key = dir .. name
  local hit = cache[key]
  if hit ~= nil then
    return hit or nil
  end
  local path
  if useExts then
    path = getPathWithExts(dir, name, useExts)
   else
    path = getPath(dir, name)
  end
  if path then
    cache[key] = loadbitmap(path) or false
    return cache[key] or nil
  end
  print("静态资源不存在: " .. dir .. name)
  cache[key] = false
  return nil
end

-- 内部通用函数：获取 Drawable
-- raw: true=原始颜色（不着色），false/nil=使用主题primary色
local function getDrawableFromDir(dir, name, sizeDp, raw, useExts)
  local bitmap = getBitmap(dir, name, useExts)
  if not bitmap then
    return nil
  end
  local sizePx = dp2px(sizeDp)
  local scaledKey = dir .. name .. "@" .. sizePx
  local scaledBitmap = scaledCache[scaledKey]
  if not scaledBitmap then
    scaledBitmap = Bitmap.createScaledBitmap(bitmap, sizePx, sizePx, true)
    scaledCache[scaledKey] = scaledBitmap
  end
  local drawable = BitmapDrawable(activity.resources, scaledBitmap)

  drawable.setBounds(0, 0, sizePx, sizePx)
  if not raw then
    local colors = AppTheme.colors
    drawable.tint = colors.primary
  end
  return drawable
end

-- ============================================
-- 对外 API
-- ============================================

-- Icon
function M.iconPath(name)
  return getPath(M.ICON_DIR, name)
end

function M.icon(name)
  return getBitmap(M.ICON_DIR, name)
end

function M.iconDrawable(name, sizeDp, raw)
  return getDrawableFromDir(M.ICON_DIR, name, sizeDp, raw)
end

-- Material Icon
function M.materialIconPath(name)
  return getPath(M.ICON_DIR, name .. "_black_24")
end

function M.materialIcon(name)
  return getBitmap(M.ICON_DIR, name .. "_black_24")
end

function M.materialDrawable(name, sizeDp, raw)
  return getDrawableFromDir(M.ICON_DIR, name .. "_black_24", sizeDp, raw)
end

-- Zemoji
function M.zemojiPath(name)
  return getPath(M.ZEMOJI_DIR, name)
end

function M.zemoji(name)
  return getBitmap(M.ZEMOJI_DIR, name)
end

function M.zemojiDrawable(name, sizeDp, raw)
  return getDrawableFromDir(M.ZEMOJI_DIR, name, sizeDp, raw)
end

--- 获取所有 zemoji 文件名列表（不含扩展名）
function M.zemojiList()
  local list = {}
  local dir = File(M.ZEMOJI_DIR)
  if dir.exists() and dir.isDirectory() then
    local files = luajava.astable(dir.listFiles() or {})
    for _, f in ipairs(files) do
      local name = f.name
      local baseName = name:match("(.+)%..+$")
      if baseName then
        table.insert(list, baseName)
      end
    end
  end
  return list
end

-- Image（支持多种图片格式）
local IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".gif"}

function M.imagePath(name)
  return getPathWithExts(M.IMAGE_DIR, name, IMAGE_EXTS)
end

function M.image(name)
  return getBitmap(M.IMAGE_DIR, name, IMAGE_EXTS)
end

function M.imageDrawable(name, sizeDp, raw)
  return getDrawableFromDir(M.IMAGE_DIR, name, sizeDp, raw, IMAGE_EXTS)
end

-- Font
function M.fontPath(name)
  local path = M.FONT_DIR .. name .. ".ttf"
  if fileExists(path) then
    return path
  end
  return nil
end

function M.font(name)
  local path = M.fontPath(name)
  if path then
    return Typeface.createFromFile(File(path))
  end
  return nil
end

-- JS
function M.getJSContent(jsName)
  local path = M.JS_DIR .. jsName .. ".js"
  return Extensions.File.read(path)
end

return M