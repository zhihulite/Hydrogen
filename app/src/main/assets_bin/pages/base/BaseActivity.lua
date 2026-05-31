-- pages/base/BaseActivity.lua
-- Activity 基类

local BasePage = require("pages.base.BasePage")

local BaseActivity = Extensions.Class(BasePage, {"BaseActivity"})

--- 设置内容视图（final 方法，子类不应重写）
--- @note 此方法为 final 方法，子类不应重写
function BaseActivity:setContentView()
  activity.ContentView = self.root_view
end

--- 启动 Activity（final 方法，子类不应重写）
--- @param params table 启动参数
--- @note 此方法为 final 方法，子类不应重写
function BaseActivity:start(params)
  self:onCreate(params)
  self:build()
  self:setContentView()
end

--- 关闭 Activity（final 方法，子类不应重写）
--- @note 此方法为 final 方法，子类不应重写
function BaseActivity:finish()
  activity.finish()
end

import "androidx.activity.OnBackPressedCallback"


function BaseActivity:addBackPressedCallback(options)
  if type(options) ~= "table" then
    error("BaseFragment:addBackPressedCallback 需要传入 table 参数")
  end

  local callback = luajava.override(OnBackPressedCallback, {
    handleOnBackPressed = options.handleOnBackPressed,
    handleOnBackStarted = options.onBackStarted,
    handleOnBackProgressed = options.onBackProgressed,
    handleOnBackCancelled = options.onBackCancelled,
  }, options.enabled == nil or options.enabled)

  activity.onBackPressedDispatcher.addCallback(activity, callback)

  if not self.backPressedCallbacks then
    self.backPressedCallbacks = {}
  end
  table.insert(self.backPressedCallbacks, callback)

  return callback
end

function BaseActivity:removeAllBackPressedCallbacks()
  if self.backPressedCallbacks then
    for _, callback in ipairs(self.backPressedCallbacks) do
      callback.remove()
    end
    self.backPressedCallbacks = nil
  end
end


-- 子类可覆盖的生命周期方法
function BaseActivity:onCreate(params) end
function BaseActivity:onResume() end
function BaseActivity:onPause() end
function BaseActivity:onDestroy()
  self:removeAllBackPressedCallbacks()
end
function BaseActivity:onKeyDown(keyCode, event) end
function BaseActivity:onKeyUp(keyCode, event) end
function BaseActivity:onConfigurationChanged(newConfig) end
function BaseActivity:onNewIntent(intent) end

-- final 标记
BaseActivity:final(
"setContentView",
"start",
"finish"
)

return BaseActivity