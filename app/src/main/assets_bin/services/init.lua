-- services/init.lua
-- services 导入

local M = {}

M.api = {
  client = require("services.api.client"),
  endpoints = require("services.api.endpoints"),
  zhihu = require("services.api.zhihu"),
  zse96 = require("services.api.zse96"),
}

M.cache = {
  history = require("services.cache.history"),
  search = require("services.cache.search"),
  storage = require("services.cache.storage"),
}

M.permission = require("services.permission")

return M