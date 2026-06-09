-- models/feed/DailySectionListModel.lua
-- 日报专栏列表模型 - PageModel

local PageModel = require("models.base.PageModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

local DailySectionListModel = Extensions.Class(PageModel)

function DailySectionListModel:ctor(sectionId)
  self.sectionId = sectionId
  self.currentDate = nil
  self.enableLoadMore = true
end

function DailySectionListModel:getFirstPageUrl(params)
  self.currentDate = os.date("%Y%m%d")
  return string.format("https://news-at.zhihu.com/api/4/section/%s", self.sectionId)
end

function DailySectionListModel:getNextPageUrl(params)
  if not self.currentDate then
    return nil
  end

  local year = tonumber(self.currentDate:sub(1, 4))
  local month = tonumber(self.currentDate:sub(5, 6))
  local day = tonumber(self.currentDate:sub(7, 8))
  local time = os.time({year = year, month = month, day = day}) - 86400
  self.currentDate = os.date("%Y%m%d", time)

  return string.format("https://news-at.zhihu.com/api/4/section/%s/before/%s", self.sectionId, self.currentDate)
end

function DailySectionListModel:parseResponse(response, params)
  local items = {}
  local stories = response.stories or {}

  for _, story in ipairs(stories) do
    table.insert(items, {
      id = story.id,
      title = story.title,
      imageUrl = story.images and story.images[1] or "",
      url = story.url,
    })
  end

  return items
end

function DailySectionListModel:createAdapter()
  return SimpleRecyclerAdapter.new({
    items = self.items,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.daily)
    end,
    onBind = function(views, item, position)
      views.title.text = item.title or ""

      if item.imageUrl and item.imageUrl ~= "" then
        Helpers.Image.load(views.image, item.imageUrl)
      end

      views.card.onClick = function()
        Router.go("browser", { url = item.url }, { sharedElement = views.card })
      end
    end,
  })
end

return DailySectionListModel