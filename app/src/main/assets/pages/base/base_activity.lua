-- pages/base/base_activity.lua
-- Activity 基类

local BasePage = require("pages.base.base_page")

local BaseActivity = Extensions.Class(BasePage, {"BaseActivity"})

--- 设置内容视图（final 方法，子类不应重写）
--- @note 此方法为 final 方法，子类不应重写
function BaseActivity:setContentView()
  activity.ContentView = self.root_view
end

--- 启动 Activity（final 方法，子类不应重写）
--- @param paramsKey string|table Activity 路径为 Storage 中存储的参数 key，Fragment 路径直接传参数表，经 Router.resolveParams 解析后传给 onCreate
--- @note 此方法为 final 方法，子类不应重写
function BaseActivity:start(paramsKey)
  local params = Router.resolveParams(paramsKey)
  self:onCreate(params)
  self:build()
  self:setContentView()
end

--- 关闭 Activity（final 方法，子类不应重写）
--- @note 此方法为 final 方法，子类不应重写
function BaseActivity:finish()
  activity.finish()
end

-- 子类可覆盖的生命周期方法
function BaseActivity:onCreate(params) end
function BaseActivity:onResume() end
function BaseActivity:onPause() end
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