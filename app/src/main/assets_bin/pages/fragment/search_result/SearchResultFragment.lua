-- SearchResultFragment.lua

local SimpleListFragment = require("pages.fragment.base.SimpleListFragment")
local SearchResultModel = require("models.search.SearchResultModel")

local SearchResultFragment = Extensions.Class(SimpleListFragment)
SearchResultFragment:chainUp("onDestroy")

function SearchResultFragment:ctor()
  self.model = nil
  self.keyword = nil
  self.searchType = nil
  self.extraId = nil
end

function SearchResultFragment:onCreate(params)
  self.keyword = params.keyword or ""
  self.searchType = params.scope or "general"
  self.extraId = params.extraId
  self.title = string.format("搜索: %s", self.keyword)

  self.model = SearchResultModel(self.keyword, self.searchType, self.extraId)
end

return SearchResultFragment