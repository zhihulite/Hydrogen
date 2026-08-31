-- main.lua
-- 应用入口：按协议签署状态分发到欢迎页或主页

require("init_app")

local function needWelcome()
  for _, agreement in ipairs(Constants.Agreements) do
    if Extensions.Config.getNumber(agreement.name .. "_agreed") ~= 1 then
      return true
    end
  end

  return false
end

local intent = activity.intent
local data = intent.data
local intentDataUrl = data and data.toString() or nil

local function launchMain()
  Router.go("main", intentDataUrl and { intentDataUrl = intentDataUrl } or nil)
end

local function launchWelcome()
  Router.go("welcome", intentDataUrl and { intentDataUrl = intentDataUrl } or nil)
end

if needWelcome() then
  launchWelcome()
 else
  launchMain()
end