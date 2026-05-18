-- pages/base/BaseActivity.lua
-- Activity 基类

local BasePage = require("pages.base.BasePage")

local BaseActivity = Extensions.Class(BasePage, {"BaseActivity"})
BaseActivity:chainUp("onDestroy")

--- 设置内容视图（final 方法，子类不应重写）
--- @note 此方法为 final 方法，子类不应重写
function BaseActivity:setContentView()
  activity.setContentView(self.root_view)
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

-- 子类可覆盖的生命周期方法
function BaseActivity:onCreate(params) end
function BaseActivity:onResume() end
function BaseActivity:onPause() end
function BaseActivity:onDestroy() end
function BaseActivity:onBackPressed() end
function BaseActivity:onKeyDown(keyCode, event) end
function BaseActivity:onKeyUp(keyCode, event) end
function BaseActivity:onConfigurationChanged(newConfig) end
function BaseActivity:onActivityResult(requestCode, resultCode, data) end

-- final 标记
BaseActivity:final(
"setContentView",
"start",
"finish"
)

return BaseActivity