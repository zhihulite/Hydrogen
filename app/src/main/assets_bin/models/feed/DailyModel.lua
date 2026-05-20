-- models/feed/DailyModel.lua
-- 日报 - PageModel（下拉刷新最新，上拉加载前一天）

local PageModel = require("models.base.PageModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

local DailyModel = Extensions.Class(PageModel)
DailyModel:chainUp("destroy")

function DailyModel:ctor()
  self.currentDate = nil
  self.enableLoadMore = true
end

function DailyModel:getFirstPageUrl(params)
  self.currentDate = os.date("%Y%m%d")
  return "https://news-at.zhihu.com/api/4/stories/latest"
end

function DailyModel:getNextPageUrl(params)
  if not self.currentDate then return nil end
  local year = tonumber(self.currentDate:sub(1, 4))
  local month = tonumber(self.currentDate:sub(5, 6))
  local day = tonumber(self.currentDate:sub(7, 8))
  local time = os.time({year = year, month = month, day = day}) - 86400
  self.currentDate = os.date("%Y%m%d", time)
  return string.format("https://news-at.zhihu.com/api/4/stories/before/%s", self.currentDate)
end

function DailyModel:parseResponse(response, params)
  local items = {}
  for _, story in ipairs(response.stories or {}) do
    table.insert(items, {
      id = story.id,
      title = story.title,
      url = story.url,
      imageUrl = story.images and story.images[1] or "",
    })
  end
  return items
end

function DailyModel:createAdapter()
  local selfRef = self
  return SimpleRecyclerAdapter.new({
    items = self.items,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.daily)
    end,
    onBind = function(views, item, position, holder)
      views.title.text = item.title or ""
      if item.imageUrl then
        Helpers.Image.load(views.image, item.imageUrl)
      end
      views.card.onClick = function()
        Router.go("browser", { url = item.url, title = item.title }, { sharedElement = views.card })
      end
    end,
  })
end

return DailyModel