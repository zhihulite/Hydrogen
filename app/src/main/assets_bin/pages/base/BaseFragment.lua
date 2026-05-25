-- pages/base/BaseFragment.lua
local BasePage = require("pages.base.BasePage")

local BaseFragment = Extensions.Class(BasePage)

function BaseFragment:ctor(name)
  self.name = name
  self.initParams = nil
  self.fragmentView = nil
  self.fragment = nil
  self.container = nil
  self.onViewCreatedCallback = nil
end


--- 创建 Fragment 实例（final 方法，子类不应重写）
--- @param params table 创建参数
--- @return LuaFragment Fragment 实例
--- @note 此方法为 final 方法，子类不应重写
function BaseFragment:createFragment(params)
  local creator = luajava.createProxy("com.hydrogen.LuaFragment$Creator", {
    onCreate = function(savedState)
      self:onCreate(params)
    end,

    onCreateView = function(inflater, container, savedState)
      if not self.fragmentView then
        self.fragmentView = self:build()
        self.container = self.fragmentView
      end
      -- 修复点击穿透
      self.fragmentView.setClickable(true)
      -- 鼠标点击适配
      self.fragmentView.setOnGenericMotionListener(luajava.createProxy("android.view.View$OnGenericMotionListener",{
        onGenericMotion = function()
          return false
        end
      }))
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
  })

  self.fragment = luajava.newInstance("com.hydrogen.LuaFragment", creator)
  luajava.clear(creator)
  return self.fragment
end

--- 设置视图创建完成后的回调（final 方法，子类不应重写）
--- @param callback function 回调函数，参数为容器视图
--- @note 此方法为 final 方法，子类不应重写
function BaseFragment:setOnViewCreatedCallback(callback)
  self.onViewCreatedCallback = callback
end

--- 获取 Fragment 实例（final 方法，子类不应重写）
--- @param params table 创建参数，可选，会传递给 onCreate
--- @return LuaFragment Fragment 实例
--- @note 此方法为 final 方法，子类不应重写
function BaseFragment:getFragment(params)
  if self.fragment then
    return self.fragment
  end
  self.initParams = params
  return self:createFragment(params)
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
  self.initParams = nil
  self.fragment = nil
  self.container = nil
  self.onViewCreatedCallback = nil
  self:removeAllBackPressedCallbacks()
end


import "androidx.activity.OnBackPressedCallback"

function BaseFragment:addBackPressedCallback(options)
  if type(options) ~= "table" then
    error("BaseFragment:addBackPressedCallback 需要传入 table 参数")
  end

  local fragment = self.fragment
  local activity = fragment.getActivity()

  local callback = luajava.override(OnBackPressedCallback, {
    handleOnBackPressed = options.handleOnBackPressed,
    handleOnBackStarted = options.onBackStarted,
    handleOnBackProgressed = options.onBackProgressed,
    handleOnBackCancelled = options.onBackCancelled,
  }, options.enabled == nil or options.enabled)

  activity.getOnBackPressedDispatcher().addCallback(fragment, callback)
  return callback
end

function BaseFragment:removeAllBackPressedCallbacks()
  if self.backPressedCallbacks then
    for _, callback in ipairs(self.backPressedCallbacks) do
      callback.remove()
    end
    self.backPressedCallbacks = nil
  end
end

-- 生命周期方法（子类覆盖）
function BaseFragment:onCreate(params) end
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