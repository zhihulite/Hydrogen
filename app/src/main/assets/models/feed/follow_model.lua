-- models/feed/follow_model.lua
-- 关注流/推荐流 - PageToolModel（多 Tab，支持分组展开）

local PageToolModel = require("models.base.page_tool_model")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")

local SafeLinearLayoutManager = luajava.bindClass("com.hydrogen.SafeLinearLayoutManager")

local FollowModel = Extensions.Class(PageToolModel)

local VIEW_NORMAL = 0
local VIEW_GROUP = 1

function FollowModel:ctor()
  self.requestHeadKey = Constants.RequestHeadKeys.APP
  self.needLogin = false
  -- 修改此处请同步修改 SettingFragmrnt ，设置关注默认 Tab 依赖此项。
  self.tabConfigs = {
    { key = "recommend", name = "精选" },
    { key = "timeline", name = "最新" },
    { key = "pin", name = "想法" },
  }
  self.urls = {
    recommend = "https://api.zhihu.com/moments_v3?feed_type=recommend",
    timeline = "https://api.zhihu.com/moments_v3?feed_type=timeline",
    pin = "https://api.zhihu.com/moments_v3?feed_type=pin",
  }
end

-- 实现基类接口 ---------------------------------------------------------

function FollowModel:getTabConfigs()
  return self.tabConfigs
end

function FollowModel:getInitialUrls()
  return self.urls
end

function FollowModel:getRequestHeaders(key)
  if self.requestHeadKey and not Constants.ValidRequestHeadKeys[self.requestHeadKey] then
    print(string.format("requestHeadKey 非法: %q", self.requestHeadKey))
  end
  local headers = {}
  for k, v in pairs(Headers[self.requestHeadKey] or {}) do
    headers[k] = v
  end
  headers["x-moments-ab-param"] = "follow_tab=1"
  return headers
end

-- parseItem
function FollowModel:parseItem(rawItem)
  if not rawItem or not rawItem.type then return nil end

  if rawItem.type == "moments_feed" then
    return self:parseMomentsFeed(rawItem)
   elseif rawItem.type == "feed_item_index_group" then
    return self:parseFeedItemGroup(rawItem)
   elseif rawItem.type == "item_group_card" then
    return self:parseItemGroupCard(rawItem)
   elseif rawItem.type == "moments_recommend_followed_group" then
    return self:parseRecommendGroup(rawItem)
  end
  return nil
end

function FollowModel:parseMomentsFeed(item)
  local source = item.source or {}
  local target = Helpers.ZhihuItem.unwrap(item)
  local actor = source.actor or {}

  local contentType = Helpers.ZhihuItem.normalizeType(target.type)
  local title = ""
  local preview = ""
  local voteupCount = 0
  local commentCount = 0

  if contentType == "answer" then
    title = Helpers.ZhihuItem.titleOf(target)
    preview = target.excerpt or ""
    voteupCount = Helpers.ZhihuItem.voteupOf(target)
    commentCount = target.comment_count or 0
   elseif contentType == "question" then
    title = target.title or ""
    preview = target.excerpt or ""
   elseif contentType == "article" then
    title = target.title or ""
    preview = target.excerpt or ""
    voteupCount = Helpers.ZhihuItem.voteupOf(target)
    commentCount = target.comment_count or 0
   elseif contentType == "pin" then
    title = "一个想法"
    if target.content and #target.content > 0 then
      preview = target.content[1].content or ""
    end
    if preview == "" and target.content and target.content[2] and target.content[2].type == "image" then
      preview = "[图片]"
    end
    voteupCount = Helpers.ZhihuItem.voteupOf(target)
   elseif contentType == "zvideo" then
    title = target.title or ""
    preview = "[视频]"
   elseif contentType == "drama" then
    title = target.title or ""
    preview = "[直播]"
   else
    return nil
  end

  if preview == "" then
    preview = nil
   elseif preview ~= "[视频]" and preview ~= "[直播]" and preview ~= "[图片]" then
    preview = fromHtml((actor.name or "") .. " : " .. preview)
  end

  return {
    id = tostring(target.id),
    type = contentType,
    title = title,
    preview = preview,
    voteupCount = voteupCount,
    commentCount = commentCount,
    actionText = (actor.name or "") .. (source.action_text or ""),
    timeText = Helpers.UI.formatTime(source.action_time),
    avatarUrl = (target.author and target.author.avatar_url) or actor.avatar_url or "",
  }
end

function FollowModel:parseFeedItemGroup(item)
  local actors = item.actors or {}
  local target = Helpers.ZhihuItem.unwrap(item)
  local desc = item.desc or ""

  local contentType = Helpers.ZhihuItem.normalizeType(target.type)
  local title = target.title or ""
  local preview = target.digest or ""

  if contentType == "pin" then
    title = target.excerpt_title or "一个想法"
   elseif contentType == "zvideo" then
    preview = "[视频]"
   elseif contentType ~= "answer" and contentType ~= "question" and contentType ~= "article" then
    return nil
  end

  if preview == "" then
    preview = nil
   elseif preview ~= "[视频]" then
    local name = target.author or (actors[1] and actors[1].name) or ""
    preview = fromHtml(name .. " : " .. preview)
  end

  return {
    id = tostring(target.id),
    type = contentType,
    title = title,
    preview = preview,
    voteupCount = tonumber(desc:match("(%d+) 赞同")) or 0,
    commentCount = tonumber(desc:match("(%d+) 评论")) or 0,
    actionText = (actors[1] and actors[1].name or "") .. (item.action_text or ""),
    timeText = Helpers.UI.formatTime(item.action_time),
    avatarUrl = actors[1] and actors[1].avatar_url or "",
  }
end

function FollowModel:parseItemGroupCard(item)
  local actor = item.actor or {}
  local allSubItems = {}
  local unfoldSize = tonumber(item.unfold_show_size) or 3

  for _, subItem in ipairs(item.data or {}) do
    local parsed
    if subItem.type == "people" then
      parsed = self:parsePeopleItem(subItem)
     else
      parsed = self:parseGroupSubItem(subItem)
    end
    if parsed then
      table.insert(allSubItems, parsed)
    end
  end

  if #allSubItems == 0 then return nil end

  local hasMore = #allSubItems > unfoldSize
  local displayItems = hasMore and { table.unpack(allSubItems, 1, unfoldSize) } or allSubItems

  return {
    id = tostring(item.id),
    type = "group",
    isGroup = true,
    groupText = item.group_text or "",
    subItems = allSubItems,
    displayItems = displayItems,
    hasMore = hasMore,
    avatarUrl = actor.avatar_url or "",
    actionText = (actor.name or "") .. (item.action_text or ""),
    timeText = Helpers.UI.formatTime(item.action_time),
  }
end

function FollowModel:parseGroupSubItem(item)
  local contentType = Helpers.ZhihuItem.normalizeType(item.type)
  return {
    id = tostring(item.id),
    type = contentType,
    title = item.title ~= "" and item.title or "无标题",
    preview = item.digest or "",
    desc = item.desc or "",
  }
end

function FollowModel:parsePeopleItem(item)
  local data = item.card_extend_data
  if not data then return nil end

  return {
    id = data.id or data.url_token or "",
    type = "people",
    name = data.name or "",
    headline = data.headline or "",
    avatarUrl = data.avatar_url or "",
    gender = data.gender,
    isFollowed = data.is_followed or false,
    isFollowing = data.is_following or false,
    followerText = data.description or "",
    url = data.url or "",
    urlToken = data.url_token or "",
  }
end

function FollowModel:parseRecommendGroup(item)
  local list = item.list or {}
  if #list == 0 then return nil end
  local parsed = self:parseMomentsFeed(list[1])
  if parsed then
    parsed.groupText = item.group_text or "为你推荐"
  end
  return parsed
end

-- createAdapter
function FollowModel:createAdapter(dataList)
  return SimpleRecyclerAdapter.new({
    items = dataList,
    getItemViewType = function(position, item)
      if item.isGroup then return VIEW_GROUP end
      return VIEW_NORMAL
    end,
    onCreateView = function(viewType)
      if viewType == VIEW_GROUP then
        return SimpleRecyclerAdapter.inflate(Layouts.cards.follow_group)
       else
        return SimpleRecyclerAdapter.inflate(Layouts.cards.follow)
      end
    end,
    onBind = function(views, item, position, holder, adapter)
      self:bindItem(views, item, position, adapter)
      views.card.onClick = function()
        if item.isGroup then return end
        if item.id and item.type then
          Helpers.ZhihuParser.go(item.type, { id = item.id}, { sharedElement = views.card })
        end
      end
    end,
  })
end

function FollowModel:bindItem(views, item, position, adapter)
  if item.isGroup then
    self:bindGroupItem(views, item, position, adapter)
   else
    self:bindNormalItem(views, item)
  end
end

-- 头像 + action_text/时间行，normal 与 group 两种卡片的头部绑定一致
local function bindHeader(views, item)
  if views.avatar and item.avatarUrl then
    Helpers.Image.load(views.avatar, item.avatarUrl)
  end

  if views.action_text then
    local text = item.actionText or ""
    if item.timeText and item.timeText ~= "" then
      text = text .. " · " .. item.timeText
    end
    views.action_text.text = text
  end
end

function FollowModel:bindNormalItem(views, item)
  if views.group_badge and item.groupText then
    views.group_badge.text = item.groupText
    views.group_badge.visibility = View.VISIBLE
   elseif views.group_badge then
    views.group_badge.visibility = View.GONE
  end

  bindHeader(views, item)

  if views.title then
    views.title.text = item.title or ""
  end

  if views.preview then
    if item.preview then
      views.preview.text = item.preview
      views.preview.visibility = View.VISIBLE
     else
      views.preview.visibility = View.GONE
    end
  end

  if views.like_count then
    views.like_count.text = tostring(item.voteupCount or 0)
  end

  if views.comment_layout then
    local commentCount = tonumber(item.commentCount) or 0
    if commentCount > 0 then
      if views.comment_count then
        views.comment_count.text = tostring(commentCount)
      end
      views.comment_layout.visibility = View.VISIBLE
     else
      views.comment_layout.visibility = View.GONE
    end
  end
end

function FollowModel:bindGroupItem(views, item, position, adapter)
  bindHeader(views, item)

  local isExpanded = item._expanded

  if views.sub_container then
    views.sub_container.visibility = View.VISIBLE
    if isExpanded then
      self:setupSubList(views, item.subItems)
     else
      self:setupSubList(views, item.displayItems)
    end
  end

  if views.expand_btn_layout then
    if item.hasMore and not isExpanded then
      views.expand_btn_layout.visibility = View.VISIBLE
      if views.expand_text then
        views.expand_text.text = item.groupText or "展开"
      end
      if views.expand_icon then
        views.expand_icon.imageBitmap = Helpers.Static.materialIcon("twotone_expand_more")
      end
      views.expand_btn_layout.onClick = function()
        item._expanded = true
        if adapter then
          adapter.notifyItemChanged(position)
        end
      end
     else
      views.expand_btn_layout.visibility = View.GONE
    end
  end
end

-- 分组卡片的子列表。views 表与 holder 一一对应，作 adapter 缓存位：
-- 同一分组 holder 重复 bind 时按 kind 复用 adapter，仅刷新条目数据。
function FollowModel:setupSubList(views, items)
  local recyclerView = views.sub_list
  if not recyclerView or not items then return end

  if not recyclerView.layoutManager then
    recyclerView.layoutManager = SafeLinearLayoutManager(activity)
  end

  local kind = items[1] and items[1].type == "people" and "people" or "normal"

  if views._subKind ~= kind or not views._subAdapter then
    views._subKind = kind
    views._subBuf = {}
    local layoutFile = kind == "people"
    and Layouts.cards.follow_group_people_sub
    or Layouts.cards.follow_group_sub

    local adapter = SimpleRecyclerAdapter.new({
      items = views._subBuf,
      onCreateView = function()
        return SimpleRecyclerAdapter.inflate(layoutFile)
      end,
      onBind = function(v, subItem, position, holder)
        if kind == "people" then
          self:bindPeopleSubItem(v, subItem)
         else
          v.title.text = subItem.title or ""
          local hasPreview = subItem.preview and subItem.preview ~= ""
          v.preview.text = subItem.preview or ""
          v.preview.visibility = hasPreview and View.VISIBLE or View.GONE
          v.desc.text = subItem.desc or ""
        end
        v.card.onClick = function()
          Helpers.ZhihuParser.go(subItem.type, { id = subItem.id }, { sharedElement = v.card })
        end
      end,
    })

    views._subAdapter = adapter
    recyclerView.adapter = adapter
  end

  -- 把当前要显示的条目拷进 adapter 持有的缓冲表，再整体通知刷新
  local buf = views._subBuf
  for i in pairs(buf) do buf[i] = nil end
  for i = 1, #items do
    buf[i] = items[i]
  end
  views._subAdapter.notifyDataSetChanged()
end

function FollowModel:bindPeopleSubItem(views, item)
  Helpers.Image.load(views.people_avatar, item.avatarUrl)
  views.people_name.text = item.name or ""
  views.people_headline.text = item.headline or ""
  views.people_followers.text = item.followerText or ""
end

return FollowModel
