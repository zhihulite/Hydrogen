-- models/feed/FollowContentModel.lua
-- 关注内容（问题/收藏夹/话题/专栏/用户等）- PageToolModel，多 Tab

local PageToolModel = require("models.base.PageToolModel")
local SimpleAdapter = require("components.adapter.SimpleRecyclerAdapter")

local FollowContentModel = Extensions.Class(PageToolModel)
FollowContentModel:chainUp("destroy")

function FollowContentModel:ctor(userId)
  self.requestHeadKey = "app"
  self.needLogin = true
  self.userId = userId or Extensions.Config.get(Constants.SharedDataKeys.USER_ID)
  self.tabConfigs = {
    { name = "问题", key = "questions" },
    { name = "收藏夹", key = "collections" },
    { name = "话题", key = "topics" },
    { name = "专栏", key = "columns" },
    -- 可能需要其他布局，不搞了
    -- { name = "用户", key = "followees" },
    { name = "专题", key = "specials" },
    { name = "圆桌", key = "roundtables" },
  }
end

function FollowContentModel:setUserId(userId)
  self.userId = userId
end

function FollowContentModel:getTabConfigs()
  return self.tabConfigs
end

function FollowContentModel:getInitialUrls()
  if not self.userId then return {} end
  local urls = {}
  for _, tab in ipairs(self.tabConfigs) do
    urls[tab.key] = self:getUrlForTab(tab.key)
  end
  return urls
end

function FollowContentModel:getUrlForTab(key)
  if not self.userId then return "" end
  if key == "specials" then
    return "https://api.zhihu.com/people/" .. self.userId .. "/following_news_specials?limit=20"
  end
  return "https://api.zhihu.com/people/" .. self.userId .. "/following_" .. key .. "?limit=20"
end

function FollowContentModel:parseItem(rawItem, key)
  if key == "questions" then
    return self:parseQuestion(rawItem)
   elseif key == "collections" then
    return self:parseCollection(rawItem)
   elseif key == "topics" then
    return self:parseTopic(rawItem)
   elseif key == "columns" then
    return self:parseColumn(rawItem)
   elseif key == "specials" then
    return self:parseSpecial(rawItem)
   elseif key == "roundtables" then
    return self:parseRoundtable(rawItem)
  end
  return nil
end

function FollowContentModel:parseQuestion(item)
  return {
    id = tostring(item.id),
    type = "question",
    title = item.title,
    bottomText = string.format("%d个回答 · %d个关注", item.answer_count or 0, item.follower_count or 0),
  }
end

function FollowContentModel:parseCollection(item)
  return {
    id = tostring(item.id),
    type = "collection",
    title = item.title,
    preview = "由 " .. (item.creator and item.creator.name or "") .. " 创建",
    bottomText = string.format("%d人关注", item.follower_count or 0),
    avatarUrl = item.creator and item.creator.avatar_url,
  }
end

function FollowContentModel:parseTopic(item)
  return {
    id = tostring(item.id),
    type = "topic",
    title = item.name,
    preview = item.excerpt or "无介绍",
  }
end

function FollowContentModel:parseColumn(item)
  return {
    id = tostring(item.id),
    type = "column",
    title = item.title,
    preview = item.description or "无介绍",
    bottomText = string.format("%d篇内容 · %d个赞同", item.items_count or 0, item.voteup_count or 0),
  }
end

function FollowContentModel:parseSpecial(item)
  local id = item.url and item.url:match("special/(.+)") or ""
  return {
    id = tostring(id),
    type = "special",
    title = item.title,
    preview = item.subtitle and item.subtitle.content or "无介绍",
    bottomText = item.footline and item.footline.content or "",
  }
end

function FollowContentModel:parseRoundtable(item)
  local id = item.url and item.url:match("roundtable/(.+)") or ""
  return {
    id = tostring(id),
    type = "roundtable",
    title = item.title,
    preview = item.subtitle and item.subtitle.content or "无介绍",
    bottomText = item.footline and item.footline.content or "",
  }
end

function FollowContentModel:createAdapter(dataList)
  local selfRef = self

  return SimpleAdapter.new({
    items = dataList,
    getItemViewType = function(position, item)
      return 0
    end,
    onCreateView = function(viewType)
      return SimpleAdapter.inflate(Layouts.cards.basic)
    end,
    onBind = function(views, item, position, holder)
      views.title.text = item.title or ""

      views.preview.text = item.preview or ""
      views.preview.setVisibility(item.preview and View.VISIBLE or View.GONE)

      views.bottom_text.text = item.bottomText or ""
      views.bottom_text.setVisibility(item.bottomText and View.VISIBLE or View.GONE)

      views.card.onClick = function()
        Helpers.ZhihuParser.go(item.type, { id = item.id }, { sharedElement = views.card })
      end
    end,
  })
end

return FollowContentModel