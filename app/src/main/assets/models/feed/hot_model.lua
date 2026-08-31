-- models/feed/hot_model.lua
-- 热榜 - PageModel（一次性加载，不支持分页）

local PageModel = require("models.base.page_model")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")

import "android.view.View"

local HotModel = Extensions.Class(PageModel)

function HotModel:ctor()
  self.requestHeadKey = Constants.RequestHeadKeys.DEFAULT_HEAD
  self.needLogin = false
  self.enableLoadMore = false
end

function HotModel:getFirstPageUrl(params)
  return "https://www.zhihu.com/api/v3/feed/topstory/hot-lists/total?limit=50&mobile=true"
end

function HotModel:parseResponse(response, params)
  local items = {}
  local closeImage = Extensions.Config.getBool(Constants.SharedDataKeys.HOT_CLOSE_IMAGE)
  local closeHeat = Extensions.Config.getBool(Constants.SharedDataKeys.HOT_CLOSE_HOTNESS)

  for i, item in ipairs(response.data or {}) do
    local target = item.target or {}
    local imageUrl = target.image_area and target.image_area.url or ""

    local heat, image
    if not closeHeat then heat = target.metrics_area and target.metrics_area.text end
    if not closeImage and imageUrl ~= "" then image = imageUrl end

    table.insert(items, {
      rank = i,
      title = target.title_area and target.title_area.text or "",
      heat = heat,
      url = target.link and target.link.url or "",
      imageUrl = image,
      hasImage = image ~= nil,
    })
  end
  return items
end

function HotModel:createAdapter()
  return SimpleRecyclerAdapter.new({
    items = self.items,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.cards.hot)
    end,
    onBind = function(views, item, position, holder)
      views.rank.text = tostring(item.rank)
      views.title.text = item.title or ""
      views.heat_row.visibility = item.heat and View.VISIBLE or View.GONE

      if item.heat then
        views.heat.text = item.heat
      end

      -- 图片：没有图片就隐藏
      views.image_container.visibility = item.hasImage and View.VISIBLE or View.GONE

      if item.hasImage then
        Helpers.Image.load(views.image, item.imageUrl)
      end

      views.card.onClick = function()
        Helpers.ZhihuParser.goUrl(item.url, { sharedElement = views.card })
      end
    end,
  })
end

return HotModel
