-- models/feed/HotModel.lua
-- 热榜 - PageModel（一次性加载，不支持分页）

local PageModel = require("models.base.PageModel")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

local HotModel = Extensions.Class(PageModel)
HotModel:chainUp("destroy")

function HotModel:ctor()
  self.requestHeadKey = "defaultHead"
  self.needLogin = false
  self.enableLoadMore = false
end

function HotModel:getFirstPageUrl(params)
  return "https://www.zhihu.com/api/v3/feed/topstory/hot-lists/total?limit=50&mobile=true"
end

function HotModel:parseResponse(response, params)
  local items = {}
  local closeImage = Extensions.Config.getBool(Constants.SharedDataKeys.HOT_CLOSE_IMAGE)
  local closeHeat = Extensions.Config.getBool(Constants.SharedDataKeys.HOT_CLOSE_HOT)

  for i, item in ipairs(response.data or {}) do
    local target = item.target or {}
    local imageUrl = target.image_area and target.image_area.url or ""

    table.insert(items, {
      rank = i,
      title = target.title_area and target.title_area.text or "",
      heat = closeHeat and nil or (target.metrics_area and target.metrics_area.text or ""),
      url = target.link and target.link.url or "",
      imageUrl = closeImage and nil or imageUrl,
      hasImage = not closeImage and #imageUrl > 0,
    })
  end
  return items
end

function HotModel:createAdapter()
  local selfRef = self
  local closeImage = Extensions.Config.getBool(Constants.SharedDataKeys.HOT_CLOSE_IMAGE)
  local closeHeat = Extensions.Config.getBool(Constants.SharedDataKeys.HOT_CLOSE_HOTNESS)

  return SimpleRecyclerAdapter.new({
    items = self.items,
    getItemViewType = function(position, item)
      return 0
    end,
    onCreateView = function(viewType)
      return SimpleRecyclerAdapter.inflate(Layouts.cards.hot)
    end,
    onBind = function(views, item, position, holder)
      views.rank.text = tostring(item.rank)
      views.title.text = item.title or ""
      views.heat_row.Visibility = (closeHeat or not item.heat) and 8 or 0

      if item.heat then
        views.heat.text = item.heat
      end

      -- 图片：关闭图片 或 没有图片 就隐藏
      local hasImage = not closeImage and item.hasImage and item.imageUrl
      views.image_container.Visibility = hasImage and 0 or 8

      if item.imageUrl then
        Helpers.Image.load(views.image, item.imageUrl)
      end

      views.card.onClick = function()
        Helpers.ZhihuParser.goUrl(item.url, { sharedElement = views.card })
      end
    end,
  })
end

return HotModel