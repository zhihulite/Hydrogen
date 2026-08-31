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
local FileInputStream = luajava.bindClass("java.io.FileInputStream")
local Intent = luajava.bindClass("android.content.Intent")
local Uri = luajava.bindClass("android.net.Uri")
local ActivityResultContracts = luajava.bindClass("androidx.activity.result.contract.ActivityResultContracts")
local String = luajava.bindClass("java.lang.String")
local BitmapFactoryOptions = luajava.bindClass("android.graphics.BitmapFactory$Options")
local ByteArray = luajava.bindClass("[B")
local LuaUtil = luajava.bindClass("org.luajvm.android.util.LuaUtil")

local saveLauncher = nil
local saveQueue = {}
local isProcessing = false

local pickFileLauncher = nil
local pickFileQueue = {}
local pickFileProcessing = false

local initialized = false

---保存数据到 MediaStore (Android 10+)
---@param data any 数据
---@param fileName string 文件名
---@param mimeType string MIME类型
---@param relativePath string 相对路径
---@param quality number 质量
---@param isGif boolean 是否GIF
---@return boolean
local function saveToMediaStore(data, fileName, mimeType, relativePath, quality, isGif)
  local values = ContentValues()
  local collection

  if mimeType:find("image") and (relativePath:find("Pictures") or relativePath:find("DCIM")) then
    collection = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
    values.put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
    values.put(MediaStore.Images.Media.MIME_TYPE, mimeType)
    values.put(MediaStore.Images.Media.RELATIVE_PATH, relativePath)
   elseif mimeType:find("video") and (relativePath:find("Movies") or relativePath:find("DCIM")) then
    collection = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
    values.put(MediaStore.Video.Media.DISPLAY_NAME, fileName)
    values.put(MediaStore.Video.Media.MIME_TYPE, mimeType)
    values.put(MediaStore.Video.Media.RELATIVE_PATH, relativePath)
   elseif mimeType:find("audio") and (relativePath:find("Music") or relativePath:find("Podcasts") or relativePath:find("Ringtones") or relativePath:find("Alarms")) then
    collection = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
    values.put(MediaStore.Audio.Media.DISPLAY_NAME, fileName)
    values.put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
    values.put(MediaStore.Audio.Media.RELATIVE_PATH, relativePath)
   else
    collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
    values.put(MediaStore.Downloads.DISPLAY_NAME, fileName)
    values.put(MediaStore.Downloads.MIME_TYPE, mimeType)
    values.put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
  end

  values.put(MediaStore.MediaColumns.IS_PENDING, int(1))

  local uri = activity.contentResolver.insert(collection, values)
  if not uri then return false end

  local stream = nil
  local ok, result = xpcall(function()
    stream = activity.contentResolver.openOutputStream(uri)
    -- 字节串与 Java byte[] 都直接写出（Lua 字符串直传 write(byte[])，二进制原样）；
    -- 只有 Bitmap 需要先编码
    if luajava.instanceof(data, Bitmap) and not (isGif or mimeType == "image/gif") then
      local fmt = (mimeType == "image/png") and BitmapCompressFormat.PNG or BitmapCompressFormat.JPEG
      local q = (mimeType == "image/png") and 100 or (quality or 95)
      data.compress(fmt, q, stream)
     else
      stream.write(data)
    end
    stream.flush()
    stream.close()
    stream = nil

    values.clear()

    -- 必须为 int
    values.put(MediaStore.MediaColumns.IS_PENDING, int(0))
    activity.contentResolver.update(uri, values, nil, nil)
    end, function(e)
    return debug.traceback(e, 2)
  end)

  -- 写到一半失败时流还开着；此时 IS_PENDING 仍为 1，记录相册看不到也不会被回收，一并删掉
  if stream then pcall(function() stream.close() end) end
  if not ok then
    pcall(function() activity.contentResolver.delete(uri, nil, nil) end)
    print(result)
  end
  return ok
end

---保存到文件系统 (Android 9-)
local function saveToFile(data, fileName, relativePath, quality, isGif, mimeType)
  local dir = File(Environment.getExternalStoragePublicDirectory(relativePath), "")
  if not dir.exists() then dir.mkdirs() end

  local file = File(dir, fileName)
  local ok = pcall(function()
    local stream = FileOutputStream(file)
    if luajava.instanceof(data, Bitmap) and not (isGif or mimeType == "image/gif") then
      local fmt = (mimeType == "image/png") and BitmapCompressFormat.PNG or BitmapCompressFormat.JPEG
      local q = (mimeType == "image/png") and 100 or (quality or 95)
      data.compress(fmt, q, stream)
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

---检查存储权限
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

---初始化 SAF 启动器
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
        local cursor = nil
        pcall(function() cursor = activity.contentResolver.query(uri, nil, nil, nil, nil) end)
        if cursor then
          -- 取名字与关闭分开，读列时抛异常也不漏 Cursor
          local ok, name = pcall(function()
            if cursor.moveToFirst() then
              local idx = cursor.getColumnIndex("_display_name")
              if idx >= 0 then return cursor.getString(idx) end
            end
            return ""
          end)
          pcall(function() cursor.close() end)
          if ok and name then displayName = name end
        end
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
  -- launch 抛异常（设备缺文件管理器时）后不会有回调，必须自己出队复位，否则队列永久卡住
  local ok = pcall(function() saveLauncher.launch(saveQueue[1].fileName) end)
  if not ok then
    local task = table.remove(saveQueue, 1)
    isProcessing = false
    if task and task.callback then task.callback(false) end
    M.processNext()
  end
end

---处理文件选择队列中的下一个任务
function M.processNextPickFile()
  if pickFileProcessing or #pickFileQueue == 0 then return end
  pickFileProcessing = true
  local arr = luajava.newArray(String, 1)
  arr[0] = pickFileQueue[1].mimeType
  local ok = pcall(function() pickFileLauncher.launch(arr) end)
  if not ok then
    local task = table.remove(pickFileQueue, 1)
    pickFileProcessing = false
    if task and task.callback then task.callback(nil) end
    M.processNextPickFile()
  end
end

-- 基础文件操作

function M.exists(path)
  return File(path).exists()
end

function M.isDir(path)
  return File(path).isDirectory()
end

function M.read(path)
  local f = io.open(path, "r")
  if not f then return "" end
  local content = f:read("*a")
  f:close()
  return content or ""
end

function M.write(path, content)
  local file = File(path)
  local parent = file.parentFile
  if not parent.exists() then parent.mkdirs() end
  local f = io.open(path, "w")
  if not f then return false end
  f:write(tostring(content))
  f:close()
  return true
end

function M.append(path, content)
  local f = io.open(path, "a")
  if not f then return false end
  f:write(tostring(content))
  f:close()
  return true
end

function M.delete(path)
  local function rm(dir)
    local files = dir.listFiles()
    if files then
      for _, f in ipairs(luajava.astable(files)) do
        if f.isDirectory() then rm(f) else f.delete() end
      end
    end
    dir.delete()
  end
  rm(File(path))
  return true
end

function M.mkdir(path)
  return File(path).mkdirs()
end

--- 拷贝文件或目录，目标不可写、单端 open 失败都返回 false
--- @param src string
--- @param dest string
--- @return boolean
function M.copy(src, dest)
  local srcFile = File(src)
  local destFile = File(dest)
  if srcFile.isDirectory() then
    destFile.mkdirs()
    local files = srcFile.listFiles()
    if not files then return false end
    local ok = true
    for _, f in ipairs(luajava.astable(files)) do
      if not M.copy(tostring(f), dest .. "/" .. f.name) then ok = false end
    end
    return ok
   else
    -- 源端用 io.open 预检可读；目标端的存在性/可写性走 File API 判断，
    -- 打开写句柄做预检会把已存在的目标先截断为空，拷贝失败后只剩空文件
    local input = io.open(src, "rb")
    if not input then return false end
    input:close()
    if destFile.isDirectory() then return false end
    if destFile.exists() and not destFile.canWrite() then return false end
    local ok, copied = pcall(function()
      local fin = FileInputStream(src)
      local fout = FileOutputStream(dest)
      local copied = LuaUtil.copyFile(fin, fout)
      pcall(function() fin.close() end)
      pcall(function() fout.close() end)
      return copied
    end)
    return ok and copied or false
  end
end

--- 列出目录下的文件，返回完整路径列表；recursive 为 true 时包含子目录内文件
--- @param path string
--- @param recursive boolean
--- @return table
function M.list(path, recursive)
  local result = {}
  local files = File(path).listFiles()
  if not files then return result end
  for _, f in ipairs(luajava.astable(files)) do
    if f.isDirectory() then
      if recursive then
        for _, sub in ipairs(M.list(tostring(f), true)) do
          result[#result + 1] = sub
        end
      end
     else
      result[#result + 1] = tostring(f)
    end
  end
  return result
end

--- 目录下所有文件的大小总和（字节）
--- @param path string
--- @return number
function M.getDirSize(path)
  local total = 0
  for _, p in ipairs(M.list(path, true)) do
    total = total + File(p).length()
  end
  return total
end

--- 读文件全部字节
--- @param filePath string
--- @return any|nil Java byte[]（userdata）
function M.fileToBytes(filePath)
  if not M.exists(filePath) then return nil end
  return LuaUtil.readAll(filePath)
end

function M.move(src, dest)
  return File(src).renameTo(File(dest))
end

function M.size(path)
  return File(path).length()
end

function M.getAppDir(subPath)
  local base = activity.getExternalFilesDir(nil).toString()
  if subPath then return base .. "/Hydrogen/" .. subPath end
  return base
end

function M.getDownloadDir(subPath)
  local base = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).toString()
  if subPath then return base .. "/" .. subPath end
  return base
end

function M.getCacheDir()
  return activity.cacheDir
end

function M.sanitizeForFilename(name)
  local illegal = {
    ["/"] = "／", [":"] = "：", ["*"] = "＊", ["?"] = "？",
    ['"'] = "＂", ["<"] = "＜", [">"] = "＞", ["|"] = "｜",
    ["\\"] = "＼",
  }
  -- 括号截断 gsub 的第二个返回值（替换计数）
  return (name:gsub("[\\/:*?\"<>|]", illegal))
end

-- 保存方法

---通用保存
---@param data any 数据
---@param options table|nil 选项
---@param onDone fun(ok: boolean)|nil 保存结果回调；API 29 以下要先申请存储权限，结果只能异步给出
---@return boolean|nil API 29 及以上同步返回结果，以下返回 nil，结果走 onDone
function M.save(data, options, onDone)
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
    local ok = saveToMediaStore(data, fileName, mimeType, relativePath, quality, isGif)
    if onDone then onDone(ok) end
    return ok
   else
    checkStoragePermission(function(granted)
      local ok = false
      if granted then
        ok = saveToFile(data, fileName, relativePath, quality, isGif, mimeType)
      end
      if onDone then onDone(ok) end
    end)
  end
end

---保存图片
function M.saveImage(bitmap, options, onDone)
  if not bitmap then
    if onDone then onDone(false) end
    return false
  end
  options = options or {}
  options.type = "image"
  options.mimeType = "image/jpeg"
  options.fileName = options.fileName or ("IMG_" .. os.date("%Y%m%d_%H%M%S") .. ".jpg")
  options.relativePath = options.relativePath or Environment.DIRECTORY_PICTURES
  return M.save(bitmap, options, onDone)
end

---从文件保存图片
function M.saveImageFromFile(filePath, options, onDone)
  return M.saveImage(BitmapFactory.decodeFile(filePath), options, onDone)
end

---保存 GIF
function M.saveGif(data, options, onDone)
  if not data then
    if onDone then onDone(false) end
    return false
  end
  if not luajava.instanceof(data, ByteArray) then
    error("saveGif: data 必须是 Java byte[]")
  end
  options = options or {}
  options.type = "gif"
  options.mimeType = "image/gif"
  options.fileName = options.fileName or ("GIF_" .. os.date("%Y%m%d_%H%M%S") .. ".gif")
  options.relativePath = options.relativePath or Environment.DIRECTORY_PICTURES
  return M.save(data, options, onDone)
end

function M.isGifData(data)
  if type(data) == "string" then
    if #data > 6 then
      local header = data:sub(1, 6)
      return header == "GIF89a" or header == "GIF87a"
    end
    return false
  end
  -- byte[] userdata（readAll/download 等的字节结果）走魔数判断
  local ok, isGif = pcall(M.isGifFromBytes, data)
  if ok then return isGif end
  return false
end

-- SAF 保存/选择

function M.saveFileWithPicker(data, options, callback)
  if not data then return end
  if not initialized then error("call File.init() first") end

  if not luajava.instanceof(data, ByteArray) then
    error("data 必须是 Java byte[]")
  end

  options = options or {}
  local fileName = options.fileName or ("file_" .. os.date("%Y%m%d_%H%M%S"))
  local isGif = options.isGif or false
  if isGif and not fileName:match("%.gif$") then fileName = fileName .. ".gif" end

  if Build.VERSION.SDK_INT >= 29 then
    table.insert(saveQueue, {
      data = data, quality = options.quality or 95,
      fileName = fileName, callback = callback, isGif = isGif,
    })
    M.processNext()
   else
    checkStoragePermission(function(granted)
      if granted then
        local rp = options.relativePath or Environment.DIRECTORY_DOWNLOADS
        local ok = saveToFile(data, fileName, rp, options.quality or 95, isGif, options.mimeType or "application/octet-stream")
        if callback then callback(ok, ok and Uri.fromFile(File(Environment.getExternalStoragePublicDirectory(rp), fileName)) or nil) end
       else
        table.insert(saveQueue, {
          data = data, quality = options.quality or 95,
          fileName = fileName, callback = callback, isGif = isGif,
        })
        M.processNext()
      end
    end)
  end
end

function M.writeToUri(uri, data, quality, isGif)
  quality = quality or 95
  return pcall(function()
    local stream = activity.contentResolver.openOutputStream(uri, "w")
    if luajava.instanceof(data, Bitmap) and not isGif then
      data.compress(BitmapCompressFormat.JPEG, quality, stream)
     else
      stream.write(data)
    end
    stream.flush(); stream.close()
  end)
end

function M.pickFile(mimeType, callback)
  if type(mimeType) == "function" then callback = mimeType; mimeType = "*/*" end
  mimeType = mimeType or "*/*"
  if not initialized then error("call File.init() first") end
  table.insert(pickFileQueue, { mimeType = mimeType, callback = callback })
  M.processNextPickFile()
end

-- Uri 操作

-- 统一的 Uri 读流入口：open、执行、关闭三步分离，fn 抛异常时也保证关流。
-- 返回值为 pcall 的成功标志加 fn 的前两个返回值
local function withInputStream(uri, fn)
  if not uri then return false end
  local okOpen, stream = pcall(function() return activity.contentResolver.openInputStream(uri) end)
  if not okOpen or not stream then return false end
  local ok, a, b = pcall(fn, stream)
  pcall(function() stream.close() end)
  return ok, a, b
end

--- 读 Uri 为文本（字节读出后按 UTF-8 解码）
--- @param uri any
--- @return string
function M.readUri(uri)
  local ok, bytes = withInputStream(uri, function(stream)
    return LuaUtil.readAll(stream)
  end)
  if not ok or not bytes then return "" end
  return tostring(String(bytes, "UTF-8"))
end

--- 读 Uri 为字节数组
--- @param uri any
--- @return any|nil Java byte[]（userdata，可作输出缓冲与 byte[] 形参实参）
function M.readUriAsBytes(uri)
  local ok, bytes = withInputStream(uri, function(stream)
    return LuaUtil.readAll(stream)
  end)
  if not ok then return nil end
  return bytes
end

--- 拷贝 Uri 内容到本地文件
--- @param uri any
--- @param destPath string
--- @return boolean
function M.copyFromUri(uri, destPath)
  if not uri then return false end
  local destFile = File(destPath)
  local parent = destFile.parentFile
  if parent and not parent.exists() then parent.mkdirs() end
  local ok, copied = withInputStream(uri, function(inputStream)
    local output = FileOutputStream(destFile)
    local copiedOk, copied = pcall(function()
      return LuaUtil.copyFile(inputStream, output)
    end)
    pcall(function() output.close() end)
    return copiedOk and copied or false
  end)
  return ok and copied or false
end

-- 图片工具

function M.getImageSizeFromUri(uri)
  if not uri then return 0, 0 end
  local opts = BitmapFactoryOptions()
  opts.inJustDecodeBounds = true
  local ok, w, h = withInputStream(uri, function(stream)
    BitmapFactory.decodeStream(stream, nil, opts)
    return opts.outWidth, opts.outHeight
  end)
  if not ok then return 0, 0 end
  return w, h
end

function M.getImageSizeFromBytes(bytes)
  if not bytes then return 0, 0 end
  local opts = BitmapFactoryOptions()
  opts.inJustDecodeBounds = true
  BitmapFactory.decodeByteArray(bytes, 0, #bytes, opts)
  return opts.outWidth, opts.outHeight
end

function M.isGifFromBytes(bytes)
  if not bytes or #bytes < 6 then return false end
  local s = String(bytes, 0, 6, "US-ASCII")
  local h = tostring(s)
  return h == "GIF89a" or h == "GIF87a"
end

function M.isGifFromUri(uri)
  if not uri then return false end
  local ok, isGif = withInputStream(uri, function(stream)
    local h = {}
    for i = 1, 6 do h[i] = stream.read() end
    return h[1] == 71 and h[2] == 73 and h[3] == 70
  end)
  if not ok then return false end
  return isGif
end

return M