local bit32 = _G["bit32"] or require("bit32")

---------------------------
-- 辅助函数
---------------------------
-- 将字符串转换为字节表
local function string_to_bytes(str)
  local bytes = {}
  for i = 1, #str do
    bytes[i] = string.byte(str, i)
  end
  return bytes
end

-- 将字节表转换为字符串
local function bytes_to_string(tbl)
  local chars = {}
  for _, b in ipairs(tbl) do
    table.insert(chars, string.char(b))
  end
  return table.concat(chars)
end

-- 反转数组
local function reverse_table(tbl)
  local newtbl = {}
  for i = #tbl, 1, -1 do
    table.insert(newtbl, tbl[i])
  end
  return newtbl
end

-- 将 32 位整数转换为大端字节表（长度为4）
local function int32_to_bytes(n)
  local b1 = math.floor(n / 16777216) % 256
  local b2 = math.floor(n / 65536) % 256
  local b3 = math.floor(n / 256) % 256
  local b4 = n % 256
  return {b1, b2, b3, b4}
end

-- 将一个长度为4的字节表转换为 32 位整数 (大端)
local function bytes_to_int32(tbl)
  return (((tbl[1] * 256 + tbl[2]) * 256) + tbl[3]) * 256 + tbl[4]
end

-- 将表按每 n 个元素分块，返回一个包含子表的数组
local function chunk_list(tbl, n)
  local chunks = {}
  for i = 1, #tbl, n do
    local chunk = {}
    for j = i, math.min(i+n-1, #tbl) do
      table.insert(chunk, tbl[j])
    end
    table.insert(chunks, chunk)
  end
  return chunks
end

-- PKCS7 填充：将 data (字符串) 填充到 block_size 的倍数
local function pkcs7_pad(data, block_size)
  block_size = block_size or 16
  local pad_len = block_size - (#data % block_size)
  return data .. string.rep(string.char(pad_len), pad_len)
end

-- 去除 PKCS7 填充
local function pkcs7_unpad(data)
  local pad_len = string.byte(data, #data)
  return data:sub(1, #data - pad_len)
end

-- 在 base64_chars 字符串中查找字符的索引（Lua 下索引从1开始）
local function base64_index(char, base64_chars)
  local pos = string.find(base64_chars, char, 1, true)
  if pos then
    return pos - 1 -- 转换为0-based索引以匹配后续操作
   else
    return nil
  end
end

---------------------------
-- XZSE96V3 类的实现
---------------------------
local XZSE96V3 = {
  key_pad = {48, 53, 57, 48, 53, 51, 102, 55, 100, 49, 53, 101, 48, 49, 100, 55},
  base64_chars = "6fpLRqJO8M/c3jnYxFkUVC4ZIG12SiH=5v0mXDazWBTsuw7QetbKdoPyAl+hN9rgE",
  mapping = {
    zk = {1170614578, 1024848638, 1413669199, -343334464, -766094290, -1373058082, -143119608, -297228157, 1933479194, -971186181, -406453910, 460404854, -547427574, -1891326262, -1679095901, 2119585428, -2029270069, 2035090028, -1521520070, -5587175, -77751101, -2094365853, -1243052806, 1579901135, 1321810770, 456816404, -1391643889, -229302305, 330002838, -788960546, 363569021, -1947871109},
    zb = {20, 223, 245, 7, 248, 2, 194, 209, 87, 6, 227, 253, 240, 128, 222, 91, 237, 9, 125, 157, 230, 93, 252, 205, 90, 79, 144, 199, 159, 197, 186, 167, 39, 37, 156, 198, 38, 42, 43, 168, 217, 153, 15, 103, 80, 189, 71, 191, 97, 84, 247, 95, 36, 69, 14, 35, 12, 171, 28, 114, 178, 148, 86, 182, 32, 83, 158, 109, 22, 255, 94, 238, 151, 85, 77, 124, 254, 18, 4, 26, 123, 176, 232, 193, 131, 172, 143, 142, 150, 30, 10, 146, 162, 62, 224, 218, 196, 229, 1, 192, 213, 27, 110, 56, 231, 180, 138, 107, 242, 187, 54, 120, 19, 44, 117, 228, 215, 203, 53, 239, 251, 127, 81, 11, 133, 96, 204, 132, 41, 115, 73, 55, 249, 147, 102, 48, 122, 145, 106, 118, 74, 190, 29, 16, 174, 5, 177, 129, 63, 113, 99, 31, 161, 76, 246, 34, 211, 13, 60, 68, 207, 160, 65, 111, 82, 165, 67, 169, 225, 57, 112, 244, 155, 51, 236, 200, 233, 58, 61, 47, 100, 137, 185, 64, 17, 70, 234, 163, 219, 108, 170, 166, 59, 149, 52, 105, 24, 212, 78, 173, 45, 0, 116, 226, 119, 136, 206, 135, 175, 195, 25, 92, 121, 208, 126, 139, 3, 75, 141, 21, 130, 98, 241, 40, 154, 66, 184, 49, 181, 46, 243, 88, 101, 183, 8, 23, 72, 188, 104, 179, 210, 134, 250, 201, 164, 89, 216, 202, 220, 50, 221, 152, 140, 33, 235, 214},
    zm = {120, 50, 98, 101, 99, 98, 119, 100, 103, 107, 99, 119, 97, 99, 110, 111}
  }
}

-- 左移运算（32位）
function XZSE96V3.left_shift(x, shift)
  shift = shift % 32
  return bit32.lshift(x, shift)
end

-- 无符号右移（32位）
function XZSE96V3.unsigned_right_shift(x, shift)
  shift = shift % 32
  return bit32.rshift(x, shift)
end

-- 位旋转操作：将 x 左旋转 rot 位
function XZSE96V3.rotate_xor(x, rot)
  rot = rot % 32
  return bit32.bor(bit32.lshift(x, rot), bit32.rshift(x, (32 - rot) % 32))
end

-- 变换 32 位整数：
-- 1. 将整数打包成 4 字节；
-- 2. 利用 mapping["zb"] 替换每个字节（注意 Lua 数组从1开始，所以索引 +1）；
-- 3. 将4字节还原成整数 r，然后 r 异或多个旋转结果。
function XZSE96V3.transform_value(e)
  local packed = int32_to_bytes(e)
  local transformed = {}
  for i = 1, #packed do
    transformed[i] = XZSE96V3.mapping["zb"][ packed[i] + 1 ]
  end
  local r = bytes_to_int32(transformed)
  local rx2 = XZSE96V3.rotate_xor(r, 2)
  local rx10 = XZSE96V3.rotate_xor(r, 10)
  local rx18 = XZSE96V3.rotate_xor(r, 18)
  local rx24 = XZSE96V3.rotate_xor(r, 24)
  return bit32.bxor(r, rx2, rx10, rx18, rx24)
end

-- 对 16 字节的数据块进行加密变换。
-- 1. 将数据块解包为四个 32 位整数；
-- 2. 进行 32 轮处理后，将最后 4 个整数打包成 16 字节数据返回。
function XZSE96V3.transform_block(data)
  local function bytes_to_int32_range(tbl, start)
    return (((tbl[start] * 256 + tbl[start+1]) * 256) + tbl[start+2]) * 256 + tbl[start+3]
  end
  local w0 = bytes_to_int32_range(data, 1)
  local w1 = bytes_to_int32_range(data, 5)
  local w2 = bytes_to_int32_range(data, 9)
  local w3 = bytes_to_int32_range(data, 13)
  local words = {w0, w1, w2, w3}
  for r = 1, 32 do
    local zk_val = XZSE96V3.mapping["zk"][r]
    local temp = bit32.bxor(words[r+1], words[r+2], words[r+3], zk_val)
    local transformed = XZSE96V3.transform_value(temp)
    words[r+4] = bit32.bxor(words[r], transformed)
  end
  local res_words = {words[36], words[35], words[34], words[33]}
  local result = {}
  for _, word in ipairs(res_words) do
    local b = int32_to_bytes(word)
    for _, byte in ipairs(b) do
      table.insert(result, byte)
    end
  end
  return result
end

-- 对 16 字节的数据块进行解密逆变换，恢复出经过变换前的数据块。
function XZSE96V3.reverse_transform_block(data)
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
    local zk_val = XZSE96V3.mapping["zk"][r]
    local temp = bit32.bxor(words[r+1], words[r+2], words[r+3], zk_val)
    words[r] = bit32.bxor(XZSE96V3.transform_value(temp), words[r+4])
  end
  local res_words = {words[1], words[2], words[3], words[4]}
  local result = {}
  for _, word in ipairs(res_words) do
    local b = int32_to_bytes(word)
    for _, byte in ipairs(b) do
      table.insert(result, byte)
    end
  end
  return result
end

-- 对数据块（字节表）按 16 字节分块加密。
function XZSE96V3.process_blocks(data, iv)
  local output = {}
  local current_chain = iv
  local chunks = chunk_list(data, 16)
  for _, chunk in ipairs(chunks) do
    local xored = {}
    for i = 1, 16 do
      xored[i] = bit32.bxor(chunk[i] or 0, current_chain[i])
    end
    current_chain = XZSE96V3.transform_block(xored)
    for _, byte in ipairs(current_chain) do
      table.insert(output, byte)
    end
  end
  return output
end

-- 对数据块（字节表）按 16 字节分块解密。
function XZSE96V3.reverse_process_blocks(data, iv)
  local output = {}
  local prev_chain = iv
  local chunks = chunk_list(data, 16)
  for _, chunk in ipairs(chunks) do
    local decrypted_block = XZSE96V3.reverse_transform_block(chunk)
    local plain_block = {}
    for i = 1, 16 do
      plain_block[i] = bit32.bxor(decrypted_block[i], prev_chain[i])
    end
    for _, byte in ipairs(plain_block) do
      table.insert(output, byte)
    end
    prev_chain = chunk
  end
  return output
end

-- 编码函数：
-- 1. 构造头部数据（包含 seed、device 和 md5_bytes）；
-- 2. 使用 PKCS7 填充后，将前 16 字节与 key_pad 异或混淆后进行 transform_block 得到 iv；
-- 3. 对剩余数据块执行 process_blocks 后，与 iv 组合，再进行自定义 Base64 编码。
function XZSE96V3.b64encode(md5_bytes, device, seed)
  device = device or 0
  seed = seed or 63
  local header = string.char(seed, device) .. md5_bytes
  local padded = pkcs7_pad(header, 16)
  local padded_bytes = string_to_bytes(padded)
  local header_block = {}
  for i = 1, 16 do
    header_block[i] = padded_bytes[i]
  end
  local transformed_header = {}
  for i = 1, 16 do
    transformed_header[i] = bit32.bxor(header_block[i], XZSE96V3.key_pad[i], 42)
  end
  local iv = XZSE96V3.transform_block(transformed_header)
  local body = {}
  for i = 17, #padded_bytes do
    body[i-16] = padded_bytes[i]
  end
  local transformed_body = XZSE96V3.process_blocks(body, iv)
  local combined = {}
  for _, v in ipairs(iv) do table.insert(combined, v) end
  for _, v in ipairs(transformed_body) do table.insert(combined, v) end

  -- 调整 combined 长度为 3 的倍数，不足部分补 0
  local pad_count = (3 - (#combined % 3)) % 3
  for i = 1, pad_count do
    table.insert(combined, 0)
  end

  local result = ""
  local shift_counter = 0
  for i = #combined, 3, -3 do
    local b0 = bit32.bxor(combined[i], XZSE96V3.unsigned_right_shift(58, 8 * (shift_counter % 4)))
    shift_counter = shift_counter + 1
    local b1 = bit32.bxor(combined[i-1], XZSE96V3.unsigned_right_shift(58, 8 * (shift_counter % 4)))
    shift_counter = shift_counter + 1
    local b2 = bit32.bxor(combined[i-2], XZSE96V3.unsigned_right_shift(58, 8 * (shift_counter % 4)))
    shift_counter = shift_counter + 1
    local num = b0 + bit32.lshift(b1, 8) + bit32.lshift(b2, 16)
    local c1 = XZSE96V3.base64_chars:sub((num & 63) + 1, (num & 63) + 1)
    local c2 = XZSE96V3.base64_chars:sub((bit32.rshift(num, 6) & 63) + 1, (bit32.rshift(num, 6) & 63) + 1)
    local c3 = XZSE96V3.base64_chars:sub((bit32.rshift(num, 12) & 63) + 1, (bit32.rshift(num, 12) & 63) + 1)
    local c4 = XZSE96V3.base64_chars:sub((bit32.rshift(num, 18) & 63) + 1, (bit32.rshift(num, 18) & 63) + 1)
    result = result .. c1 .. c2 .. c3 .. c4
  end

  return result
end

-- 解码函数：
-- 1. 逆向将编码字符串转换为字节流；
-- 2. 分离出最后 16 字节作为 iv，其余为主体数据（均反转顺序）；
-- 3. 使用 reverse_process_blocks 恢复明文，再去除 PKCS7 填充，返回 seed, device 及 md5_bytes。
function XZSE96V3.b64decode(encoded)
  local shift_counter = 0
  local decoded_bytes = {}
  for i = 1, #encoded, 4 do
    local chunk = encoded:sub(i, i+3)
    local d4 = base64_index(chunk:sub(4,4), XZSE96V3.base64_chars)
    local d3 = base64_index(chunk:sub(3,3), XZSE96V3.base64_chars)
    local d2 = base64_index(chunk:sub(2,2), XZSE96V3.base64_chars)
    local d1 = base64_index(chunk:sub(1,1), XZSE96V3.base64_chars)
    local num = bit32.lshift(d4, 18) + bit32.lshift(d3, 12) + bit32.lshift(d2, 6) + d1
    for _, shift in ipairs({0, 8, 16}) do
      local byte = bit32.band(bit32.rshift(num, shift), 255)
      byte = bit32.bxor(byte, XZSE96V3.unsigned_right_shift(58, 8 * (shift_counter % 4)))
      shift_counter = shift_counter + 1
      table.insert(decoded_bytes, byte)
    end
  end

  while decoded_bytes[1] == 0 do
    table.remove(decoded_bytes, 1)
  end

  local total = #decoded_bytes
  local iv = reverse_table({table.unpack(decoded_bytes, total-15, total)})
  local body = reverse_table({table.unpack(decoded_bytes, 1, total-16)})
  local untransformed_body = XZSE96V3.reverse_process_blocks(body, iv)
  local reversed_header = XZSE96V3.reverse_transform_block(iv)
  local header_untransformed = {}
  for i = 1, 16 do
    header_untransformed[i] = bit32.bxor(reversed_header[i], XZSE96V3.key_pad[i], 42)
  end
  local combined = {}
  for _, v in ipairs(header_untransformed) do table.insert(combined, v) end
  for _, v in ipairs(untransformed_body) do table.insert(combined, v) end

  local full_data = pkcs7_unpad(bytes_to_string(combined))
  local seed = string.byte(full_data, 1)
  local device = string.byte(full_data, 2)
  local md5_bytes = full_data:sub(3)
  return { seed = seed, device = device, md5_bytes = md5_bytes }
end

local function getmd5(url)
  local path,md5str,加密前数据
  local 判断url="https://www.zhihu.com"
  if url:find(判断url) then
    path= url:match("zhihu.com(.+)")
    url=url
   elseif url:find("https://api.zhihu.com") then
    path="/api/v4"..url:match("zhihu.com(.+)")
    url=判断url..path
  end
  
  local cookie = 获取Cookie("https://www.zhihu.com/")
  -- 尝试从多个可能的域获取 cookie，如果第一个失败了
  if not cookie or not cookie:find("d_c0") then
    cookie = 获取Cookie("https://zhihu.com")
  end
  
  local dc0 = cookie and cookie:match("d_c0=\"?([^\";]+)\"?")
  
  if not dc0 then
    -- 如果确实缺失 d_c0，后台触发刷新，但本次请求使用随机生成的临时 udid 替代以防止崩溃
    -- 知乎的签名算法在缺失 d_c0 时通常可以使用 udid 或随机字符串占位通过初步校验
    Http.get("https://www.zhihu.com/", function(code, content) end)
    dc0 = activity.getSharedData("udid") or "null"
  end
  
  加密前数据="101_3_3.0+"..path.."+"..dc0
  md5str=string.lower(MD5(加密前数据))
  return url,md5str
end

local function encrypt(url)
  local url,md5str=getmd5(url)
  local myhead = {
    ["cookie"] = 获取Cookie("https://www.zhihu.com/");
    ["x-api-version"] = "3.0.91";
    ["x-zse-93"] = "101_3_3.0";
    ["x-zse-96"] = "2.0_"..XZSE96V3.b64encode(md5str);
    ["x-app-za"] = "OS=Web";
  }
  return url,myhead
end

return encrypt