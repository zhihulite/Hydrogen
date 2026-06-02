-- helpers/zhihu_parser.lua
-- url 解析器

local M = {}

import "android.webkit.CookieManager"

local function urlEncode(s)
  local s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
  return string.gsub(s, " ", "+")
end

local function urlDecode(s)
  local s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
  return s
end

local URL_SPLIT_PATTERN = "([^%?]+)%??(.*)"

--- 解析知乎链接
---@param url string 知乎链接
---@return table|nil { type, id, questionId, url }
function M.parse(url)
  if not url or url == "" then return nil end

  local fullUrl = url

  if fullUrl:find("^zhihu://") then
    fullUrl = fullUrl:gsub("^zhihu://([^/]+)(.*)", function(word, rest)
      -- 第一个/ 有 s 就替换掉
      if word:sub(-1) == "s" then word = word:sub(1, -2) end
      return "https://www.zhihu.com/" .. word .. rest
    end)
  end

  if not fullUrl:find("zhihu.com") then
    return nil
  end

  local base, query = fullUrl:match(URL_SPLIT_PATTERN)
  if not base then
    return nil
  end

  -- 回答（带问题ID）
  local qId, aId = base:match("question/(%d+)/answers?/(%d+)")
  if qId and aId then
    return { type = "answer", id = aId, questionId = qId }
  end

  local answerId = base:match("answer/(%d+)")
  if answerId then
    return { type = "answer", id = answerId }
  end

  local questionId = base:match("question/(%d+)")
  if questionId then
    return { type = "question", id = questionId }
  end

  -- article(s) 仅在 intent 出现
  local articleId = base:match("p/(%d+)") or base:match("article/(%d+)")
  if articleId then
    return { type = "article", id = articleId }
  end

  local topicId = base:match("topics/(%d+)") or base:match("topic/(%d+)")
  if topicId then
    return { type = "topic", id = topicId }
  end

  local pinId = base:match("pin/(%d+)")
  if pinId then
    return { type = "pin", id = pinId }
  end

  local videoId = base:match("zvideo/(%d+)")
  if videoId then
    return { type = "zvideo", id = videoId }
  end

  local userName = base:match("people/([^/]+)") or base:match("org/([^/]+)")
  if userName then
    return { type = "people", id = userName }
  end

  local columnId = base:match("column/(%d+)")
  if columnId then
    return { type = "column", id = columnId }
  end

  local roundTableId = base:match("roundtable/(%d+)")
  if roundTableId then
    return { type = "roundtable", id = roundTableId }
  end

  local specialId = base:match("special/(%d+)")
  if specialId then
    return { type = "special", id = specialId }
  end

  if base:find("theater") then
    local dramaId = query:match("drama_id=(%d+)")
    if dramaId then
      return { type = "drama", id = dramaId }
    end
  end

  if base:find("signin") then
    return { type = "login" }
  end

  return nil
end

--- 统一跳转函数
---@param type_ string 类型（必填）
---@param params table 业务参数
---@param options table|nil 选项
---   options.sharedElement: view 共享元素视图（可选）
function M.go(type_, params, options)
  if not type_ or type(type_) ~= "string" then
    error("go: a string type is required")
    return
  end

  params = params or {}
  options = options or {}

  local idStr = params.id and tostring(params.id) or nil
  local sharedElement = options.sharedElement
  local routeParams = {}

  if type_ == "answer" then
    routeParams = { answerId = idStr }
   elseif type_ == "question" then
    routeParams = { id = idStr }
   elseif type_ == "collection" then
    routeParams = { id = idStr }
   elseif type_ == "article" or type_ == "pin" or type_ == "zvideo" or type_ == "roundtable" or type_ == "special" or type_ == "drama" then
    local contentType = type_
    -- 跳转到 browser
    type_ = "content"
    if type_ == "zvideo" then contentType = "video" end
    routeParams = { id = idStr, type = contentType }
   elseif type_ == "topic" then
    routeParams = { id = idStr }
   elseif type_ == "people" then
    routeParams = { id = idStr }
   elseif type_ == "column" then
    -- 跳转到 browser
    type_ = "browser"
    routeParams = { url = "https://www.zhihu.com/column/" .. idStr, type = "column" }
   elseif type_ == "browser" then
    routeParams = { url = params.url }
   elseif type_ == "login" then
    Router.go("login")
    return
   else
    error("go: unknown type " .. type_)
  end

  Router.go(type_, routeParams, { sharedElement = sharedElement })
end

--- 直接传入 parse 结果跳转
---@param parseResult table parse 返回的结果
---@param options table|nil 选项
---   options.sharedElement: view 共享元素视图（可选）
function M.goFrom(parseResult, options)
  if not parseResult or not parseResult.type then
    error("goFrom: parseResult is invalid")
    return
  end

  options = options or {}
  M.go(parseResult.type, {
    id = parseResult.id,
    questionId = parseResult.questionId,
    url = parseResult.url
    }, {
    sharedElement = options.sharedElement
  })
end

--- 解析并跳转（一步完成）
---@param url string 知乎链接
---@param options table|nil 选项
---   options.sharedElement: view 共享元素视图（可选）
---   options.skipOnNil: boolean 为true时匹配不到则跳过，为false时跳转浏览器（默认false）
function M.goUrl(url, options)
  options = options or {}

  local result = M.parse(url)

  if result then
    M.goFrom(result, {
      sharedElement = options.sharedElement
    })
   else
    if options.skipOnNil == true then
      return
     else
      Router.go("browser", { url = url })
    end
  end
end

return M