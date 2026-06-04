-- models/feed/FollowModel.lua
-- 关注流/推荐流 - PageToolModel（多 Tab，支持分组展开）

local PageToolModel = require("models.base.PageToolModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

local FollowModel = Extensions.Class(PageToolModel)

local VIEW_NORMAL = 0
local VIEW_GROUP = 1

function FollowModel:ctor()
  self.requestHeadKey = "app"
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

function FollowModel:getHeaders()
  local headers = {}
  for k, v in pairs(Headers[self.requestHeadKey] or {}) do
    headers[k] = v
  end
  headers["x-moments-ab-param"] = "follow_tab=1"
  return headers
end

function FollowModel:formatTime(timestamp)
  if not timestamp then return "" end
  local diff = os.time() - timestamp
  if diff < 60 then return "刚刚"
   elseif diff < 3600 then return math.floor(diff / 60) .. "分钟前"
   elseif diff < 86400 then return math.floor(diff / 3600) .. "小时前"
   elseif diff < 604800 then return math.floor(diff / 86400) .. "天前"
   else return os.date("%Y-%m-%d", timestamp)
  end
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
  local target = item.target or {}
  local actor = source.actor or {}

  local contentType = target.type == "moments_pin" and "pin" or target.type
  local title = ""
  local preview = ""
  local voteupCount = 0
  local commentCount = 0

  if contentType == "answer" then
    title = target.question and target.question.title or ""
    preview = target.excerpt or ""
    voteupCount = target.voteup_count or 0
    commentCount = target.comment_count or 0
   elseif contentType == "question" then
    title = target.title or ""
    preview = target.excerpt or ""
   elseif contentType == "article" then
    title = target.title or ""
    preview = target.excerpt or ""
    voteupCount = target.voteup_count or 0
    commentCount = target.comment_count or 0
   elseif contentType == "pin" then
    title = "一个想法"
    if target.content and #target.content > 0 then
      preview = target.content[1].content or ""
    end
    if preview == "" and target.content and target.content[2] and target.content[2].type == "image" then
      preview = "[图片]"
    end
    voteupCount = target.reaction_count or 0
   elseif contentType == "zvideo" then
    title = target.title or ""
    preview = "[视频]"
   elseif contentType == "drama" then
    title = target.title or ""
    preview = "[直播]"
   else
    return nil
  end

  if preview and preview ~= "" and preview ~= "[视频]" and preview ~= "[直播]" and preview ~= "[图片]" then
    preview = fromHtml((actor.name or "") .. " : " .. preview)
   elseif preview then
    preview = nil
  end

  return {
    id = tostring(target.id),
    type = contentType,
    title = title,
    preview = preview,
    voteupCount = voteupCount,
    commentCount = commentCount,
    actionText = (actor.name or "") .. (source.action_text or ""),
    timeText = self:formatTime(source.action_time),
    avatar = (target.author and target.author.avatar_url) or actor.avatar_url or "",
  }
end

function FollowModel:parseFeedItemGroup(item)
  local actors = item.actors or {}
  local target = item.target or {}
  local desc = item.desc or ""

  local contentType = target.type == "moments_pin" and "pin" or target.type
  local title = target.title or ""
  local preview = target.digest or ""

  if contentType == "pin" then
    title = target.excerpt_title or "一个想法"
   elseif contentType == "zvideo" then
    preview = "[视频]"
   elseif contentType ~= "answer" and contentType ~= "question" and contentType ~= "article" then
    return nil
  end

  if preview and preview ~= "" and preview ~= "[视频]" then
    local name = target.author or (actors[1] and actors[1].name) or ""
    preview = fromHtml(name .. " : " .. preview)
   elseif preview then
    preview = nil
  end

  return {
    id = tostring(target.id),
    type = contentType,
    title = title,
    preview = preview,
    voteupCount = tonumber(desc:match("(%d+) 赞同")) or 0,
    commentCount = tonumber(desc:match("(%d+) 评论")) or 0,
    actionText = (actors[1] and actors[1].name or "") .. (item.action_text or ""),
    timeText = self:formatTime(item.action_time),
    avatar = actors[1] and actors[1].avatar_url or "",
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
    avatar = actor.avatar_url or "",
    actionText = (actor.name or "") .. (item.action_text or ""),
    timeText = self:formatTime(item.action_time),
  }
end

function FollowModel:parseGroupSubItem(item)
  local contentType = item.type == "moments_pin" and "pin" or item.type
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
    avatar = data.avatar_url or "",
    gender = data.gender,
    isFollowed = data.is_followed or false,
    isFollowing = data.is_following or false,
    followerCount = data.description or "",
    url = data.url or "",
    url_token = data.url_token or "",
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
  local adapter
  adapter = SimpleRecyclerAdapter.new({
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
    onBind = function(views, item, position, holder)
      self:bindItem(views, item, position, adapter)
      views.card.onClick = function()
        if item.isGroup then return end
        if item.id and item.type then
          Helpers.ZhihuParser.go(item.type, { id = item.id}, { sharedElement = views.card })
        end
      end
    end,
  })
  return adapter
end

function FollowModel:bindItem(views, item, position, adapter)
  if item.isGroup then
    self:bindGroupItem(views, item, position, adapter)
   else
    self:bindNormalItem(views, item)
  end
end

function FollowModel:bindNormalItem(views, item)
  if views.group_badge and item.groupText then
    views.group_badge.text = item.groupText
    views.group_badge.visibility = View.VISIBLE
   elseif views.group_badge then
    views.group_badge.visibility = View.GONE
  end

  if views.avatar and item.avatar then
    Helpers.Image.load(views.avatar, item.avatar)
  end

  if views.action_text then
    local text = item.actionText or ""
    if item.timeText and item.timeText ~= "" then
      text = text .. " · " .. item.timeText
    end
    views.action_text.text = text
  end

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
  if views.avatar and item.avatar then
    Helpers.Image.load(views.avatar, item.avatar)
  end

  if views.action_text and item.actionText then
    local text = item.actionText
    if item.timeText and item.timeText ~= "" then
      text = text .. " · " .. item.timeText
    end
    views.action_text.text = text
  end

  local isExpanded = item._expanded

  if views.sub_container then
    views.sub_container.visibility = View.VISIBLE
    if isExpanded then
      self:setupSubList(views.sub_list, item.subItems)
     else
      self:setupSubList(views.sub_list, item.displayItems)
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

function FollowModel:setupSubList(recyclerView, items)
  if not recyclerView or not items then return end

  local isPeopleType = items[1] and items[1].type == "people"
  local layoutFile = isPeopleType
  and Layouts.cards.follow_group_people_sub
  or Layouts.cards.follow_group_sub

  local adapter = SimpleRecyclerAdapter.new({
    items = items,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(layoutFile)
    end,
    onBind = function(views, subItem, position, holder)
      if isPeopleType then
        self:bindPeopleSubItem(views, subItem)
       else
        views.title.text = subItem.title or ""
        local hasPreview = subItem.preview and subItem.preview ~= ""
        views.preview.text = subItem.preview or ""
        views.preview.visibility = hasPreview and View.VISIBLE or View.GONE
        views.desc.text = subItem.desc or ""
      end
      views.card.onClick = function()
        Helpers.ZhihuParser.go(subItem.type, { id = subItem.id }, { sharedElement = views.card })
      end
    end,
  })

  recyclerView.adapter = adapter
  recyclerView.layoutManager = LinearLayoutManager(activity)
end

function FollowModel:bindPeopleSubItem(views, item)
  Helpers.Image.load(views.people_avatar, item.avatar)
  views.people_name.text = item.name or ""
  views.people_headline.text = item.headline or ""
  views.people_followers.text = item.followerCount or ""
end

return FollowModel
