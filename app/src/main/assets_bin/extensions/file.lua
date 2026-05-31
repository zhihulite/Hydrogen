-- extensions/file.lua
-- 文件操作

local M = {}

local File = luajava.bindClass("java.io.File")
local Build = luajava.bindClass("android.os.Build")
local Environment = luajava.bindClass("android.os.Environment")
local ContentValues = luajava.bindClass("android.content.ContentValues")
local MediaStore = luajava.bindClass("android.provider.MediaStore")
local BitmapFactory = luajava.bindClass("android.graphics.BitmapFactory")
local Bitmap = luajava.bindClass("android.graphics.Bitmap")
local BitmapCompressFormat = luajava.bindClass("android.graphics.Bitmap$CompressFormat")
local FileOutputStream = luajava.bindClass("java.io.FileOutputStream")
local Intent = luajava.bindClass("android.content.Intent")
local Uri = luajava.bindClass("android.net.Uri")
local ActivityResultContracts = luajava.bindClass("androidx.activity.result.contract.ActivityResultContracts")
local DownloadManager = luajava.bindClass("android.app.DownloadManager")
local URLUtil = luajava.bindClass("android.webkit.URLUtil")
local Context = luajava.bindClass("android.content.Context")
local FileInputStream = luajava.bindClass("java.io.FileInputStream")
local URLUtil = luajava.bindClass("android.webkit.URLUtil")

local saveLauncher = nil
local saveQueue = {}
local isProcessing = false

local pickFileLauncher = nil
local pickFileQueue = {}
local pickFileProcessing = false

local initialized = false

---保存数据到 MediaStore (Android 10+)
---@param data any 数据 (Bitmap/string/bytes)
---@param fileName string 文件名
---@param mimeType string MIME类型
---@param relativePath string 相对路径
---@param quality number 质量(1-100)
---@param isGif boolean 是否为GIF
---@return boolean 是否成功
local function saveToMediaStoreInternal(data, fileName, mimeType, relativePath, quality, isGif)
  local values = ContentValues()
  local collection

  if mimeType:find("image") then
    collection = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
    values.put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
    values.put(MediaStore.Images.Media.MIME_TYPE, mimeType)
    values.put(MediaStore.Images.Media.RELATIVE_PATH, relativePath)
   else
    collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
    values.put(MediaStore.Downloads.DISPLAY_NAME, fileName)
    values.put(MediaStore.Downloads.MIME_TYPE, mimeType)
    values.put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
  end

  -- 必须为 int
  values.put(MediaStore.MediaColumns.IS_PENDING, int(1))

  local uri = activity.contentResolver.insert(collection, values)
  if not uri then return false end

  local ok,result = xpcall(function()
    local stream = activity.contentResolver.openOutputStream(uri)
    if isGif or mimeType == "image/gif" then
      local bytes = data
      stream.write(bytes)
     elseif luajava.instanceof(data, Bitmap) then
      local compressFormat = (mimeType == "image/png") and BitmapCompressFormat.PNG or BitmapCompressFormat.JPEG
      local q = (mimeType == "image/png") and 100 or (quality or 95)
      data.compress(compressFormat, q, stream)
     elseif type(data) == "string" then
      local bytes = luajava.newInstance("java.lang.String", data).getBytes("UTF-8")
      stream.write(bytes)
     else
      stream.write(data)
    end
    stream.flush()
    stream.close()

    values.clear()

    -- 必须为 int
    values.put(MediaStore.MediaColumns.IS_PENDING, int(0))
    activity.contentResolver.update(uri, values, nil, nil)
    end,function(e)
    return debug.traceback(e, 2)
  end)

  if not ok then
    print(result)
  end

  return ok
end

---保存数据到文件系统 (Android 9 及以下)
---@param data any 数据 (Bitmap/string/bytes)
---@param fileName string 文件名
---@param relativePath string 相对路径
---@param quality number 质量(1-100)
---@param isGif boolean 是否为GIF
---@param mimeType string MIME类型
---@return boolean 是否成功
local function saveToFileInternal(data, fileName, relativePath, quality, isGif, mimeType)
  local dir = File(Environment.getExternalStoragePublicDirectory(relativePath), "")
  if not dir.exists() then dir.mkdirs() end

  local file = File(dir, fileName)
  local ok = pcall(function()
    local stream = FileOutputStream(file)
    if isGif or (mimeType == "image/gif") then
      stream.write(data)
     elseif luajava.instanceof(data, Bitmap) then
      local compressFormat = (mimeType == "image/png") and BitmapCompressFormat.PNG or BitmapCompressFormat.JPEG
      local q = (mimeType == "image/png") and 100 or (quality or 95)
      data.compress(compressFormat, q, stream)
     elseif type(data) == "string" then
      local bytes = luajava.newInstance("java.lang.String", data).getBytes("UTF-8")
      stream.write(bytes)
     else
      stream.write(data)
    end
    stream.flush()
    stream.close()

    local intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
    intent.data = Uri.fromFile(file)
    activity.sendBroadcast(intent)
  end)

  return ok
end

---检查并请求存储权限
---@param callback fun(granted: boolean) 回调函数
local function checkStoragePermission(callback)
  if Services.Permission.check("android.permission.WRITE_EXTERNAL_STORAGE") then
    callback(true)
   else
    Services.Permission.request("android.permission.WRITE_EXTERNAL_STORAGE", callback, {
      title = "存储权限",
      message = "保存文件需要存储权限"
    })
  end
end

---初始化模块，注册 ActivityResult 启动器
---在使用文件选择器或 SAF 保存前必须调用
function M.init()
  if initialized then return end

  saveLauncher = activity.registerForActivityResult(
  ActivityResultContracts.CreateDocument("*/*"),
  function(uri)
    local task = saveQueue[1]
    if task then
      table.remove(saveQueue, 1)
      if uri then
        local ok = M.writeToUri(uri, task.data, task.quality, task.isGif)
        if task.callback then task.callback(ok, uri) end
       else
        if task.callback then task.callback(false) end
      end
    end
    isProcessing = false
    if #saveQueue > 0 then M.processNext() end
  end
  )

  pickFileLauncher = activity.registerForActivityResult(
  ActivityResultContracts.OpenDocument(),
  function(uri)
    local task = pickFileQueue[1]
    if task then
      table.remove(pickFileQueue, 1)
      if uri and task.callback then
        local displayName = ""
        pcall(function()
          local cursor = activity.contentResolver.query(uri, nil, nil, nil, nil)
          if cursor then
            if cursor.moveToFirst() then
              local nameIndex = cursor.getColumnIndex("_display_name")
              if nameIndex >= 0 then
                displayName = cursor.getString(nameIndex)
              end
            end
            cursor.close()
          end
        end)
        task.callback(uri, displayName)
       elseif task.callback then
        task.callback(nil)
      end
    end
    pickFileProcessing = false
    if #pickFileQueue > 0 then M.processNextPickFile() end
  end
  )

  initialized = true
end

---处理保存队列中的下一个任务
function M.processNext()
  if isProcessing or #saveQueue == 0 then return end
  isProcessing = true
  saveLauncher.launch(saveQueue[1].fileName)
end

---处理文件选择队列中的下一个任务
function M.processNextPickFile()
  if pickFileProcessing or #pickFileQueue == 0 then return end
  pickFileProcessing = true
  local mimeArray = luajava.newArray(luajava.bindClass("java.lang.String"), 1)
  mimeArray[0] = pickFileQueue[1].mimeType
  pickFileLauncher.launch(mimeArray)
end

---检查文件是否存在
---@param path string 文件路径
---@return boolean 是否存在
function M.exists(path)
  return File(path).exists()
end

---检查是否为目录
---@param path string 路径
---@return boolean 是否为目录
function M.isDir(path)
  return File(path).isDirectory()
end

---读取文本文件内容
---@param path string 文件路径
---@return string 文件内容
function M.read(path)
  local f = io.open(path, "r")
  if not f then return "" end
  local content = f:read("*a")
  f:close()
  return content or ""
end

---写入文本文件
---@param path string 文件路径
---@param content string 内容
---@return boolean 是否成功
function M.write(path, content)
  local file = File(path)
  local parent = file.parentFile
  if not parent.exists() then
    parent.mkdirs()
  end
  local f = io.open(path, "w")
  if not f then return false end
  f:write(tostring(content))
  f:close()
  return true
end

---追加内容到文件
---@param path string 文件路径
---@param content string 内容
---@return boolean 是否成功
function M.append(path, content)
  local f = io.open(path, "a")
  if not f then return false end
  f:write(tostring(content))
  f:close()
  return true
end

---删除文件或目录(递归)
---@param path string 文件路径
---@return boolean 是否成功
function M.delete(path)
  local function rm(dir)
    local files = dir.listFiles()
    if files then
      for _, f in ipairs(luajava.astable(files)) do
        if f.isDirectory() then
          rm(f)
         else
          f.delete()
        end
      end
    end
    dir.delete()
  end
  rm(File(path))
  return true
end

---创建目录(包括父目录)
---@param path string 目录路径
---@return boolean 是否成功
function M.mkdir(path)
  return File(path).mkdirs()
end

---复制文件或目录
---@param src string 源路径
---@param dest string 目标路径
---@return boolean 是否成功
function M.copy(src, dest)
  local srcFile = File(src)
  local destFile = File(dest)

  if srcFile.isDirectory() then
    destFile.mkdirs()
    for _, f in ipairs(luajava.astable(srcFile.listFiles())) do
      M.copy(tostring(f), dest .. "/" .. f.name)
    end
   else
    local input = io.open(src, "rb")
    local output = io.open(dest, "wb")
    if input and output then
      output:write(input:read("*a"))
      output:close()
      input:close()
    end
  end
  return true
end

---将文件路径转为 Java byte[]
---@param filePath string 文件路径
---@return userdata|nil Java byte[] 对象
function M.fileToBytes(filePath)
  if not M.exists(filePath) then return nil end

  local file = File(filePath)
  local fis = FileInputStream(file)
  local Byte = luajava.bindClass("java.lang.Byte").TYPE
  local bytes = luajava.newArray(Byte, file.length())
  fis.read(bytes)
  fis.close()

  return bytes
end

---移动/重命名文件
---@param src string 源路径
---@param dest string 目标路径
---@return boolean 是否成功
function M.move(src, dest)
  return File(src).renameTo(File(dest))
end

---获取文件大小(字节)
---@param path string 文件路径
---@return number 文件大小
function M.size(path)
  return File(path).length()
end

---获取应用私有目录
---@param subPath? string 子路径
---@return string 目录路径
function M.getAppDir(subPath)
  local base = activity.getExternalFilesDir(nil).toString()
  if subPath then
    return base .. "/Hydrogen/" .. subPath
  end
  return base
end

---获取下载目录
---@param subPath? string 子路径
---@return string 目录路径
function M.getDownloadDir(subPath)
  local base = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).toString()
  if subPath then
    return base .. "/" .. subPath
  end
  return base
end

---获取缓存目录
---@return string 缓存目录路径
function M.getCacheDir()
  return activity.cacheDir.toString()
end

---过滤文件名中的非法字符
---@param name string 原始文件名
---@return string 安全的文件名
function M.sanitizeForFilename(name)
  local illegal = {
    ["/"] = "／",
    [":"] = "：",
    ["*"] = "＊",
    ["?"] = "？",
    ['"'] = "＂",
    ["<"] = "＜",
    [">"] = "＞",
    ["|"] = "｜",
  }
  return name:gsub("[\\/:*?\"<>|]", illegal)
end

---通用保存方法
---@param data any 数据
---@param options? table 选项
---@option options.type string 类型: "auto", "image", "gif"
---@option options.fileName string 文件名
---@option options.relativePath string 相对路径
---@option options.quality number 质量(1-100)
---@option options.mimeType string MIME类型
---@return boolean 是否成功
function M.save(data, options)
  options = options or {}
  local dataType = options.type or "auto"
  local fileName = options.fileName or ("file_" .. os.date("%Y%m%d_%H%M%S"))
  local relativePath = options.relativePath or Environment.DIRECTORY_DOWNLOADS
  local quality = options.quality or 95
  local mimeType = options.mimeType or "application/octet-stream"
  local isGif = false

  if dataType == "auto" then
    if M.isGifData(data) then
      isGif = true
      mimeType = "image/gif"
      if not fileName:match("%.gif$") then fileName = fileName .. ".gif" end
     elseif luajava.instanceof(data, Bitmap) then
      mimeType = "image/jpeg"
      if not fileName:match("%.jpg$") then fileName = fileName .. ".jpg" end
    end
   elseif dataType == "gif" then
    isGif = true
    mimeType = "image/gif"
    if not fileName:match("%.gif$") then fileName = fileName .. ".gif" end
   elseif dataType == "image" then
    mimeType = options.mimeType or "image/jpeg"
    if not fileName:match("%.jpg$") then fileName = fileName .. ".jpg" end
  end

  if Build.VERSION.SDK_INT >= 29 then
    return saveToMediaStoreInternal(data, fileName, mimeType, relativePath, quality, isGif)
   else
    local success = false
    checkStoragePermission(function(granted)
      if granted then
        success = saveToFileInternal(data, fileName, relativePath, quality, isGif, mimeType)
      end
    end)
    return success
  end
end

--- 根据 URL 推断文件名和 MIME 类型
--- @param url string 图片 URL
--- @param headers table|nil 自定义请求头
--- @param callback function 回调函数 (fileName, mimeType)
function M.getFileNameAndType(url, headers, callback)
  -- 重载：getFileNameAndType(url, callback)
  if type(headers) == "function" then
    callback = headers
    headers = nil
  end

  -- 备选文件名：从 URL 猜测
  local fallbackName = URLUtil.guessFileName(url, nil, nil) or ("image_" .. os.time())
  if not fallbackName:find("%.") then
    fallbackName = fallbackName .. ".jpg"
  end

  NetWork.head(url, headers, function(code, respHeaders)
    local mimeType = nil
    local fileName = fallbackName

    if respHeaders and respHeaders["Content-Type"] then
      mimeType = respHeaders["Content-Type"]:match("([^;]+)")

      local extMap = {
        ["image/jpeg"] = "jpg",
        ["image/png"] = "png",
        ["image/gif"] = "gif",
        ["image/webp"] = "webp",
      }

      local correctExt = extMap[mimeType]
      if correctExt then
        local nameWithoutExt = fallbackName:gsub("%.[^%.]+$", "")
        fileName = nameWithoutExt .. "." .. correctExt
        if fileName == "." .. correctExt then
          fileName = "image_" .. os.time() .. "." .. correctExt
        end
      end
    end

    local finalMime = mimeType or "image/*"
    callback(fileName, finalMime)
  end)
end

---保存图片
---@param bitmap Bitmap 位图对象
---@param options? table 选项
---@option options.fileName string 文件名
---@option options.relativePath string 相对路径
---@option options.quality number 质量(1-100)
---@return boolean 是否成功
function M.saveImage(bitmap, options)
  if not bitmap then return false end
  options = options or {}
  options.type = "image"
  options.mimeType = "image/jpeg"
  options.fileName = options.fileName or ("IMG_" .. os.date("%Y%m%d_%H%M%S") .. ".jpg")
  options.relativePath = options.relativePath or Environment.DIRECTORY_PICTURES
  return M.save(bitmap, options)
end

---从文件保存图片
---@param filePath string 图片文件路径
---@param options? table 选项
---@return boolean 是否成功
function M.saveImageFromFile(filePath, options)
  local bitmap = BitmapFactory.decodeFile(filePath)
  return M.saveImage(bitmap, options)
end

---检查字符串数据是否为GIF
---@param data string 数据
---@return boolean 是否为GIF
function M.isGifData(data)
  if type(data) == "string" and #data > 6 then
    local header = data:sub(1, 6)
    return header == "GIF89a" or header == "GIF87a"
  end
  return false
end

---保存GIF数据
---@param data byte[] GIF二进制数据
---@param options? table 选项
---@option options.fileName string 文件名
---@option options.relativePath string 相对路径
---@return boolean 是否成功
function M.saveGif(data, options)
  if not data then return false end
  local byteArrayClass = luajava.bindClass("[B")
  if not luajava.instanceof(data, byteArrayClass) then
    error("saveGif: data 参数必须是 Java byte[] 类型")
  end
  options = options or {}
  options.type = "gif"
  options.mimeType = "image/gif"
  options.fileName = options.fileName or ("GIF_" .. os.date("%Y%m%d_%H%M%S") .. ".gif")
  options.relativePath = options.relativePath or Environment.DIRECTORY_PICTURES
  return M.save(data, options)
end

---使用文件选择器保存GIF (SAF)
---@param data string GIF二进制数据
---@param options? table 选项
---@param callback? fun(success: boolean, uri: any) 回调
function M.saveGifWithPicker(data, options, callback)
  if not data then return end
  if not initialized then
    error("File not initialized, call File.init() first")
    return
  end

  options = options or {}
  local fileName = options.fileName or ("GIF_" .. os.date("%Y%m%d_%H%M%S") .. ".gif")

  table.insert(saveQueue, {
    data = data,
    quality = 100,
    fileName = fileName,
    callback = callback,
    isGif = true,
  })
  M.processNext()
end

---使用文件选择器保存文件 (SAF)
---@param data any 数据
---@param options? table 选项
---@param callback? fun(success: boolean, uri: any) 回调
function M.saveFileWithPicker(data, options, callback)
  if not data then return end
  if not initialized then
    error("File not initialized, call File.init() first")
    return
  end

  local byteArrayClass = luajava.bindClass("[B")
  if not luajava.instanceof(data, byteArrayClass) then
    error("saveGif: data 参数必须是 Java byte[] 类型")
  end

  options = options or {}
  local fileName = options.fileName or ("file_" .. os.date("%Y%m%d_%H%M%S"))
  local isGif = options.isGif or false

  if isGif and not fileName:match("%.gif$") then
    fileName = fileName .. ".gif"
  end

  if Build.VERSION.SDK_INT >= 29 then
    table.insert(saveQueue, {
      data = data,
      quality = options.quality or 95,
      fileName = fileName,
      callback = callback,
      isGif = isGif,
    })
    M.processNext()
   else
    checkStoragePermission(function(granted)
      if granted then
        local relativePath = options.relativePath or Environment.DIRECTORY_DOWNLOADS
        local ok = saveToFileInternal(data, fileName, relativePath, options.quality or 95, isGif)
        if callback then callback(ok, ok and Uri.fromFile(File(Environment.getExternalStoragePublicDirectory(relativePath), fileName)) or nil) end
       else
        table.insert(saveQueue, {
          data = data,
          quality = options.quality or 95,
          fileName = fileName,
          callback = callback,
          isGif = isGif,
        })
        M.processNext()
      end
    end)
  end
end

---写入数据到 Uri
---@param uri any Uri对象
---@param data any 数据
---@param quality? number 质量
---@param isGif? boolean 是否为GIF
---@return boolean 是否成功
function M.writeToUri(uri, data, quality, isGif)
  quality = quality or 95
  local ok = pcall(function()
    local stream = activity.contentResolver.openOutputStream(uri, "w")

    if isGif then
      local bytes = data
      stream.write(bytes)
     elseif luajava.instanceof(data, Bitmap) then
      data.compress(BitmapCompressFormat.JPEG, quality, stream)
     elseif type(data) == "string" then
      local bytes = luajava.newInstance("java.lang.String", data).getBytes("UTF-8")
      stream.write(bytes)
     else
      stream.write(data)
    end

    stream.flush()
    stream.close()
  end)
  return ok
end

---选择文件 (通过 SAF)
---@param mimeType string|fun(uri: any, name: string) 文件类型，默认为 "*/*"，如果传入function则作为回调
---@param callback? fun(uri: any, displayName: string) 回调 function(uri, displayName)
function M.pickFile(mimeType, callback)
  if type(mimeType) == "function" then
    callback = mimeType
    mimeType = "*/*"
  end
  mimeType = mimeType or "*/*"

  if not initialized then
    error("File not initialized, call File.init() first")
    return
  end

  table.insert(pickFileQueue, {
    mimeType = mimeType,
    callback = callback,
  })
  M.processNextPickFile()
end

---读取 Uri 内容为文本
---@param uri any Uri对象
---@return string 文件内容
function M.readUri(uri)
  if not uri then return "" end
  local stream = activity.contentResolver.openInputStream(uri)
  if not stream then return "" end

  local buffer = luajava.newInstance("java.io.ByteArrayOutputStream")
  local data = luajava.newArray(luajava.bindClass("java.lang.Byte").TYPE, 8192)
  local len = stream.read(data)
  while len > 0 do
    buffer.write(data, 0, len)
    len = stream.read(data)
  end
  stream.close()
  local content = buffer.toString("UTF-8")
  buffer.close()
  return content
end

---读取 Uri 内容为 byte[]
---@param uri any Uri对象
---@return userdata|nil Java byte[] 对象
function M.readUriAsBytes(uri)
  if not uri then return nil end
  local stream = activity.contentResolver.openInputStream(uri)
  if not stream then return nil end

  local buffer = luajava.newInstance("java.io.ByteArrayOutputStream")
  local data = luajava.newArray(luajava.bindClass("java.lang.Byte").TYPE, 8192)
  local len = stream.read(data)
  while len > 0 do
    buffer.write(data, 0, len)
    len = stream.read(data)
  end
  stream.close()
  local bytes = buffer.toByteArray()
  buffer.close()
  return bytes
end

---从 Uri 复制文件到本地路径
---@param uri any Uri对象
---@param destPath string 目标路径
---@return boolean 是否成功
function M.copyFromUri(uri, destPath)
  if not uri then return false end

  local inputStream = activity.contentResolver.openInputStream(uri)
  if not inputStream then return false end

  local destFile = File(destPath)
  local parent = destFile.parentFile
  if parent and not parent.exists() then
    parent.mkdirs()
  end

  local outputStream = FileOutputStream(destFile)
  local byteBuffer = luajava.newArray(luajava.bindClass("java.lang.Byte").TYPE, 8192)
  local len = inputStream.read(byteBuffer)
  while len > 0 do
    outputStream.write(byteBuffer, 0, len)
    len = inputStream.read(byteBuffer)
  end
  outputStream.close()
  inputStream.close()

  return true
end

---下载文件到公共下载目录（无需存储权限）
---@param url string 文件链接
---@param options? table|function 可选参数或回调
---   options.fileName string 文件名（可选，默认从 URL 推断）
---   options.mimeType string MIME 类型（可选）
---   options.subDir string 子目录，默认 "Hydrogen"
---   options.headers table 自定义请求头
---@param callback? function 回调函数 (success, downloadId, errorMsg)
function M.downloadFile(url, options, callback)
  if not url or url == "" then
    if callback then callback(false, nil, "URL 为空") end
    return
  end

  -- 重载1：downloadFile(url, callback)
  if type(options) == "function" then
    callback = options
    options = {}
  end

  -- 重载2：downloadFile(url) 或 downloadFile(url, options)
  options = options or {}
  callback = callback or function() end

  -- 通过 HEAD 请求获取真实文件名和 MIME 类型
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
      for k, v in pairs(options.headers) do
        request.addRequestHeader(k, v)
      end
    end

    local subDir = options.subDir or "Hydrogen"
    request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, subDir .. "/" .. fileName)

    local success, result = pcall(function()
      return activity.getSystemService(Context.DOWNLOAD_SERVICE).enqueue(request)
    end)

    if success then
      callback(true, result, nil)
      tip("已开始下载，请查看通知栏进度")
     else
      callback(false, nil, tostring(result))
      tip("下载失败")
    end
  end)
end

--- 获取图片的宽高（从 Uri）
--- @param uri any Uri对象
--- @return number width, number height
function M.getImageSizeFromUri(uri)
  if not uri then return 0, 0 end

  local options = luajava.newInstance("android.graphics.BitmapFactory$Options")
  options.inJustDecodeBounds = true

  local inputStream = activity.contentResolver.openInputStream(uri)
  if not inputStream then return 0, 0 end

  BitmapFactory.decodeStream(inputStream, nil, options)
  inputStream.close()

  return options.outWidth, options.outHeight
end

--- 获取图片的宽高（从 byte[]）
--- @param bytes userdata Java byte[] 数组
--- @return number width, number height
function M.getImageSizeFromBytes(bytes)
  if not bytes then return 0, 0 end

  local options = luajava.newInstance("android.graphics.BitmapFactory$Options")
  options.inJustDecodeBounds = true

  BitmapFactory.decodeByteArray(bytes, 0, #bytes, options)

  return options.outWidth, options.outHeight
end

--- 判断 byte[] 是否为 GIF
--- @param bytes userdata Java byte[] 数组
--- @return boolean isGif
function M.isGifFromBytes(bytes)
  if not bytes or #bytes < 6 then return false end

  -- 将 byte[] 前6个字节转为 Lua 字符串
  local javaString = luajava.newInstance("java.lang.String", bytes, 0, 6, "US-ASCII")
  local header = tostring(javaString)

  return header == "GIF89a" or header == "GIF87a"
end

--- 判断 Uri 是否为 GIF
--- @param uri any Uri对象
--- @return boolean isGif
function M.isGifFromUri(uri)
  if not uri then return false end

  local inputStream = activity.contentResolver.openInputStream(uri)
  if not inputStream then return false end

  local header = {}
  for i = 1, 6 do
    header[i] = inputStream.read()
  end
  inputStream.close()

  if header[1] == 71 and header[2] == 73 and header[3] == 70 then -- 'G','I','F'
    return true
  end
  return false
end

return M