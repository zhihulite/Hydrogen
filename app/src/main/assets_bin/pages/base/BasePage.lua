-- pages/base/BasePage.lua
-- 所有页面的基类

import "androidx.activity.EdgeToEdge"
import "androidx.core.view.ViewCompat"
import "androidx.core.view.WindowInsetsCompat"
import "android.view.View"

local BasePage = Extensions.Class()
-- 标记链式方法（标记会被子类自动继承，子类无需重复调用）
BasePage:chainUp("onDestroy")

function BasePage:ctor(name)
  self.name = name or "BasePage"
  self.views = {}
  self.root_view = nil
  self.isDestroyed = false
  self.edgeToEdgeViews = {} -- 保存 EdgeToEdge 添加的视图，用于销毁时移除
end

function BasePage:initLayout() end
function BasePage:initViews() end

-- 检测是否存活
function BasePage:isAlive()
  return not self.isDestroyed
end

-- 安全执行回调
function BasePage:runIfAlive(callback)
  if type(callback) ~= "function" then
    error("BasePage:runIfAlive 必须为 function 类型")
  end
  return function(...)
    if self:isAlive() then
      return callback(...)
    end
  end
end

local EdgeToEdgeUtils = require("pages.base.EdgeToEdgeUtils")

-- 配置 EdgeToEdge
-- @param options table
--   options.top: View|table 需要适配状态栏的视图
--   options.bottom: View|table 需要适配导航栏的视图
--   options.start: View|table 需要适配左边的视图
--   options["end"]: View|table 需要适配右边的视图
--   options.lazy: 偷懒模式，decorView 自动处理 left/right（默认 true）
--   options.useMargin: 全局是否使用 margin 而非 padding
function BasePage:setupEdgeToEdge(options)
  if not options then
    error("setupEdgeToEdge() 必须传入 options 参数")
  end

  local addedViews = EdgeToEdgeUtils.setup(options)
  if addedViews and #addedViews > 0 then
    for _, view in ipairs(addedViews) do
      table.insert(self.edgeToEdgeViews, view)
    end
  end
end

-- 添加单个 EdgeToEdge 视图
-- @param view 需要适配的视图
-- @param direction 方向: "start", "end", "top", "bottom"
-- @param useMargin 是否使用 margin 而非 padding
function BasePage:addEdgeToEdgeView(view, direction, useMargin)
  if not view then return end
  EdgeToEdgeUtils.add(view, direction, useMargin)
  table.insert(self.edgeToEdgeViews, view)
end

function BasePage:onCreate(params) end
function BasePage:onResume() end
function BasePage:onPause() end

function BasePage:onDestroy()
  -- 销毁时移除所有 EdgeToEdge 添加的视图
  if self.edgeToEdgeViews and #self.edgeToEdgeViews > 0 then
    EdgeToEdgeUtils.remove(self.edgeToEdgeViews)
    self.edgeToEdgeViews = nil
  end

  self.isDestroyed = true
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

BasePage:final("build", "isAlive", "runIfAlive", "setupEdgeToEdge", "addEdgeToEdgeView")
BasePage:abstract("initLayout")

return BasePage