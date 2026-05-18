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
  local selfRef = self
  local creator = luajava.createProxy("com.hydrogen.LuaFragment$Creator", {
    onCreate = function(savedState)
      selfRef:onCreate(params)
    end,

    onCreateView = function(inflater, container, savedState)
      if not selfRef.fragmentView then
        selfRef.fragmentView = selfRef:build()
        selfRef.container = selfRef.fragmentView
      end
      return selfRef.fragmentView
    end,

    onViewCreated = function(view, savedState)
      selfRef:onViewCreated(view, savedState)
      -- 鼠标点击适配
      view.setOnGenericMotionListener(luajava.createProxy("android.view.View$OnGenericMotionListener",{
        OnGenericMotionListener = function()
          return true
        end
      }))
      if selfRef.onViewCreatedCallback then
        selfRef.onViewCreatedCallback(selfRef.container)
        selfRef.onViewCreatedCallback = nil
      end
    end,

    onResume = function()
      selfRef:onResume()
    end,

    onPause = function()
      selfRef:onPause()
    end,

    onDestroy = function()
      selfRef:onDestroy()
      selfRef:clear()
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
  self.initParams = params
  return self:createFragment(params)
end

--- 获取容器视图（final 方法，子类不应重写）
--- @return View 容器视图，可能为 nil（在 onCreateView 之前）
--- @note 此方法为 final 方法，子类不应重写
function BaseFragment:getContainer()
  return self.container
end

--- 获取 Fragment 对象（final 方法，子类不应重写）
--- @return LuaFragment Fragment 对象
--- @note 此方法为 final 方法，子类不应重写
function BaseFragment:getFragmentObject()
  return self.fragment
end

-- 清理
function BaseFragment:clear()
  self.fragmentView = nil
  self.initParams = nil
  self.fragment = nil
  self.container = nil
  self.onViewCreatedCallback = nil
end

-- 生命周期方法（子类覆盖）
function BaseFragment:onCreate(params) end
function BaseFragment:onViewCreated(view, savedState) end
function BaseFragment:onResume() end
function BaseFragment:onPause() end
function BaseFragment:onDestroy() end

BaseFragment:final(
"createFragment",
"setOnViewCreatedCallback",
"getFragment",
"getContainer",
"getFragmentObject"
)

return BaseFragment