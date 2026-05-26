-- helpers/ui.lua
-- ui工具类

local M = {}

import "android.widget.Toast"
import "android.view.Gravity"
import "com.google.android.material.card.MaterialCardView"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "android.content.ClipboardManager"
import "android.content.Context"
import "android.content.Intent"
import "android.net.Uri"
import "android.view.MenuItem"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"
import "androidx.appcompat.widget.AppCompatEditText"
import "java.io.FileOutputStream"

local lastToast = nil

function M.dp2px(dp)
  return dp * activity.resources.displayMetrics.density + 0.5
end

function M.sp2px(sp)
  return sp * activity.resources.displayMetrics.scaledDensity + 0.5
end

function M.px2dp(px)
  return px / activity.resources.displayMetrics.density
end

function M.px2sp(px)
  return px / activity.resources.displayMetrics.scaledDensity
end

function M.screenWidth()
  return activity.resources.displayMetrics.widthPixels
end

function M.screenHeight()
  return activity.resources.displayMetrics.heightPixels
end


-- Toast
function M.tip(msg, long)
  if lastToast then lastToast.cancel() end

  local duration = long and Toast.LENGTH_LONG or Toast.LENGTH_SHORT
  local colors = AppTheme.colors

  local layout = {
    LinearLayoutCompat,
    layout_width = "wrap",
    layout_height = "wrap",
    {
      MaterialCardView,
      layout_width = "wrap",
      layout_height = "wrap",
      layout_margin = "16dp",
      layout_marginBottom = "64dp",
      cardElevation = 0,
      cardBackgroundColor = colors.surface,
      strokeWidth = 0,
      radius = "8dp",
      {
        LinearLayoutCompat,
        layout_width = "wrap",
        layout_height = "wrap",
        orientation = "horizontal",
        gravity = "center",
        paddingLeft = "20dp",
        paddingRight = "20dp",
        paddingTop = "12dp",
        paddingBottom = "12dp",
        {
          MaterialTextView,
          layout_width = "wrap",
          layout_height = "wrap",
          text = msg,
          textColor = colors.onSurface,
          textSize = "14sp",
          typeface = Fonts.regular,
        }
      }
    }
  }

  lastToast = Toast.makeText(activity, msg, duration)
  lastToast.setGravity(Gravity.BOTTOM, 0, 0)
  lastToast.view = loadlayout(layout)
  lastToast.show()
end

-- 复制到剪贴板
function M.copyText(text)
  local cm = activity.getSystemService(Context.CLIPBOARD_SERVICE)
  local clip = luajava.newInstance("android.content.ClipData", text, {"text/plain"}, luajava.newInstance("android.content.ClipData$Item", text))
  cm.primaryClip = clip
  M.tip("已复制")
end

-- 分享文本
function M.shareText(text, title)
  local intent = Intent(Intent.ACTION_SEND)
  intent.type = "text/plain"
  intent.putExtra(Intent.EXTRA_TEXT, text)
  if title then intent.putExtra(Intent.EXTRA_SUBJECT, title) end
  activity.startActivity(Intent.createChooser(intent, title or "分享"))
end

-- 打开链接
function M.openUrl(url)
  local success, err = pcall(function()
    local intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    activity.startActivity(intent)
  end)

  if not success then
    tip("未找到可打开的应用")
  end
end

--- 分享文件，返回删除函数
--- @param filePath string 文件路径
--- @param text string|nil 附加文本
--- @param mimeType string|nil MIME 类型，默认 "image/*"
--- @param onError function|nil 错误回调
--- @return function 删除函数
function M.shareFile(filePath, text, mimeType, onError)
  if not filePath or not Extensions.File.exists(filePath) then
    if onError then onError("文件不存在") else tip("文件不存在") end
    return function() end
  end

  local file = File(filePath)
  local uri = FileProvider.getUriForFile(activity, activity.packageName .. ".FileProvider", file)

  local intent = Intent(Intent.ACTION_SEND)
  intent.type = mimeType or "application/octet-stream"
  intent.putExtra(Intent.EXTRA_STREAM, uri)
  intent.Flags = Intent.FLAG_GRANT_READ_URI_PERMISSION

  if text and text ~= "" then
    intent.putExtra(Intent.EXTRA_TEXT, text)
  end

  activity.startActivity(Intent.createChooser(intent, "分享"))

  return function()
    if Extensions.File.exists(filePath) then
      Extensions.File.delete(filePath)
    end
  end
end

--- 分享 Bitmap 图片
--- @param bitmap Bitmap
--- @param fileName string|nil 文件名
--- @param text string|nil 附加文本
--- @param onError function|nil 错误回调
--- @return function 删除函数
function M.shareBitmap(bitmap, fileName, text, onError)
  if not bitmap then
    if onError then onError("图片无效") end
    return function() end
  end
  local tempDir = M.prepareShareTempDir()
  local file = File(tempDir, fileName or ("share_" .. os.time() .. ".jpg"))
  local fos = FileOutputStream(file)
  bitmap.compress(Bitmap.CompressFormat.JPEG, 95, fos)
  fos.flush()
  fos.close()
  return M.shareFile(file.absolutePath, text, "image/jpeg", onError)
end

--- 分享字节数据（支持 gif/png/jpg 等）
--- @param bytes any Java byte[] 字节数组
--- @param fileName string|nil 文件名（必须带扩展名）
--- @param mimeType string|nil MIME 类型，默认从文件名推断
--- @param text string|nil 附加文本
--- @param onError function|nil 错误回调
--- @return function 删除函数
function M.shareBytes(bytes, fileName, mimeType, text, onError)
  if not bytes then
    if onError then onError("数据无效") end
    return function() end
  end

  fileName = fileName or ("share_" .. os.time())

  local _filename, _mimeType = Extensions.File.getFileNameAndType(fileName)
  mimeType = mimeType or _mimeType or "application/octet-stream"

  local tempDir = M.prepareShareTempDir()
  local file = File(tempDir, fileName)
  local fos = FileOutputStream(file)
  fos.write(bytes)
  fos.flush()
  fos.close()

  return M.shareFile(file.absolutePath, text, mimeType, onError)
end

--- 准备分享临时目录（每次调用会先清理旧目录）
--- @return string 临时目录路径
function M.prepareShareTempDir()
  local tempDir = activity.externalCacheDir.toString() .. "/share_temp"
  if Extensions.File.exists(tempDir) then
    Extensions.File.delete(tempDir)
  end
  Extensions.File.mkdir(tempDir)
  return tempDir
end

function M.setupSwipeRefresh(sr, onRefresh)
  if not sr then return end
  local colors = AppTheme.colors
  sr.progressBackgroundColorSchemeColor = colors.background
  sr.colorSchemeColors = {colors.primary}

  if onRefresh then
    sr.onRefresh = onRefresh
  end
end

function M.setupToolbar(toolbar, options)
  if not toolbar then return end
  options = options or {}

  local colors = AppTheme.colors
  toolbar.titleTextColor = colors.primary

  if options.title then
    toolbar.title = options.title
  end

  local navIcon = options.navIcon or Helpers.Static.materialDrawable("twotone_arrow_back", 24)
  toolbar.navigationIcon = navIcon
  if navIcon then navIcon.tint = colors.primary end

  local navCallback = options.navCallback or function() Router.back() end
  toolbar.navigationOnClickListener = { onClick = navCallback }

  local overflowIcon = toolbar.overflowIcon
  if overflowIcon then overflowIcon.tint = colors.primary end

  local menuItems = options.menu or {}
  local menuIdMap = {}

  if Extensions.Config.getBool(Constants.SharedDataKeys.ALLOW_LOAD_CODE) then
    table.insert(menuItems, {
      id = "debug_code",
      title = "执行代码",
      asAction = "never",
      click = function()
        local views = {}
        local dialog = MaterialAlertDialogBuilder(activity)
        .setTitle("执行代码")
        .setView(loadlayout({
          LinearLayoutCompat, orientation = "vertical", padding = "16dp",
          { AppCompatEditText, id = "edit", layout_width = "match_parent", gravity = "top", typeface = Typeface.MONOSPACE }
        }, views))
        .setPositiveButton("确定", nil)
        .setNegativeButton("取消", nil)
        .show()
        local edit = views.edit
        dialog.getButton(dialog.BUTTON_POSITIVE).onClick = function()
          if not edit then return end
          local code = edit.text
          if code == "" then tip("请输入代码") return end
          pcall(load(code))
        end
      end
    })
  end

  if #menuItems > 0 then
    toolbar.menu.clear()
    menuIdMap = loadmenu(toolbar.menu, menuItems)
  end

  return menuIdMap
end

function M.clearAppCache()
  import "java.io.File"
  import "androidx.core.content.ContextCompat"

  local dataDir = tostring(ContextCompat.getDataDir(activity))
  local imageTmp = tostring(activity.externalCacheDir) .. "/images"
  local totalSize = 0

  local function countAndDelete(path)
    local file = File(path)
    if file.isDirectory() and file.canWrite() then
      local files = file.listFiles()
      if files then
        for _, f in ipairs(luajava.astable(files)) do
          if f.isDirectory() then
            countAndDelete(tostring(f))
           else
            totalSize = totalSize + f.length()
          end
        end
      end
      file.delete()
    end
  end

  -- 清理内部缓存
  countAndDelete(dataDir .. "/cache")
  -- 清理外部图片缓存
  countAndDelete(imageTmp)
  -- 清理崩溃日志
  countAndDelete(dataDir .. "/files/crash")

  -- 清除图片内存缓存
  Helpers.Image.clearMemory()

  if totalSize == 0 then
    return nil
  end

  local mb = totalSize / 1024 / 1024
  return string.format("已清理缓存，释放 %.2f MB", mb)
end

--- 跳转图片查看器（多图）
--- @param imageUrls table 图片 URL 列表
--- @param currentIndex number 当前显示的图片索引（从 0 开始）
function M.showImageViewer(imageUrls, currentIndex)
  if not imageUrls or #imageUrls == 0 then
    tip("没有可显示的图片")
    return
  end
  activity.setSharedData("imagedata", json.encode(imageUrls))
  activity.setSharedData("imageindex", tostring(currentIndex or 0))
  Router.go("image")
end

--- 跳转图片查看器（单图）
--- @param imageUrl string 图片 URL
function M.showImage(imageUrl)
  if not imageUrl or imageUrl == "" then
    tip("没有可显示的图片")
    return
  end
  M.showImageViewer({ imageUrl }, 0)
end

import "android.os.Handler"
import "java.lang.Runnable"
local handler=Handler()
---节流，delay 毫秒内只运行一次，若在 delay 毫秒内重复触发，只有一次生效
---@param func function 事件
---@param delay number 延迟
---@return function runnable 节流运行
function M.throttle(func,delay)
  local args={}
  local runnable=Runnable({run=function()
      func(table.unpack(args,1,args.length))
  end})
  return function(...)
    if handler.hasCallbacks(runnable) then
      return
    end
    args=table.pack(...)
    handler.postDelayed(runnable,delay)
  end
end

---防抖，delay 毫秒后在执行该事件，若在 delay 毫秒内被重复触发，则重新计时
---@param func function 事件
---@param delay number 延迟
---@return function runnable 防抖运行
function M.debounce(func,delay)
  local args={}
  local runnable=Runnable({run=function()
      func(table.unpack(args,1,args.length))
  end})
  return function(...)
    if handler.hasCallbacks(runnable) then
      handler.removeCallbacks(runnable)
    end
    args=table.pack(...)
    handler.postDelayed(runnable,delay)
  end
end

--- 创建固定行为的 Java 代理对象
--- 
--- 修复 luajava.createProxy 的以下问题：
--- 1. 每次创建代理对象的 equals/hashCode 行为不一致
--- 2. 无法在集合（如 HashSet、HashMap）中正确去重
--- 3. 代理对象之间无法正确比较相等性
---
--- @param interfaceName string 接口类名
--- @param methods table 方法实现表
--- @return userdata 具有稳定 equals/hashCode 的 Java 代理对象
function M.createFixedProxy(interfaceName, methods)
  local proxy = nil
  local uniqueId = math.random(1, 99999999) .. "_" .. os.time()
  local m = {}
  for k, v in pairs(methods) do m[k] = v end
  m.equals = function(other) return tostring(proxy) == tostring(other) end
  m.hashCode = function() return tonumber(uniqueId:match("%d+")) or 12345 end
  m.toString = function() return "FixedProxy@" .. uniqueId end
  proxy = luajava.createProxy(interfaceName, m)
  return proxy
end

return M