-- pages/base/BasePage.lua
-- 所有页面的基类

import "androidx.activity.EdgeToEdge"
import "androidx.core.view.ViewCompat"
import "androidx.core.view.WindowInsetsCompat"
import "android.view.View"

local BasePage = Extensions.Class()

function BasePage:ctor(name)
  self.name = name or "BasePage"
  self.views = {}
  self.root_view = nil
  self.isDestroyed = false
end

function BasePage:initLayout() end
function BasePage:initViews() end

-- 检测是否存活
function BasePage:isAlive()
  return not self.isDestroyed and self.views ~= nil
end

-- 安全执行回调
function BasePage:runIfAlive(callback)
  if type(callback) ~= "function" then
    error("BasePage:runIfAlive 必须为 function 类型")
  end
  return function(...)
    if self:isAlive() then
      callback(...)
    end
  end
end

-- 初始化设置左右边距
import "androidx.core.view.OnApplyWindowInsetsListener"
ViewCompat.setOnApplyWindowInsetsListener(activity.getWindow().getDecorView(), OnApplyWindowInsetsListener({
  onApplyWindowInsets = function(v, insets)
    local systemBars = WindowInsetsCompat.Type.systemBars()
    local cutout = WindowInsetsCompat.Type.displayCutout()
    local insetValue = insets.getInsets(bit32.bor(systemBars, cutout))
    v.setPadding(insetValue.left, 0, insetValue.right, 0)
    return insets
  end
}))

-- 配置 EdgeToEdge（直接拿当前 insets 设置，不注册监听器）
-- https://github.com/material-components/material-components-android/blob/master/lib/java/com/google/android/material/appbar/CollapsingToolbarLayout.java
-- CollapsingToolbarLayout onWindowInsetChanged 返回 insets.consumeSystemWindowInsets() 会吞掉 insets 所以不注册回调了

local Toolbar = luajava.bindClass("androidx.appcompat.widget.Toolbar")
function BasePage:setupEdgeToEdge(options)
  options = options or {}

  EdgeToEdge.enable(activity)

  local function applyInsets()
    local insets = ViewCompat.getRootWindowInsets(activity.getWindow().getDecorView())
    if not insets then return false end

    local statusBarHeight = insets.getInsets(WindowInsetsCompat.Type.statusBars()).top
    local navBarHeight = insets.getInsets(WindowInsetsCompat.Type.navigationBars()).bottom

    if options.top then
      local list = type(options.top) == "table" and options.top or { options.top }
      for _, v in ipairs(list) do
        if luajava.instanceof(v, Toolbar) then
          error("不支持直接为 Toolbar 设置 top，请尝试改为 Toolbar 的父布局")
         else
          v.setPadding(v.getPaddingLeft(), statusBarHeight, v.getPaddingRight(), v.getPaddingBottom())
        end
      end
    end

    if options.bottom then
      local list = type(options.bottom) == "table" and options.bottom or { options.bottom }
      for _, v in ipairs(list) do
        v.setPadding(v.getPaddingLeft(), v.getPaddingTop(), v.getPaddingRight(), navBarHeight)
      end
    end

    if options.callback then
      options.callback(statusBarHeight, navBarHeight)
    end

    return true
  end

  -- 先尝试一次
  if applyInsets() then return end

  -- insets 还没就绪，给传入的 View 注册一次性监听器
  local targetView = nil
  if options.top then
    local list = type(options.top) == "table" and options.top or { options.top }
    targetView = list[1]
  end
  if not targetView and options.bottom then
    local list = type(options.bottom) == "table" and options.bottom or { options.bottom }
    targetView = list[1]
  end

  if targetView then
    targetView.addOnAttachStateChangeListener(View.OnAttachStateChangeListener({
      onViewAttachedToWindow = function(v)
        applyInsets()
      end,
      onViewDetachedFromWindow = function() end
    }))
  end
end

function BasePage:onCreate(params) end
function BasePage:onResume() end
function BasePage:onPause() end

function BasePage:onDestroy()
  self.isDestroyed = true
  self.views = nil
  self.root_view = nil
end

function BasePage:build()
  if self.root_view ~= nil then
    error(self.name .. ": root_view 已经被设置，禁止重复调用 build()")
  end

  local success, err = xpcall(function()
    self:initLayout()
    self:initViews()
  end, debug.traceback)

  if not success then
    print(string.format("[%s] build 错误: %s", self.name or "BasePage", err))
  end

  return self.root_view
end

function BasePage:findViewById(id)
  return self.views[id]
end

function BasePage:setTitle(title)
  self.views.title.setText(title)
end

BasePage:final("build", "setupEdgeToEdge", "findViewById", "setTitle", "isAlive", "runIfAlive")
BasePage:abstract("initLayout")

return BasePage