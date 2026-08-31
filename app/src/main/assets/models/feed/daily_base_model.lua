-- models/feed/daily_base_model.lua
-- 日报类列表公共基类 - 日期游标分页与 daily 卡片适配器
-- 子类实现 getFirstPageUrl/getNextPageUrl 构造各自的 URL，日期游标推进由基类统一处理

local PageModel = require("models.base.page_model")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
local WebViewPrewarm = luajava.bindClass("org.luajvm.android.engine.WebViewPrewarm")

import "android.view.View"

local DailyBaseModel = Extensions.Class(PageModel)

-- 计算指定日期（YYYYMMDD）前一天
function DailyBaseModel:prevDate(date)
  local t = os.time({
    year = tonumber(date:sub(1, 4)),
    month = tonumber(date:sub(5, 6)),
    day = tonumber(date:sub(7, 8)),
  }) - 86400
  return os.date("%Y%m%d", t)
end

function DailyBaseModel:ctor()
  self.currentDate = nil -- 日期游标（YYYYMMDD），加载更多成功后推进
  self.enableLoadMore = true
  WebViewPrewarm.prewarmNow(activity.applicationContext)
end

function DailyBaseModel:parseResponse(response, params)
  -- 加载更多成功拿到数据时才推进日期，getNextPageUrl 本身保持无副作用
  if params and params.loadMore then
    self.currentDate = self:prevDate(self.currentDate)
  end
  local items = {}
  for _, story in ipairs(response.stories or {}) do
    table.insert(items, {
      id = story.id,
      title = story.title,
      url = story.url or string.format("https://daily.zhihu.com/story/%s", story.id),
      imageUrl = story.images and story.images[1] or "",
    })
  end
  return items
end

function DailyBaseModel:createAdapter()
  return SimpleRecyclerAdapter.new({
    items = self.items,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.daily)
    end,
    onBind = function(views, item, position, holder)
      views.title.text = item.title or ""
      local hasImage = item.imageUrl and item.imageUrl ~= ""
      views.image_container.visibility = hasImage and View.VISIBLE or View.GONE
      if hasImage then
        Helpers.Image.load(views.image, item.imageUrl)
      end
      views.card.onClick = function()
        Router.go("browser", {
          url = item.url,
          dailyId = item.id,
          title = item.title,
          type = "daily",
        }, { sharedElement = views.card })
      end
    end,
  })
end

return DailyBaseModel
