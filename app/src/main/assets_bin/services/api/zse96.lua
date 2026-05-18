-- services/api/zse96.lua
-- 加密参数生成

local M = {}

local bit32 = _G.bit32 or require("bit32")

-- ============================================
-- 辅助函数
-- ============================================

local function stringToBytes(str)
  local bytes = {}
  for i = 1, #str do
    bytes[i] = string.byte(str, i)
  end
  return bytes
end

local function bytesToString(tbl)
  local chars = {}
  for _, b in ipairs(tbl) do
    table.insert(chars, string.char(b))
  end
  return table.concat(chars)
end

local function reverseTable(tbl)
  local newtbl = {}
  for i = #tbl, 1, -1 do
    table.insert(newtbl, tbl[i])
  end
  return newtbl
end

local function int32ToBytes(n)
  return {
    math.floor(n / 16777216) % 256,
    math.floor(n / 65536) % 256,
    math.floor(n / 256) % 256,
    n % 256
  }
end

local function bytesToInt32(tbl)
  return (((tbl[1] * 256 + tbl[2]) * 256) + tbl[3]) * 256 + tbl[4]
end

local function chunkList(tbl, n)
  local chunks = {}
  for i = 1, #tbl, n do
    local chunk = {}
    for j = i, math.min(i + n - 1, #tbl) do
      table.insert(chunk, tbl[j])
    end
    table.insert(chunks, chunk)
  end
  return chunks
end

local function pkcs7Pad(data, blockSize)
  blockSize = blockSize or 16
  local padLen = blockSize - (#data % blockSize)
  return data .. string.rep(string.char(padLen), padLen)
end

local function pkcs7Unpad(data)
  local padLen = string.byte(data, #data)
  return data:sub(1, #data - padLen)
end

-- ============================================
-- XZSE96V3 实现
-- ============================================

local XZSE96V3 = {
  keyPad = {48, 53, 57, 48, 53, 51, 102, 55, 100, 49, 53, 101, 48, 49, 100, 55},
  base64Chars = "6fpLRqJO8M/c3jnYxFkUVC4ZIG12SiH=5v0mXDazWBTsuw7QetbKdoPyAl+hN9rgE",
  mapping = {
    zk = {1170614578, 1024848638, 1413669199, -343334464, -766094290, -1373058082, -143119608, -297228157, 1933479194, -971186181, -406453910, 460404854, -547427574, -1891326262, -1679095901, 2119585428, -2029270069, 2035090028, -1521520070, -5587175, -77751101, -2094365853, -1243052806, 1579901135, 1321810770, 456816404, -1391643889, -229302305, 330002838, -788960546, 363569021, -1947871109},
    zb = {20, 223, 245, 7, 248, 2, 194, 209, 87, 6, 227, 253, 240, 128, 222, 91, 237, 9, 125, 157, 230, 93, 252, 205, 90, 79, 144, 199, 159, 197, 186, 167, 39, 37, 156, 198, 38, 42, 43, 168, 217, 153, 15, 103, 80, 189, 71, 191, 97, 84, 247, 95, 36, 69, 14, 35, 12, 171, 28, 114, 178, 148, 86, 182, 32, 83, 158, 109, 22, 255, 94, 238, 151, 85, 77, 124, 254, 18, 4, 26, 123, 176, 232, 193, 131, 172, 143, 142, 150, 30, 10, 146, 162, 62, 224, 218, 196, 229, 1, 192, 213, 27, 110, 56, 231, 180, 138, 107, 242, 187, 54, 120, 19, 44, 117, 228, 215, 203, 53, 239, 251, 127, 81, 11, 133, 96, 204, 132, 41, 115, 73, 55, 249, 147, 102, 48, 122, 145, 106, 118, 74, 190, 29, 16, 174, 5, 177, 129, 63, 113, 99, 31, 161, 76, 246, 34, 211, 13, 60, 68, 207, 160, 65, 111, 82, 165, 67, 169, 225, 57, 112, 244, 155, 51, 236, 200, 233, 58, 61, 47, 100, 137, 185, 64, 17, 70, 234, 163, 219, 108, 170, 166, 59, 149, 52, 105, 24, 212, 78, 173, 45, 0, 116, 226, 119, 136, 206, 135, 175, 195, 25, 92, 121, 208, 126, 139, 3, 75, 141, 21, 130, 98, 241, 40, 154, 66, 184, 49, 181, 46, 243, 88, 101, 183, 8, 23, 72, 188, 104, 179, 210, 134, 250, 201, 164, 89, 216, 202, 220, 50, 221, 152, 140, 33, 235, 214},
    zm = {120, 50, 98, 101, 99, 98, 119, 100, 103, 107, 99, 119, 97, 99, 110, 111}
  }
}

function XZSE96V3:leftShift(x, shift)
  return bit32.lshift(x, shift % 32)
end

function XZSE96V3:rightShift(x, shift)
  return bit32.rshift(x, shift % 32)
end

function XZSE96V3:rotateXor(x, rot)
  rot = rot % 32
  return bit32.bor(bit32.lshift(x, rot), bit32.rshift(x, (32 - rot) % 32))
end

function XZSE96V3:transformValue(e)
  local packed = int32ToBytes(e)
  local transformed = {}
  for i = 1, #packed do
    transformed[i] = self.mapping.zb[packed[i] + 1]
  end
  local r = bytesToInt32(transformed)
  return bit32.bxor(r, self:rotateXor(r, 2), self:rotateXor(r, 10), self:rotateXor(r, 18), self:rotateXor(r, 24))
end

function XZSE96V3:transformBlock(data)
  local function bytesToInt32Range(tbl, start)
    return (((tbl[start] * 256 + tbl[start + 1]) * 256) + tbl[start + 2]) * 256 + tbl[start + 3]
  end

  local w0 = bytesToInt32Range(data, 1)
  local w1 = bytesToInt32Range(data, 5)
  local w2 = bytesToInt32Range(data, 9)
  local w3 = bytesToInt32Range(data, 13)
  local words = {w0, w1, w2, w3}

  for r = 1, 32 do
    local zkVal = self.mapping.zk[r]
    local temp = bit32.bxor(words[r + 1], words[r + 2], words[r + 3], zkVal)
    local transformed = self:transformValue(temp)
    words[r + 4] = bit32.bxor(words[r], transformed)
  end

  local resWords = {words[36], words[35], words[34], words[33]}
  local result = {}
  for _, word in ipairs(resWords) do
    local b = int32ToBytes(word)
    for _, byte in ipairs(b) do
      table.insert(result, byte)
    end
  end
  return result
end

function XZSE96V3:reverseTransformBlock(data)
  local words = {}
  for i = 1, 32 do words[i] = 0 end

  local unpacked = {}
  for i = 1, 4 do
    local start = (i - 1) * 4 + 1
    local word = 0
    for j = 0, 3 do
      word = word * 256 + data[start + j]
    end
    table.insert(unpacked, word)
  end

  local rev = {}
  for i = #unpacked, 1, -1 do
    table.insert(rev, unpacked[i])
  end

  for i = 1, 4 do
    words[32 + i] = rev[i]
  end

  for r = 32, 1, -1 do
    local zkVal = self.mapping.zk[r]
    local temp = bit32.bxor(words[r + 1], words[r + 2], words[r + 3], zkVal)
    words[r] = bit32.bxor(self:transformValue(temp), words[r + 4])
  end

  local resWords = {words[1], words[2], words[3], words[4]}
  local result = {}
  for _, word in ipairs(resWords) do
    local b = int32ToBytes(word)
    for _, byte in ipairs(b) do
      table.insert(result, byte)
    end
  end
  return result
end

function XZSE96V3:processBlocks(data, iv)
  local output = {}
  local currentChain = iv
  local chunks = chunkList(data, 16)

  for _, chunk in ipairs(chunks) do
    local xored = {}
    for i = 1, 16 do
      xored[i] = bit32.bxor(chunk[i] or 0, currentChain[i])
    end
    currentChain = self:transformBlock(xored)
    for _, byte in ipairs(currentChain) do
      table.insert(output, byte)
    end
  end
  return output
end

function XZSE96V3:reverseProcessBlocks(data, iv)
  local output = {}
  local prevChain = iv
  local chunks = chunkList(data, 16)

  for _, chunk in ipairs(chunks) do
    local decryptedBlock = self:reverseTransformBlock(chunk)
    local plainBlock = {}
    for i = 1, 16 do
      plainBlock[i] = bit32.bxor(decryptedBlock[i], prevChain[i])
    end
    for _, byte in ipairs(plainBlock) do
      table.insert(output, byte)
    end
    prevChain = chunk
  end
  return output
end

function XZSE96V3:b64encode(md5Bytes, device, seed)
  device = device or 0
  seed = seed or 63
  local header = string.char(seed, device) .. md5Bytes
  local padded = pkcs7Pad(header, 16)
  local paddedBytes = stringToBytes(padded)

  local headerBlock = {}
  for i = 1, 16 do
    headerBlock[i] = paddedBytes[i]
  end

  local transformedHeader = {}
  for i = 1, 16 do
    transformedHeader[i] = bit32.bxor(headerBlock[i], self.keyPad[i], 42)
  end

  local iv = self:transformBlock(transformedHeader)

  local body = {}
  for i = 17, #paddedBytes do
    body[i - 16] = paddedBytes[i]
  end

  local transformedBody = self:processBlocks(body, iv)

  local combined = {}
  for _, v in ipairs(iv) do table.insert(combined, v) end
  for _, v in ipairs(transformedBody) do table.insert(combined, v) end

  local padCount = (3 - (#combined % 3)) % 3
  for i = 1, padCount do
    table.insert(combined, 0)
  end

  local resultParts = {}
  local shiftCounter = 0
  for i = #combined, 3, -3 do
    local b0 = bit32.bxor(combined[i], self:rightShift(58, 8 * (shiftCounter % 4)))
    shiftCounter = shiftCounter + 1
    local b1 = bit32.bxor(combined[i - 1], self:rightShift(58, 8 * (shiftCounter % 4)))
    shiftCounter = shiftCounter + 1
    local b2 = bit32.bxor(combined[i - 2], self:rightShift(58, 8 * (shiftCounter % 4)))
    shiftCounter = shiftCounter + 1

    local num = b0 + bit32.lshift(b1, 8) + bit32.lshift(b2, 16)
    local c1 = self.base64Chars:sub((num & 63) + 1, (num & 63) + 1)
    local c2 = self.base64Chars:sub((bit32.rshift(num, 6) & 63) + 1, (bit32.rshift(num, 6) & 63) + 1)
    local c3 = self.base64Chars:sub((bit32.rshift(num, 12) & 63) + 1, (bit32.rshift(num, 12) & 63) + 1)
    local c4 = self.base64Chars:sub((bit32.rshift(num, 18) & 63) + 1, (bit32.rshift(num, 18) & 63) + 1)

    table.insert(resultParts, c1)
    table.insert(resultParts, c2)
    table.insert(resultParts, c3)
    table.insert(resultParts, c4)
  end

  return table.concat(resultParts)
end

-- ============================================
-- 公开接口
-- ============================================

local function getMd5(url)
  local path
  local targetUrl = url

  if url:find("https://www.zhihu.com") then
    path = url:match("zhihu.com(.+)")
   elseif url:find("https://api.zhihu.com") then
    path = "/api/v4" .. url:match("zhihu.com(.+)")
    targetUrl = "https://www.zhihu.com" .. path
  end

  local cookie = NetWork.getCookie("https://www.zhihu.com/")
  local dc0 = cookie and cookie:match('d_c0="?([^";]+)"?')

  if not dc0 then
    return error("合成参数失败 请检查登录状态 (如若想不登录浏览跳转主页登录页即可 不用登录)")
  end

  local dataToHash = "101_3_3.0+" .. (path or "") .. "+" .. dc0
  local md5Str = string.lower(Extensions.Crypto.md5(dataToHash))

  return targetUrl, md5Str
end

function M.encrypt(url)
  local newUrl, md5Str = getMd5(url)

  local headers = {
    ["cookie"] = NetWork.getCookie("https://www.zhihu.com/");
    ["x-api-version"] = "3.0.91";
    ["x-zse-93"] = "101_3_3.0";
    ["x-zse-96"] = "2.0_"..XZSE96V3:b64encode(md5Str);
    ["x-app-za"] = "OS=Web";
  }

  return newUrl, headers
end

return M