-- models/feed/daily_model.lua
-- 日报 - PageModel（下拉刷新最新，上拉加载前一天）

local DailyBaseModel = require("models.feed.daily_base_model")

local DailyModel = Extensions.Class(DailyBaseModel)

function DailyModel:getFirstPageUrl(params)
  self.currentDate = os.date("%Y%m%d")
  return "https://news-at.zhihu.com/api/4/stories/latest"
end

function DailyModel:getNextPageUrl(params)
  if not self.currentDate then return nil end
  return string.format("https://news-at.zhihu.com/api/4/stories/before/%s", self:prevDate(self.currentDate))
end

return DailyModel
