-- helpers/ui.lua
-- ui工具类

local M = {}

import "android.widget.Toast"
import "android.view.Gravity"
import "android.view.View"
import "android.graphics.Bitmap"
import "android.graphics.Typeface"
import "com.google.android.material.card.MaterialCardView"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "androidx.appcompat.widget.AppCompatEditText"
import "androidx.core.content.FileProvider"
import "androidx.core.content.ContextCompat"
import "android.content.Context"
import "android.content.Intent"
import "android.net.Uri"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"
import "java.io.File"
import "java.io.FileOutputStream"
import "java.lang.Runnable"
import "android.os.Handler"
import "android.os.Looper"

local ClipData = luajava.bindClass("android.content.ClipData")
local ClipDataItem = luajava.bindClass("android.content.ClipData$Item")

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

--- 判断 View 的 Java 引用是否仍然有效
--- luajava.clear 只把 userdata 的 Java 载荷置空，Lua 侧仍是 userdata 且为真值，
--- instanceof 在载荷为空时返回 false；非 userdata 一律视为无效
--- @param view any 待检查的值
--- @return boolean 引用有效返回 true
function M.isViewAlive(view)
  if type(view) ~= "userdata" then return false end
  return luajava.instanceof(view, View)
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
  local clip = ClipData(text, {"text/plain"}, ClipDataItem(text))
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
  -- 构造 FileOutputStream 也可能失败（目录创建失败/磁盘满），一并纳入 pcall
  local okFos, fos = pcall(FileOutputStream, file)
  if not okFos then
    if onError then onError("图片保存失败") end
    return function() end
  end
  local success = pcall(function()
    bitmap.compress(Bitmap.CompressFormat.JPEG, 95, fos)
    fos.flush()
  end)
  pcall(function() fos.close() end)
  if not success then
    if onError then onError("图片保存失败") end
    return function() end
  end
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
  mimeType = mimeType or "application/octet-stream"

  local tempDir = M.prepareShareTempDir()
  local file = File(tempDir, fileName)
  -- 构造 FileOutputStream 也可能失败（目录创建失败/磁盘满），一并纳入 pcall
  local okFos, fos = pcall(FileOutputStream, file)
  if not okFos then
    if onError then onError("数据写入失败") end
    return function() end
  end
  local success = pcall(function()
    fos.write(bytes)
    fos.flush()
  end)
  pcall(function() fos.close() end)
  if not success then
    if onError then onError("数据写入失败") end
    return function() end
  end

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
  toolbar.navigationOnClickListener = luajava.createProxy(View.OnClickListener, { onClick = navCallback })

  local overflowIcon = toolbar.overflowIcon
  if overflowIcon then overflowIcon.tint = colors.primary end

  -- 浅拷贝菜单表：追加调试项时不能污染调用方传入的表
  local menuItems = {}
  for _, it in ipairs(options.menu or {}) do
    menuItems[#menuItems + 1] = it
  end
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
          local fn, syntaxErr = load(code)
          if not fn then
            tip("语法错误: " .. tostring(syntaxErr))
            return
          end
          local ok, err = pcall(fn)
          if not ok then
            tip("运行错误: " .. tostring(err))
          end
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

-- 缓存清理的实现体：在调用方的线程上同步执行，返回提示文案或 nil
local function clearAppCacheImpl()
  local dataDir = ContextCompat.getDataDir(activity).toString()
  local imageTmp = activity.externalCacheDir.toString() .. "/images"
  local totalSize = 0

  local function countAndDelete(path)
    local file = File(path)
    if not file.exists() or not file.canWrite() then return end
    if file.isDirectory() then
      local files = file.listFiles()
      if files then
        for _, f in ipairs(luajava.astable(files)) do
          countAndDelete(f.toString())
        end
      end
      -- 目录只有清空后才删得掉
      file.delete()
     else
      totalSize = totalSize + file.length()
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

--- 后台线程清理缓存，完成后主线程提示。
--- 三棵目录树（Glide 磁盘缓存/外部图片/崩溃日志）可能数千文件，
--- 同步删除会阻塞主线程数秒，必须移出调用方线程
function M.clearAppCache()
  task(function()
    return clearAppCacheImpl()
    end, function(msg)
    if msg then tip(msg) end
  end)
end

-- 防抖节流主 handle
local mainHandler = Handler(Looper.getMainLooper())
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
    if mainHandler.hasCallbacks(runnable) then
      return
    end
    args=table.pack(...)
    mainHandler.postDelayed(runnable,delay)
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
    if mainHandler.hasCallbacks(runnable) then
      mainHandler.removeCallbacks(runnable)
    end
    args=table.pack(...)
    mainHandler.postDelayed(runnable,delay)
  end
end

-- 通用主 handle
---在 UI 线程延迟执行（替代繁重的 task 函数，避免创建线程和子状态机）
---@param delay number 延迟时间（毫秒），可选，默认为 0
---@param func function 需要执行的函数
function M.runDelayed(delay, func)
  if type(delay) == "function" then
    func = delay
    delay = 0
  end
  if delay == 0 then
    mainHandler.post(Runnable{run=func})
   else
    mainHandler.postDelayed(Runnable{run=func}, delay)
  end
end

---数值格式化为带单位的中文短文本
---@param num number 数值，可为 nil
---@return string 格式化结果
function M.formatNumber(num)
  if not num then return "0" end
  if num >= 100000000 then return string.format("%.1f亿", num / 100000000) end
  if num >= 10000 then return string.format("%.1f万", num / 10000) end
  return tostring(num)
end

---格式化时间戳为友好显示（支持秒/毫秒时间戳）
---@param timestamp number|nil 时间戳（秒或毫秒）
---@return string|nil 友好时间字符串（刚刚/X 分钟前/X 小时前/MM-dd/YYYY-MM-DD），入参为 nil 时返回 nil
function M.formatTime(timestamp)
  if not timestamp then
    return nil
  end

  -- 秒级时间戳不会超过 1e11，超过即为毫秒
  if timestamp > 1e11 then
    timestamp = timestamp // 1000
  end

  local now = os.time() -- 当前时间（秒）
  local diff = now - timestamp -- 时间差（秒）

  -- 1小时内：显示分钟数
  if diff < 3600 then
    local minutes = math.floor(diff / 60 + 0.5) -- 四舍五入
    if minutes <= 0 then
      return "刚刚"
    end
    return minutes .. " 分钟前"

    -- 24小时内：显示小时数
   elseif diff < 86400 then
    local hours = math.floor(diff / 3600 + 0.5)
    return hours .. " 小时前"

    -- 今年内：显示月-日
   elseif tonumber(os.date("%Y", now)) == tonumber(os.date("%Y", timestamp)) then
    return os.date("%m-%d", timestamp)

    -- 跨年：显示年-月-日
   else
    return os.date("%Y-%m-%d", timestamp)
  end
end

return M