-- helpers/zhihu_item.lua
-- 知乎条目字段解析：内层对象提取、类型归一与标题/预览/赞同数/作者的统一兜底取值

local M = {}

-- 类型别名归一表：不同接口对同类内容的 type 命名不同
local TYPE_ALIASES = {
  moments_pin = "pin",
  pin_general = "pin",
  favlist = "collection",
}

-- 依序取第一个非 nil 且非空串的值
local function firstText(...)
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if v ~= nil and v ~= "" then return v end
  end
  return nil
end

-- 依序取第一个非 nil 的值
local function firstValue(...)
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if v ~= nil then return v end
  end
  return nil
end

--- 取条目的内层内容对象
--- @param raw table|nil 原始条目
--- @param key string|nil 优先取值的键（如 "column"）
--- @return table 内层对象，raw 为 nil 时返回空表
function M.unwrap(raw, key)
  raw = raw or {}
  if key and raw[key] then return raw[key] end
  return raw.target or raw.object or raw.collection or raw
end

--- 类型归一：别名映射为统一类型，其余原样返回
--- @param t string|nil 原始 type
--- @return string|nil 归一后的 type
function M.normalizeType(t)
  return t and TYPE_ALIASES[t] or t
end

--- 取条目标题：answer 取所属问题标题；pin 取 excerpt_title/title 兜底"一个想法"；其余取 title/name
--- @param target table|nil 内层内容对象
--- @return string 标题，无值时为空串
function M.titleOf(target)
  target = target or {}
  local contentType = M.normalizeType(target.type)
  if contentType == "answer" then
    return (target.question and target.question.title) or ""
  end
  if contentType == "pin" then
    return firstText(target.excerpt_title, target.title, "一个想法")
  end
  return firstText(target.title, target.name) or ""
end

--- 取条目预览文本并经 fromHtml 反转义；pin 取 content 首段
--- @param target table|nil 内层内容对象
--- @return any|nil 预览文本（Spanned），无值时为 nil
function M.excerptOf(target)
  target = target or {}
  local text
  if M.normalizeType(target.type) == "pin" then
    text = firstText(
    target.content and target.content[1] and target.content[1].content,
    target.excerpt,
    target.excerpt_title
    )
   else
    text = firstText(target.excerpt, target.excerpt_title)
  end
  if not text then return nil end
  return fromHtml(text)
end

--- 取条目赞同数
--- @param target table|nil 内层内容对象
--- @return number 赞同数，无值时为 0
function M.voteupOf(target)
  target = target or {}
  -- reaction.statistics 为嵌套路径，中间层可能缺失，依 and 链短路安全访问
  local reaction = target.reaction
  return firstValue(
  target.reaction_count,
  reaction and reaction.statistics and reaction.statistics.up_vote_count,
  target.voteup_count,
  target.vote_count,
  target.like_count
  ) or 0
end

--- 取作者子表
--- @param author table|nil 原始作者对象
--- @return table|nil 驼峰字段表 { id, name, headline, avatarUrl }，author 为 nil 时返回 nil
function M.authorOf(author)
  if not author then return nil end
  return {
    id = tostring(author.id or ""),
    name = author.name or "",
    headline = author.headline or "",
    avatarUrl = author.avatar_url or "",
  }
end

return M