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
  local intent = activity.getIntent()
  local data = intent.getData()
  local intentDataUrl = data and data.toString() or nil
  Router.go("main", intentDataUrl and { intentDataUrl = intentDataUrl } or nil)
end

local function launchWelcome()
  Router.go("welcome")
end

if needWelcome() then
  launchWelcome()
 else
  launchMain()
end