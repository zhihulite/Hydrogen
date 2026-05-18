-- models/content/CommentModel.lua
-- 评论列表 - PageToolModel（支持分页、URL 点击、表情包）

local PageToolModel = require("models.base.PageToolModel")
local SimpleAdapter = require("components.adapter.SimpleRecyclerAdapter")

import "android.text.SpannableStringBuilder"
import "android.text.style.URLSpan"
import "android.text.style.ImageSpan"
import "android.text.Spannable"
import "android.graphics.Bitmap"
import "android.graphics.drawable.BitmapDrawable"
import "java.util.regex.Pattern"
import "android.text.style.ClickableSpan"

import "com.bumptech.glide.Glide"
import "com.bumptech.glide.request.RequestOptions"
import "com.bumptech.glide.load.engine.DiskCacheStrategy"
import "com.bumptech.glide.request.target.SimpleTarget"
import "com.bumptech.glide.request.transition.Transition"
import "android.graphics.drawable.Drawable"
import "android.text.method.LinkMovementMethod"
import "java.util.regex.Pattern"
import "android.text.SpannableStringBuilder"
import "android.text.Spanned"
import "android.text.style.ForegroundColorSpan"
import "android.text.style.ClickableSpan"


local MentionSpan = require("components.span.MentionSpan")
local EmojiSpan = require("components.span.EmojiSpan")
local LinkSpan = require("components.span.LinkSpan")
local linkMovementMethodInstance = LinkMovementMethod.getInstance()

local CommentModel = Extensions.Class(PageToolModel)
CommentModel:chainUp("destroy")

local pattern_cache = {}
local emoji_list_cache = nil -- 表情名列表缓存

-- 创建可点击的 URL Span
local function create_clickable_span(url)
  return luajava.override(ClickableSpan, {
    onClick = function(widge,t)
      Helpers.UI.openUrl(url)
    end
  })
end

-- 获取表情名列表（带缓存）
local function get_emoji_list()
  if not emoji_list_cache then
    emoji_list_cache = Helpers.Static.zemojiList()
  end
  return emoji_list_cache
end

-- 在 Spannable 中用正则匹配并替换为 Drawable
local function spannable_image(spannable, pattern_str, drawable, flags)
  local pattern = pattern_cache[pattern_str]
  if not pattern then
    pattern = Pattern.compile(pattern_str)
    pattern_cache[pattern_str] = pattern
  end

  local text = tostring(spannable)
  local matcher = pattern.matcher(text)

  while matcher.find() do
    local start_pos = matcher.start()
    local end_pos = matcher["end"]()
    if drawable then
      spannable.setSpan(ImageSpan(drawable), start_pos, end_pos,flags or Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
    end
  end
end

-- 手工创建表情 Drawable（按 sp 缩放，带缓存）
local emoji_drawable_cache = {}
local function get_emoji_drawable(name)
  local cached = emoji_drawable_cache[name]
  if cached then return cached end

  local bitmap = Helpers.Static.zemoji(name)
  if not bitmap then return nil end

  local sizePx = sp2px(20) -- 想调大小只改这里
  local scaled = Bitmap.createScaledBitmap(bitmap, sizePx, sizePx, true)
  local d = BitmapDrawable(activity.getResources(), scaled)
  d.setBounds(0, 0, sizePx, sizePx)
  emoji_drawable_cache[name] = d
  return d
end

local function calcImageSize(w, h)
  if not w or not h or w <= 0 or h <= 0 then return 0, 0 end

  if h > w then
    -- 竖图（高度大于宽度）
    return dp2px(100), dp2px(200)
   elseif w > h then
    -- 横图（宽度大于高度）
    return dp2px(200), dp2px(100)
   else
    -- 正方形（宽高相等）
    return dp2px(200), dp2px(200)
  end
end


function CommentModel:ctor(contentId, contentType, parentContentType)
  self.contentId = tostring(contentId)
  self.contentType = contentType
  self.parentContentType = parentContentType
  self.orderBy = "score"
  self.totalCount = 0
  self.requestHeadKey = "defaultHead"
  self.needLogin = false
  self.expandedGroups = {}
end

function CommentModel:getInitialUrl()
  if self.contentType == "comment" then
    return string.format(
    "https://api.zhihu.com/comment_v5/comment/%s/child_comment?order_by=%s&limit=20",
    self.contentId, self.orderBy
    )
   else
    return string.format(
    "https://api.zhihu.com/comment_v5/%ss/%s/root_comment?order_by=%s&limit=20",
    self.contentType, self.contentId, self.orderBy
    )
  end
end

function CommentModel:formatContent(content)
  if not content or content == "" then
    return SpannableStringBuilder(""), nil, 0, 0
  end

  local img_url = nil
  local img_width = 0
  local img_height = 0

  -- 提取图片信息（查看图片/动图标签）
  local a_start, a_end = content:find('<a[^>]*>查看[^<]+</a>')
  if a_start then
    local a_tag = content:sub(a_start, a_end)
    img_url = a_tag:match('href="([^"]+)"')
    local w_str = a_tag:match('data%-width="(%d+)"')
    if w_str then img_width = tonumber(w_str) end
    local h_str = a_tag:match('data%-height="(%d+)"')
    if h_str then img_height = tonumber(h_str) end
    content = content:sub(1, a_start - 1) .. content:sub(a_end + 1)
  end

  -- 先用 Html.fromHtml 解析 HTML，生成带 URLSpan 和 ImageSpan 的 Spannable
  local spannable = SpannableStringBuilder(fromHtml(content))

  -- 1. 处理 @提及 和 链接：将 URLSpan 替换为对应的自定义 Span
  local urlSpans = luajava.astable(spannable.getSpans(0, spannable.length(), URLSpan))
  for _, span in ipairs(urlSpans) do
    local url = span.getURL()
    local start = spannable.getSpanStart(span)
    local endPos = spannable.getSpanEnd(span)
    local displayText = tostring(spannable.subSequence(start, endPos))
    spannable.removeSpan(span)

    -- 判断是否是 @提及（以 /people/ 开头）
    if url:match("/people/") then
      local userId = url:match("/people/([^?/]+)")
      if userId then
        local userName = displayText:match("^@(.+)") or displayText
        local mentionSpan = MentionSpan.new(userId, userName)
        mentionSpan.setSpan(spannable, start, endPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
       else
        -- 降级为普通链接
        local linkSpan = LinkSpan.new(url, displayText, nil)
        linkSpan.setSpan(spannable, start, endPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      end
     else
      -- 普通链接
      local linkSpan = LinkSpan.new(url, displayText, nil)
      linkSpan.setSpan(spannable, start, endPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
    end
  end

  -- 2. 处理表情包 [表情名]：使用 Java 正则匹配，替换为 EmojiSpan
  local emojiPattern = Pattern.compile("\\[([^\\s\\[\\]]{1,10})\\]")
  local matcher = emojiPattern.matcher(tostring(spannable))
  while matcher.find() do
    local emojiName = matcher.group(1)
    local startPos = matcher.start()
    local endPos = matcher["end"]()
    -- 检查是否已有 Span（避免重复替换）
    local existing = spannable.getSpans(startPos, endPos, ImageSpan)
    if not existing or #existing == 0 then
      if Helpers.Static.zemoji(emojiName) then
        local emojiSpan = EmojiSpan.new(emojiName, 18)
        emojiSpan.setSpan(spannable, startPos, endPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
      end
    end
  end

  return spannable, img_url, img_width, img_height
end


function CommentModel:parseItem(rawItem)
  local author = rawItem.author or {}
  local content = rawItem.content or ""
  content = content:gsub("</p>+$", ""):gsub("^<p>", "")

  local name = author.name or ""

  if rawItem.author_tag and rawItem.author_tag[1] then
    name = name .. "「" .. rawItem.author_tag[1].text .. "」"
  end

  if rawItem.reply_to_author then
    name = name .. " -> " .. rawItem.reply_to_author.name
    if rawItem.reply_author_tag and rawItem.reply_author_tag[1] then
      name = name .. "「" .. rawItem.reply_author_tag[1].text .. "」"
    end
  end

  -- 接收 formatContent 返回的图片信息
  local formatted_content, img_url, img_width, img_height = self:formatContent(content)

  local childComments = {}
  for _, child in ipairs(rawItem.child_comments or {}) do
    local childData = self:parseItem(child)
    if childData then
      table.insert(childComments, childData)
    end
  end

  return {
    id = tostring(rawItem.id),
    type = "comment",
    authorId = tostring(author.id),
    author = author,
    title = name,
    content = formatted_content,
    imageUrl = img_url,
    imageWidth = img_width or 0,
    imageHeight = img_height or 0,
    hasImage = img_url ~= nil,
    avatarUrl = author.avatar_url,
    likeCount = rawItem.like_count or 0,
    time = "",
    childCount = rawItem.child_comment_count or 0,
    childNextOffset = rawItem.child_comment_next_offset,
    childComments = childComments,
    isAuthor = rawItem.is_author or false,
    isLiked = rawItem.liked or false,
    isDisliked = rawItem.disliked or false,
    canDelete = rawItem.can_delete or false,
    hasUrl = content:find("http") ~= nil,
  }
end

function CommentModel:createAdapter(dataList)
  local selfRef = self

  return SimpleAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleAdapter.inflate(Layouts.cards.comment)
    end,
    onBind = function(views, item, position, holder)

      views.author_name.text = item.title or ""
      views.comment_time.text = item.time or ""
      views.comment_content.text = item.content or ""
      views.like_count.text = tostring(item.likeCount)
      Helpers.Image.load(views.avatar, item.avatarUrl)

      if item.hasImage then
        views.comment_image.setVisibility(View.VISIBLE)

        views.comment_image.onClick = function()
          Helpers.UI.showImage(item.imageUrl)
        end
        local w,h = calcImageSize(item.imageWidth, item.imageHeight)
        Helpers.Image.load(views.comment_image, item.imageUrl, {
          size = { width = w, height = h },
          centerCrop = true
        })
       else
        views.comment_image.setVisibility(View.GONE)
      end

      if item.hasUrl then
        views.comment_content.setMovementMethod(linkMovementMethodInstance)
      end

      if item.childCount > 0 then
        views.comment_count.text = tostring(item.childCount)
        views.reply_layout.setVisibility(View.VISIBLE)
       else
        views.reply_layout.setVisibility(View.VISIBLE)
        views.comment_count.text = "0"
      end

      selfRef:setupChildRecycler(views.child_recycler, item)

      if item.childCount > #(item.childComments or {}) then
        views.more_replies.text = string.format("查看全部%d条回复", item.childCount)
        views.more_replies.setVisibility(View.VISIBLE)
        views.more_replies.onClick = function()
          if selfRef.contentType == "comment" then
            tip("当前已在当前回复中")
            return
          end
          selfRef:notifyListeners("showMoreComments", item.id, item.childNextOffset)
        end
       else
        views.more_replies.setVisibility(View.GONE)
      end

      selfRef:updateLikeIcon(views.like_icon, item.isLiked)
      views.like_layout.onClick = function()
        selfRef:likeComment(item.id, not item.isLiked, function(success)
          if success then
            item.isLiked = not item.isLiked
            item.likeCount = item.likeCount + (item.isLiked and 1 or -1)
            views.like_count.text = tostring(item.likeCount)
            selfRef:updateLikeIcon(views.like_icon, item.isLiked)
          end
        end)
      end

      views.card.onClick = function()
        selfRef:notifyListeners("commentClick", item, position)
      end
      views.card.onLongClick = function()
        selfRef:notifyListeners("commentLongClick", item, position, views.card)
        return true
      end
    end
  })
end

function CommentModel:setupChildRecycler(childRecycler, item)
  if not item.childComments or #item.childComments == 0 then
    childRecycler.setVisibility(View.GONE)
    return
  end

  childRecycler.setVisibility(View.VISIBLE)

  if not childRecycler.getLayoutManager() then
    childRecycler.setLayoutManager(
    luajava.bindClass("androidx.recyclerview.widget.LinearLayoutManager")(activity)
    )
  end

  local selfRef = self
  local adapter = SimpleAdapter.new({
    items = item.childComments,
    onCreateView = function()
      return SimpleAdapter.inflate(Layouts.cards.comment_children)
    end,
    onBind = function(views, childItem, position, holder)
      views.author_name.text = childItem.title or ""
      views.comment_content.text = childItem.content or ""

      if childItem.hasUrl then
        views.comment_content.setMovementMethod(linkMovementMethodInstance)
      end

      views.like_count.text = tostring(childItem.likeCount)
      Helpers.Image.load(views.avatar, childItem.avatarUrl)

      -- 子评论点赞
      selfRef:updateLikeIcon(views.like_icon, childItem.isLiked)
      views.like_layout.onClick = function()
        selfRef:likeComment(childItem.id, not childItem.isLiked, function(success)
          if success then
            childItem.isLiked = not childItem.isLiked
            childItem.likeCount = childItem.likeCount + (childItem.isLiked and 1 or -1)
            views.like_count.text = tostring(childItem.likeCount)
            selfRef:updateLikeIcon(views.like_icon, childItem.isLiked)
          end
        end)
      end

      if childItem.hasImage then
        views.comment_image.setVisibility(View.VISIBLE)
        views.comment_image.onClick = function()
          Helpers.UI.showImage(childItem.imageUrl)
        end
        local w, h = calcImageSize(childItem.imageWidth, childItem.imageHeight)
        Helpers.Image.load(views.comment_image, childItem.imageUrl, {
          size = { width = w, height = h },
          centerCrop = true
        })
       else
        views.comment_image.setVisibility(View.GONE)
      end

      views.card.onClick = function()
        selfRef:notifyListeners("commentClick", childItem, position)
      end
      views.card.onLongClick = function()
        selfRef:notifyListeners("commentLongClick", childItem, position, views.card)
        return true
      end

    end,
  })

  childRecycler.setAdapter(adapter)
end

function CommentModel:updateLikeIcon(iconView, isLiked)
  local iconName = isLiked and "twotone_favorite" or "outline_favorite_border"
  iconView.setImageBitmap(Helpers.Static.materialIcon(iconName))
end

function CommentModel:likeComment(commentId, isLike, callback)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  local url = "https://api.zhihu.com/comment_v5/comment/" .. commentId .. "/reaction/like"
  if isLike then
    self:put(url, "", nil, callback)
   else
    self:delete(url, nil, callback)
  end
end

function CommentModel:dislikeComment(commentId, isDislike, callback)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  local url = "https://api.zhihu.com/comment_v5/comment/" .. commentId .. "/reaction/dislike"
  if isDislike then
    self:put(url, "", nil, callback)
   else
    self:delete(url, nil, callback)
  end
end


function CommentModel:setOrderBy(orderBy)
  self.orderBy = orderBy
  self:refresh()
end

function CommentModel:onFirstLoad(data, dataList)
  if data and data.counts then
    self.totalCount = data.counts.total_counts or 0
    self:notifyListeners("totalCountChanged", self.totalCount)
  end

  if self.contentType == "comment" and data and data.root then
    local parentComment = self:parseItem(data.root)
    if parentComment then
      table.insert(dataList, 1, parentComment)
    end
  end
end

function CommentModel:deleteComment(commentId, callback)
  local url = "https://www.zhihu.com/api/v4/comment_v5/comment/" .. commentId
  self:delete(url, nil, function(success, data)
    if callback then callback(success, data) end
  end)
end

function CommentModel:destroy()
  self.expandedGroups = nil
end

return CommentModel