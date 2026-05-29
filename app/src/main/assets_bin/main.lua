require("initApp")

local function needWelcome()
  local agreements ={"user_agreement", "privacy_policy"}
  for _, name in ipairs(agreements) do
    if Extensions.Config.getNumber(name .. "_agreed") ~= 1 then
      return true
    end
  end

  return false
end

local function launchMain()
  Router.go("main")
end

local function launchWelcome()
  Router.go("welcome")
end

if needWelcome() then
  launchWelcome()
 else
  launchMain()
end