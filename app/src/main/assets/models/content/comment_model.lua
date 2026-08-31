-- models/content/comment_model.lua
-- 评论列表 - PageToolModel（支持分页、URL 点击、表情包）

local PageToolModel = require("models.base.page_tool_model")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")

import "android.text.SpannableStringBuilder"
import "android.text.Spanned"
import "android.text.style.URLSpan"
import "android.text.style.ImageSpan"
import "android.text.method.LinkMovementMethod"
import "android.text.method.ArrowKeyMovementMethod"
import "java.util.regex.Pattern"

local SafeLinearLayoutManager = luajava.bindClass("com.hydrogen.SafeLinearLayoutManager")


local MentionSpan = require("components.span.mention_span")
local EmojiSpan = require("components.span.emoji_span")
local LinkSpan = require("components.span.link_span")
local linkMovementMethodInstance = LinkMovementMethod.instance
local arrowKeyMovementMethodInstance = ArrowKeyMovementMethod.instance

-- 表情包 [表情名] 的匹配正则，模块加载时编译一次
local EMOJI_PATTERN = Pattern.compile("\\[([^\\s\\[\\]]{1,10})\\]")

local CommentModel = Extensions.Class(PageToolModel)

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
  self.requestHeadKey = Constants.RequestHeadKeys.DEFAULT_HEAD
  self.needLogin = false
  self.expandedGroups = {}

  -- 是否为子评论：存在父类型且与当前类型不同
  local isSubComment = self.parentContentType
  and self.parentContentType ~= self.contentType

  if isSubComment then
    self.orderBy = "ts"
  end
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
    local url = span.URL
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
  local matcher = EMOJI_PATTERN.matcher(tostring(spannable))
  while matcher.find() do
    local emojiName = matcher.group(1)
    local startPos = matcher.start()
    local endPos = matcher["end"]()
    -- 检查是否已有 Span（避免重复替换）
    local existing = spannable.getSpans(startPos, endPos, ImageSpan)
    if not existing or #existing == 0 then
      -- EmojiSpan.new 找不到同名位图时返回 nil
      local emojiSpan = EmojiSpan.new(emojiName, 18)
      if emojiSpan then
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

  local commentTime = Helpers.UI.formatTime(rawItem.created_time)
  local commentBottom = commentTime
  local comment_tag = rawItem.comment_tag and rawItem.comment_tag[1]
  if comment_tag and comment_tag.type == "ip_info" then
    commentBottom = commentTime .. " · ".. comment_tag.text
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
    commentBottom = commentBottom,
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

-- 绑定父评论卡片与子评论行的公共部分：文本、头像、图片、点赞、卡片点击
-- adapter 用于点赞成功后按 position 重绘该行，selectable 表示 comment_content 可选中文本
function CommentModel:bindCommentViews(views, item, position, adapter, selectable)
  views.author_name.text = item.title or ""
  views.comment_bottom.text = item.commentBottom or ""
  views.comment_content.text = item.content or ""
  views.like_count.text = tostring(item.likeCount)
  Helpers.Image.load(views.avatar, item.avatarUrl)

  -- movementMethod 随 holder 复用会留在上一条评论的状态：可选中文本的行要回到
  -- ArrowKeyMovementMethod 才能长按选择，其余行必须清空，装着 movementMethod 的
  -- TextView 是 clickable 的，会吞掉卡片点击
  if item.hasUrl then
    views.comment_content.movementMethod = linkMovementMethodInstance
   elseif selectable then
    views.comment_content.movementMethod = arrowKeyMovementMethodInstance
   else
    views.comment_content.setMovementMethod(nil)
  end

  if item.hasImage then
    views.comment_image.visibility = View.VISIBLE
    views.comment_image.onClick = function()
      Router.go("image", { data = { item.imageUrl }, index = 0})
    end
    local w, h = calcImageSize(item.imageWidth, item.imageHeight)
    Helpers.Image.load(views.comment_image, item.imageUrl, {
      size = { width = w, height = h },
      centerCrop = true
    })
   else
    views.comment_image.visibility = View.GONE
  end

  self:updateLikeIcon(views.like_icon, item.isLiked)
  views.like_layout.onClick = function()
    self:likeComment(item.id, not item.isLiked, function(success)
      if success then
        item.isLiked = not item.isLiked
        item.likeCount = item.likeCount + (item.isLiked and 1 or -1)
        -- 请求返回时 views 可能已绑到别的评论，按位置重绘由 onBind 重新取数据
        adapter.notifyItemChanged(position)
      end
    end)
  end

  views.card.onClick = function()
    self:notifyListeners("commentClick", item, position)
  end
  views.card.onLongClick = function()
    self:notifyListeners("commentLongClick", item, position, views.card)
    return true
  end
end

function CommentModel:createAdapter(dataList)
  return SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.comment)
    end,
    onBind = function(views, item, position, holder, adapter)
      self:bindCommentViews(views, item, position, adapter, true)

      views.comment_count.text = tostring(item.childCount)
      views.reply_layout.visibility = View.VISIBLE

      self:setupChildRecycler(views.child_recycler, item)

      if item.childCount > #(item.childComments or {}) then
        views.more_replies.text = string.format("查看全部%d条回复", item.childCount)
        views.more_replies.visibility = View.VISIBLE
        views.more_replies.onClick = function()
          if self.contentType == "comment" then
            tip("当前已在当前回复中")
            return
          end
          self:notifyListeners("moreCommentsClick", item.id)
        end
       else
        views.more_replies.visibility = View.GONE
      end
    end
  })
end

function CommentModel:setupChildRecycler(childRecycler, item)
  if not item.childComments or #item.childComments == 0 then
    childRecycler.visibility = View.GONE
    return
  end

  childRecycler.visibility = View.VISIBLE

  if not childRecycler.layoutManager then
    childRecycler.layoutManager = SafeLinearLayoutManager(activity)
  end

  if not item._childAdapter then
    item._childAdapter = SimpleRecyclerAdapter.new({
      items = item.childComments,
      onCreateView = function()
        return SimpleRecyclerAdapter.inflate(Layouts.cards.comment_children)
      end,
      onBind = function(views, childItem, position, holder, adapter)
        self:bindCommentViews(views, childItem, position, adapter, false)
      end,
    })
  end

  -- 适配器缓存在 item 上只建一次；swapAdapter 第二个参数为 false 时保留 RecyclerView
  -- 的回收池，子评论行不必每次父卡片 bind 都重新 loadlayout
  childRecycler.swapAdapter(item._childAdapter, false)
end

function CommentModel:updateLikeIcon(iconView, isLiked)
  local iconName = isLiked and "twotone_favorite" or "outline_favorite_border"
  iconView.imageBitmap = Helpers.Static.materialIcon(iconName)
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