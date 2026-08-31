-- pages/base/base_fragment.lua
-- Fragment 基类

local BasePage = require("pages.base.base_page")

local LuaFragment = luajava.bindClass("org.luajvm.android.host.LuaFragment")
local LuaFragmentCreator = luajava.bindClass("org.luajvm.android.host.LuaFragment$Creator")

local BaseFragment = Extensions.Class(BasePage)

function BaseFragment:ctor(name)
  -- BasePage:ctor 先执行并已写入默认名，仅显式传入时覆盖
  self.name = name or self.name
  self.fragmentView = nil
  self.fragment = nil
  self.container = nil
  self.onViewCreatedCallback = nil
end


--- 创建 Fragment 实例（final 方法，子类不应重写）
--- @param paramsKey string|table Activity 路径为 Storage 中存储的参数 key，Fragment 路径直接传参数表，经 Router.resolveParams 解析后传给 onCreate
--- @return LuaFragment Fragment 实例
--- @note 此方法为 final 方法，子类不应重写
function BaseFragment:createFragment(paramsKey)
  local params = Router.resolveParams(paramsKey)
  local creator = luajava.createProxy(LuaFragmentCreator, {
    onCreate = function(savedState)
      self:onCreate(params)
    end,

    onCreateView = function(inflater, container, savedState)
      if not self.fragmentView then
        self.fragmentView = self:build()
        self.container = self.fragmentView
      end
      -- 修复点击穿透
      self.fragmentView.clickable = true
      -- 鼠标点击适配
      self.fragmentView.onGenericMotion = function()
        return false
      end
      return self.fragmentView
    end,

    onViewCreated = function(view, savedState)
      self:onViewCreated(view, savedState)
      if self.onViewCreatedCallback then
        self.onViewCreatedCallback(self.container)
        self.onViewCreatedCallback = nil
      end
    end,

    onResume = function()
      self:onResume()
    end,

    onPause = function()
      self:onPause()
    end,

    onDestroy = function()
      self:onDestroy()
    end,

    onConfigurationChanged = function(newConfig)
      self:onConfigurationChanged(newConfig)
    end
  })

  self.fragment = LuaFragment(creator)
  --luajava.clear(creator)
  return self.fragment
end

--- 设置视图创建完成后的回调（final 方法，子类不应重写）
--- @param callback function 回调函数，参数为容器视图
--- @note 此方法为 final 方法，子类不应重写
function BaseFragment:setOnViewCreatedCallback(callback)
  self.onViewCreatedCallback = callback
end

--- 获取 Fragment 实例（final 方法，子类不应重写）
--- @param paramsKey string|table Activity 路径为 Storage 中存储的参数 key，Fragment 路径直接传参数表，经 Router.resolveParams 解析后传给 onCreate，可选，会传递给 onCreate
--- @return LuaFragment Fragment 实例
--- @note 此方法为 final 方法，子类不应重写
function BaseFragment:getFragment(paramsKey)
  if self.fragment then
    return self.fragment
  end
  return self:createFragment(paramsKey)
end

--- 获取容器视图（final 方法，子类不应重写）
--- @return View 容器视图，可能为 nil（在 onCreateView 之前）
--- @note 此方法为 final 方法，子类不应重写
function BaseFragment:getContainer()
  return self.container
end

-- 清理
function BaseFragment:clear()
  self.fragmentView = nil
  self.fragment = nil
  self.container = nil
  self.onViewCreatedCallback = nil
  self:removeAllBackPressedCallbacks()
end

-- 返回键回调以 Fragment 自身为 LifecycleOwner
function BaseFragment:getBackPressedOwner()
  return self.fragment
end

-- 生命周期方法（子类覆盖）
function BaseFragment:onCreate(params) end
function BaseFragment:onConfigurationChanged(newConfig) end
function BaseFragment:onViewCreated(view, savedState) end
function BaseFragment:onResume() end
function BaseFragment:onPause() end
function BaseFragment:onDestroy()
  self:clear()
end

BaseFragment:final(
"createFragment",
"setOnViewCreatedCallback",
"getFragment",
"getContainer"
)

return BaseFragment