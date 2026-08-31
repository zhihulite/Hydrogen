-- models/feed/daily_section_list_model.lua
-- 日报专栏列表模型 - PageModel

local DailyBaseModel = require("models.feed.daily_base_model")

local DailySectionListModel = Extensions.Class(DailyBaseModel)

function DailySectionListModel:ctor(sectionId)
  self.sectionId = sectionId
end

function DailySectionListModel:getFirstPageUrl(params)
  self.currentDate = os.date("%Y%m%d")
  return string.format("https://news-at.zhihu.com/api/4/section/%s", self.sectionId)
end

function DailySectionListModel:getNextPageUrl(params)
  if not self.currentDate then return nil end
  return string.format("https://news-at.zhihu.com/api/4/section/%s/before/%s", self.sectionId, self:prevDate(self.currentDate))
end

return DailySectionListModel
