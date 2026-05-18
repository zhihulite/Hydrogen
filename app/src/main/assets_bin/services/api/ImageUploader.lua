-- services/api/ImageUploader.lua
-- 知乎图片上传服务（完整阿里云 OSS 签名版本）

local M = {}

local function md5(bytes)
  if type(bytes) == "userdata" then
    -- Java byte[] -> MD5
    local MessageDigest = luajava.bindClass("java.security.MessageDigest")
    local BigInteger = luajava.bindClass("java.math.BigInteger")
    local md = MessageDigest.getInstance("MD5")
    local digest = md.digest(bytes)
    local hash = BigInteger(1, digest).toString(16)
    while #hash < 32 do hash = "0" .. hash end
    return hash
  end
  return Helpers.Crypto.md5(bytes)
end

local function hmacSha1(key, message)
  local Mac = luajava.bindClass("javax.crypto.Mac")
  local SecretKeySpec = luajava.bindClass("javax.crypto.spec.SecretKeySpec")
  local Base64 = luajava.bindClass("android.util.Base64")

  local signingKey = SecretKeySpec(key, "HmacSHA1")
  local mac = Mac.getInstance("HmacSHA1")
  mac.init(signingKey)
  local rawHmac = mac.doFinal(message)
  return Base64.encodeToString(rawHmac, Base64.NO_WRAP)
end

local function ossSign(accessKey, stringToSign)
  local keyBytes = luajava.newInstance("java.lang.String", accessKey).getBytes("UTF-8")
  local messageBytes = luajava.newInstance("java.lang.String", stringToSign).getBytes("UTF-8")
  return hmacSha1(keyBytes, messageBytes)
end

local function ossPutObject(uploadUrl, objectKey, imageBytes, contentType, token, callback)
  -- 方法1：使用 SimpleDateFormat 指定格式
  local SimpleDateFormat = luajava.bindClass("java.text.SimpleDateFormat")
  local TimeZone = luajava.bindClass("java.util.TimeZone")
  local Locale = luajava.bindClass("java.util.Locale")

  local ossDate = SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", Locale.US)
  ossDate.setTimeZone(TimeZone.getTimeZone("GMT"))

  local ossDateStr = ossDate.format(luajava.newInstance("java.util.Date"))

  local ossUserAgent = "aliyun-sdk-js/6.8.0"
  local bucket = "zhihu-pics"
  local canonicalizedResource = "/" .. bucket .. "/" .. objectKey

  local canonicalizedOSSHeaders =
  "x-oss-date:" .. ossDateStr .. "\n" ..
  "x-oss-security-token:" .. token.access_token .. "\n" ..
  "x-oss-user-agent:" .. ossUserAgent

  local stringToSign =
  "PUT\n" ..
  "\n" ..
  (contentType or "image/jpeg") .. "\n" ..
  ossDateStr .. "\n" ..
  canonicalizedOSSHeaders .. "\n" ..
  canonicalizedResource

  local signature = ossSign(token.access_key, stringToSign)
  local authorization = "OSS " .. token.access_id .. ":" .. signature

  local headers = {
    ["Content-Type"] = contentType or "image/jpeg",
    ["Authorization"] = authorization,
    ["x-oss-date"] = ossDateStr,
    ["x-oss-security-token"] = token.access_token,
    ["x-oss-user-agent"] = ossUserAgent,
  }
    
  local str = NetWork.bytesToLuaString(imageBytes)
  local url = uploadUrl .. "/" .. objectKey
  NetWork.put(url, imageBytes, headers, function(code, _)
    callback(code == 200)
  end)
end

--- 等待图片处理完成并获取 src
--- @param imageId string 图片 ID
--- @param callback function function(success, imageUrl)
local function waitForImageSrc(imageId, callback)
  local maxRetries = 10
  local retryCount = 0

  local function checkStatus()
    NetWork.get(
    "https://api.zhihu.com/images/" .. imageId,
    Headers.defaultHead,
    function(code, content)
      if code ~= 200 then
        retryCount = retryCount + 1
        if retryCount < maxRetries then
          task(1000, checkStatus)
         else
          callback(false, nil)
        end
        return
      end

      local result = json.decode(content)
      if result and result.original_hash then
        callback(true, "https://pic4.zhimg.com/" .. result.original_hash)
       elseif result and result.src then
        callback(true, result.src)
       else
        retryCount = retryCount + 1
        if retryCount < maxRetries then
          task(1000, checkStatus)
         else
          callback(false, nil)
        end
      end
    end
    )
  end

  checkStatus()
end

--- 上传图片到知乎
--- @param imageBytes table Java byte[] 图片字节数据
--- @param callback function 回调 function(success, imageUrl)
function M.upload(imageBytes, callback)
  if not imageBytes then
    if callback then callback(false, nil) end
    return
  end

  -- 1. 计算图片 hash
  local imageHash = md5(imageBytes)

  -- 2. 请求上传许可
  local postData = json.encode({
    image_hash = imageHash,
    source = "article"
  })

  NetWork.post(
  "https://api.zhihu.com/images",
  postData,
  Headers["postApp"],
  function(code, content)
    if code ~= 200 then
      if callback then callback(false, nil) end
      return
    end

    local result = json.decode(content)
    if not result then
      if callback then callback(false, nil) end
      return
    end

    local uploadFile = result.upload_file
    if not uploadFile then
      if callback then callback(false, nil) end
      return
    end

    -- 3. 如果图片已存在（state == 1），直接获取 src
    if uploadFile.state == 1 and uploadFile.image_id then
      waitForImageSrc(uploadFile.image_id, callback)
      return
    end

    -- 4. 图片不存在（state == 2），上传到阿里云 OSS
    local uploadToken = result.upload_token
    if not uploadToken or not uploadFile.object_key then
      if callback then callback(false, nil) end
      return
    end

    local uploadUrl = "https://zhihu-pics-upload.zhimg.com"

    ossPutObject(uploadUrl, uploadFile.object_key, imageBytes, "image/jpeg", uploadToken, function(code)
      if code == 200 then
        -- OSS 上传成功后，通知知乎服务器
        local imageId = uploadFile.image_id
        local statusUrl = "https://api.zhihu.com/images/" .. imageId .. "/uploading_status"
        NetWork.put(statusUrl, '{"upload_result":"success"}', Headers["postApp"], function(code, _)
          if code ~= 200 then callback(false, nil) return end
          waitForImageSrc(uploadFile.image_id, callback)
        end)
       else
        if callback then callback(false, nil) end
      end
    end)
  end
  )
end

return M