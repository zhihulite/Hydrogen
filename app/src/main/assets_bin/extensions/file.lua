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
local FileInputStream = luajava.bindClass("java.io.FileInputStream")

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

  local ok, result = xpcall(function()
    local stream = activity.contentResolver.openOutputStream(uri)
    if isGif or mimeType == "image/gif" then
      stream.write(data)
     elseif luajava.instanceof(data, Bitmap) then
      local fmt = (mimeType == "image/png") and BitmapCompressFormat.PNG or BitmapCompressFormat.JPEG
      local q = (mimeType == "image/png") and 100 or (quality or 95)
      data.compress(fmt, q, stream)
     elseif type(data) == "string" then
      stream.write(luajava.newInstance("java.lang.String", data).getBytes("UTF-8"))
     else
      stream.write(data)
    end
    stream.flush()
    stream.close()

    values.clear()

    -- 必须为 int
    values.put(MediaStore.MediaColumns.IS_PENDING, int(0))
    activity.contentResolver.update(uri, values, nil, nil)
    end, function(e)
    return debug.traceback(e, 2)
  end)

  if not ok then print(result) end
  return ok
end

---保存到文件系统 (Android 9-)
local function saveToFile(data, fileName, relativePath, quality, isGif, mimeType)
  local dir = File(Environment.getExternalStoragePublicDirectory(relativePath), "")
  if not dir.exists() then dir.mkdirs() end

  local file = File(dir, fileName)
  local ok = pcall(function()
    local stream = FileOutputStream(file)
    if isGif or mimeType == "image/gif" then
      stream.write(data)
     elseif luajava.instanceof(data, Bitmap) then
      local fmt = (mimeType == "image/png") and BitmapCompressFormat.PNG or BitmapCompressFormat.JPEG
      local q = (mimeType == "image/png") and 100 or (quality or 95)
      data.compress(fmt, q, stream)
     elseif type(data) == "string" then
      stream.write(luajava.newInstance("java.lang.String", data).getBytes("UTF-8"))
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
        pcall(function()
          local cursor = activity.contentResolver.query(uri, nil, nil, nil, nil)
          if cursor then
            if cursor.moveToFirst() then
              local idx = cursor.getColumnIndex("_display_name")
              if idx >= 0 then displayName = cursor.getString(idx) end
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
  local arr = luajava.newArray(luajava.bindClass("java.lang.String"), 1)
  arr[0] = pickFileQueue[1].mimeType
  pickFileLauncher.launch(arr)
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
  }
  return name:gsub("[\\/:*?\"<>|]", illegal)
end

-- 保存方法

---通用保存
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
    return saveToMediaStore(data, fileName, mimeType, relativePath, quality, isGif)
   else
    local success = false
    checkStoragePermission(function(granted)
      if granted then
        success = saveToFile(data, fileName, relativePath, quality, isGif, mimeType)
      end
    end)
    return success
  end
end

---保存图片
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
function M.saveImageFromFile(filePath, options)
  return M.saveImage(BitmapFactory.decodeFile(filePath), options)
end

---保存 GIF
function M.saveGif(data, options)
  if not data then return false end
  if not luajava.instanceof(data, luajava.bindClass("[B")) then
    error("saveGif: data 必须是 Java byte[]")
  end
  options = options or {}
  options.type = "gif"
  options.mimeType = "image/gif"
  options.fileName = options.fileName or ("GIF_" .. os.date("%Y%m%d_%H%M%S") .. ".gif")
  options.relativePath = options.relativePath or Environment.DIRECTORY_PICTURES
  return M.save(data, options)
end

function M.isGifData(data)
  if type(data) == "string" and #data > 6 then
    local header = data:sub(1, 6)
    return header == "GIF89a" or header == "GIF87a"
  end
  return false
end

-- SAF 保存/选择

function M.saveFileWithPicker(data, options, callback)
  if not data then return end
  if not initialized then error("call File.init() first") end

  if not luajava.instanceof(data, luajava.bindClass("[B")) then
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
        local ok = saveToFile(data, fileName, rp, options.quality or 95, isGif)
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
    if isGif then
      stream.write(data)
     elseif luajava.instanceof(data, Bitmap) then
      data.compress(BitmapCompressFormat.JPEG, quality, stream)
     elseif type(data) == "string" then
      stream.write(luajava.newInstance("java.lang.String", data).getBytes("UTF-8"))
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

function M.readUri(uri)
  if not uri then return "" end
  local stream = activity.contentResolver.openInputStream(uri)
  if not stream then return "" end
  local buffer = luajava.newInstance("java.io.ByteArrayOutputStream")
  local data = luajava.newArray(luajava.bindClass("java.lang.Byte").TYPE, 8192)
  local len = stream.read(data)
  while len > 0 do buffer.write(data, 0, len); len = stream.read(data) end
  stream.close()
  local content = buffer.toString("UTF-8")
  buffer.close()
  return content
end

function M.readUriAsBytes(uri)
  if not uri then return nil end
  local stream = activity.contentResolver.openInputStream(uri)
  if not stream then return nil end
  local buffer = luajava.newInstance("java.io.ByteArrayOutputStream")
  local data = luajava.newArray(luajava.bindClass("java.lang.Byte").TYPE, 8192)
  local len = stream.read(data)
  while len > 0 do buffer.write(data, 0, len); len = stream.read(data) end
  stream.close()
  local bytes = buffer.toByteArray(); buffer.close()
  return bytes
end

function M.copyFromUri(uri, destPath)
  if not uri then return false end
  local inputStream = activity.contentResolver.openInputStream(uri)
  if not inputStream then return false end
  local destFile = File(destPath)
  local parent = destFile.parentFile
  if parent and not parent.exists() then parent.mkdirs() end
  local outputStream = FileOutputStream(destFile)
  local buf = luajava.newArray(luajava.bindClass("java.lang.Byte").TYPE, 8192)
  local len = inputStream.read(buf)
  while len > 0 do outputStream.write(buf, 0, len); len = inputStream.read(buf) end
  outputStream.close(); inputStream.close()
  return true
end

-- 图片工具

function M.getImageSizeFromUri(uri)
  if not uri then return 0, 0 end
  local opts = luajava.newInstance("android.graphics.BitmapFactory$Options")
  opts.inJustDecodeBounds = true
  local stream = activity.contentResolver.openInputStream(uri)
  if not stream then return 0, 0 end
  BitmapFactory.decodeStream(stream, nil, opts)
  stream.close()
  return opts.outWidth, opts.outHeight
end

function M.getImageSizeFromBytes(bytes)
  if not bytes then return 0, 0 end
  local opts = luajava.newInstance("android.graphics.BitmapFactory$Options")
  opts.inJustDecodeBounds = true
  BitmapFactory.decodeByteArray(bytes, 0, #bytes, opts)
  return opts.outWidth, opts.outHeight
end

function M.isGifFromBytes(bytes)
  if not bytes or #bytes < 6 then return false end
  local s = luajava.newInstance("java.lang.String", bytes, 0, 6, "US-ASCII")
  local h = tostring(s)
  return h == "GIF89a" or h == "GIF87a"
end

function M.isGifFromUri(uri)
  if not uri then return false end
  local stream = activity.contentResolver.openInputStream(uri)
  if not stream then return false end
  local h = {}
  for i = 1, 6 do h[i] = stream.read() end
  stream.close()
  return h[1] == 71 and h[2] == 73 and h[3] == 70
end

return M