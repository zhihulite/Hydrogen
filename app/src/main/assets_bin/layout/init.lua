-- layout/init.lua
-- 点号路径访问，如 Layouts.pages.home.main

local function loader(prefix)
  return setmetatable({}, {
    __index = function(_, key)
      local full = prefix .. "." .. key
      local ok, mod = pcall(require, full)
      if ok then return mod end
      return loader(full)
    end
  })
end

local M = loader("layout")

return M