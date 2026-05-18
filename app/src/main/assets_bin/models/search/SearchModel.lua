-- models/search/SearchModel.lua
-- 搜索模块 - BaseModel

local BaseModel = require("models.base.BaseModel")

local SearchModel = Extensions.Class(BaseModel)
SearchModel:chainUp("destroy")

function SearchModel:ctor()
  self.hotItems = {}
  self.suggestItems = {}
end

function SearchModel:loadHotSearch(callback)
  local url = "https://api.zhihu.com/search/top_search"

  self:fetch(url, nil, function(success, response)
    if not success then
      if callback then callback(false) end
      return
    end

    table.clear(self.hotItems)
    if response and response.top_search then
      for _, v in ipairs(response.top_search.words or {}) do
        table.insert(self.hotItems, v.query)
      end
    end

    self:notifyListeners("hotSearchLoaded", self.hotItems)

    if callback then callback(true, self.hotItems) end
  end)
end

function SearchModel:getHotItems()
  return self.hotItems
end

function SearchModel:loadSuggest(keyword, callback)
  local url = "https://www.zhihu.com/api/v4/search/suggest?q=" .. NetWork.urlEncode(keyword)

  self:fetch(url, nil, function(success, response)
    if not success then
      if callback then callback(false) end
      return
    end

    table.clear(self.suggestItems)
    if response and response.suggest then
      for _, v in ipairs(response.suggest) do
        table.insert(self.suggestItems, v.query)
      end
    end

    self:notifyListeners("suggestLoaded", self.suggestItems)

    if callback then callback(true, self.suggestItems) end
  end)
end

function SearchModel:getSuggestItems()
  return self.suggestItems
end

return SearchModel