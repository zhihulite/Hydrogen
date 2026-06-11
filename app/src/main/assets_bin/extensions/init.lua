-- extensions/init.lua
-- 语言级别扩展

local M = {}

M.config = require("extensions.config")
M.file = require("extensions.file")
M.download = require("extensions.download")
M.crypto = require("extensions.crypto")
M.class = require("extensions.class")

return M
