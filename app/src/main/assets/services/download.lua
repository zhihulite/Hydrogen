-- services/download.lua
-- 网络下载相关

local M = {}

local File = luajava.bindClass("java.io.File")
local Environment = luajava.bindClass("android.os.Environment")
local DownloadManager = luajava.bindClass("android.app.DownloadManager")
local Uri = luajava.bindClass("android.net.Uri")
local URLUtil = luajava.bindClass("android.webkit.URLUtil")
local Context = luajava.bindClass("android.content.Context")
local Base64 = luajava.bindClass("android.util.Base64")
local Build = luajava.bindClass("android.os.Build")

local MIME_TO_EXT = {
  ["image/jpeg"] = "jpg", ["image/png"] = "png", ["image/gif"] = "gif",
  ["image/webp"] = "webp", ["image/svg+xml"] = "svg", ["image/bmp"] = "bmp",
  ["video/mp4"] = "mp4", ["video/webm"] = "webm",
  ["audio/mpeg"] = "mp3", ["audio/wav"] = "wav",
  ["application/pdf"] = "pdf", ["application/zip"] = "zip",
  ["application/json"] = "json", ["text/plain"] = "txt",
  ["text/html"] = "html", ["text/css"] = "css", ["text/javascript"] = "js",
}

-- 反表由正表翻转生成，jpeg 是唯一的别名条目
local EXT_TO_MIME = {}
for mime, ext in pairs(MIME_TO_EXT) do
  EXT_TO_MIME[ext] = mime
end
EXT_TO_MIME.jpeg = "image/jpeg"

--- MIME → 扩展名
local function MIMEtoEXT(mimeType)
  return MIME_TO_EXT[mimeType]
end

--- 扩展名 → MIME
local function EXTtoMIME(ext)
  return EXT_TO_MIME[ext:lower()] or "application/octet-stream"
end

--- 根据 URL 推断文件名和 MIME 类型
function M.getFileNameAndType(url, headers, callback)
  if type(headers) == "function" then callback = headers; headers = nil end

  -- url 为 nil 时后续各分支的 url:match 都会抛错，按函数默认命名直接回调
  if not url then
    callback("file_" .. os.time(), "application/octet-stream")
    return
  end

  -- base64
  if url:match("^data:") then
    local mimeType = url:match("^data:([^;]+)") or "application/octet-stream"
    local ext = MIMEtoEXT(mimeType) or "bin"
    callback("file_" .. os.time() .. "." .. ext, mimeType)
    return
  end

  -- 非 HTTP
  if not url:match("^https?://") then
    local fileName = URLUtil.guessFileName(url, nil, nil) or ("file_" .. os.time())
    local ext = fileName:match("%.([%w]+)$")
    local mimeType = ext and EXTtoMIME(ext) or "application/octet-stream"
    callback(fileName, mimeType)
    return
  end

  -- HTTP HEAD
  local fallback = URLUtil.guessFileName(url, nil, nil) or ("file_" .. os.time())
  -- 第三个回参是引擎按大小写无关抽取的 Content-Type（已去掉 charset 部分）；
  -- result.headers 里同名键取到的是 Java List 包装，Lua 侧不能当字符串用
  NetWork.head(url, headers, function(code, _, contentType)
    local mimeType = contentType or "application/octet-stream"
    local fileName = fallback
    local ext = MIMEtoEXT(mimeType)
    if ext then fileName = fallback:gsub("%.[^%.]+$", "") .. "." .. ext end
    callback(fileName, mimeType)
  end)
end

---下载文件到 Downloads 目录（仅支持 http/https）
---@param url string 文件链接
---@param options? table|function 可选参数或回调
---   options.fileName string 文件名（可选）
---   options.mimeType string MIME 类型（可选）
---   options.subDir string 子目录，默认 "Hydrogen"
---   options.headers table 自定义请求头
---@param callback? function 回调 (success, downloadId, errorMsg)
function M.downloadFile(url, options, callback)
  -- options 位传回调的重载先归一化，URL 守卫触发时才能可靠回调
  if type(options) == "function" then callback = options; options = {} end
  options = options or {}
  callback = callback or function() end

  if not url or url == "" then
    callback(false, nil, "URL 为空")
    return
  end

  if not url:match("^https?://") then
    callback(false, nil, "仅支持 http/https 链接")
    return
  end

  M.getFileNameAndType(url, options.headers or {}, function(fileName, mimeType)
    if options.fileName then fileName = options.fileName end
    if options.mimeType then mimeType = options.mimeType end

    local request = DownloadManager.Request(Uri.parse(url))
    request.allowedNetworkTypes = DownloadManager.Request.NETWORK_MOBILE | DownloadManager.Request.NETWORK_WIFI
    request.notificationVisibility = DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED
    request.title = fileName
    request.mimeType = mimeType
    request.allowedOverRoaming = true
    request.allowScanningByMediaScanner()
    request.addRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
    request.addRequestHeader("Referer", url)
    if options.headers then
      for k, v in pairs(options.headers) do request.addRequestHeader(k, v) end
    end

    local subDir = options.subDir or "Hydrogen"
    request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, subDir .. "/" .. fileName)

    local ok, result = pcall(function()
      return activity.getSystemService(Context.DOWNLOAD_SERVICE).enqueue(request)
    end)
    if ok then
      callback(true, result, nil)
      tip("已开始下载，请查看通知栏进度")
     else
      callback(false, nil, tostring(result))
      tip("下载失败")
    end
  end)
end

---从 URL 下载图片到 Pictures 目录
function M.saveImageFromUrl(url, options, callback)
  -- options 位传回调的重载先归一化，URL 守卫触发时才能可靠回调
  if type(options) == "function" then callback = options; options = {} end
  options = options or {}
  callback = callback or function() end

  if not url or url == "" then
    callback(false, nil, "URL 为空")
    return
  end

  local function processImage(bytes, fileName, mimeType)
    if options.fileName then fileName = options.fileName end
    if options.mimeType then mimeType = options.mimeType end
    local subDir = options.subDir or "Hydrogen"
    local relativePath = Environment.DIRECTORY_PICTURES .. "/" .. subDir
    local isGif = (mimeType == "image/gif")
    local saveOpts = {
      fileName = fileName, mimeType = mimeType,
      relativePath = relativePath, quality = options.quality or 95,
      type = isGif and "gif" or "auto",
    }

    local function onSaved(ok)
      if ok then
        callback(true, nil, nil)
        tip("已保存到相册")
       else
        callback(false, nil, "保存失败")
      end
    end

    if Build.VERSION.SDK_INT >= 29 then
      -- MediaStore 落盘是纯 IO，放到 IO 线程执行，结果回主线程收；
      -- 低版本要先走运行时权限申请（UI 操作），必须留在主线程
      task(function()
        return Extensions.File.save(bytes, saveOpts)
      end, onSaved)
     else
      Extensions.File.save(bytes, saveOpts, onSaved)
    end
  end

  -- data: URI
  if url:match("^data:") then
    M.getFileNameAndType(url, nil, function(fileName, mimeType)
      local b64 = url:match(";base64,(.+)$")
      if not b64 then callback(false, nil, "无法解析 data URI"); return end
      local ok, bytes = pcall(function() return Base64.decode(b64, Base64.DEFAULT) end)
      if not ok then callback(false, nil, "Base64 解码失败"); return end
      processImage(bytes, fileName, mimeType)
    end)
    return
  end

  -- http/https: GET 下载，响应自带 Content-Type，取不到时按文件名后缀推断
  NetWork.getRaw(url, options.headers or {}, function(code, bytes, contentType)
    if code ~= 200 or not bytes then
      callback(false, nil, "下载失败，HTTP " .. tostring(code))
      return
    end
    local fileName = URLUtil.guessFileName(url, nil, nil) or ("file_" .. os.time())
    local mimeType = contentType
    if not mimeType then
      local ext = fileName:match("%.([%w]+)$")
      mimeType = ext and EXTtoMIME(ext) or "application/octet-stream"
    end
    processImage(bytes, fileName, mimeType)
  end)
end

return M