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
function BasePage:setupEdgeToEdge(options)
  local addedViews = EdgeToEdgeUtils.setup(options)
  if addedViews and #addedViews > 0 then
    for _, view in ipairs(addedViews) do
      table.insert(self.edgeToEdgeViews, view)
    end
  end
end

function BasePage:addEdgeToEdgeView(view, direction, useMargin)
  EdgeToEdgeUtils.add(view, direction, useMargin)
  table.insert(self.edgeToEdgeViews, view)
end

function BasePage:onCreate(params) end
function BasePage:onResume() end
function BasePage:onPause() end

function BasePage:onDestroy()
  -- 销毁时移除所有 EdgeToEdge 添加的视图
  if #self.edgeToEdgeViews > 0 then
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