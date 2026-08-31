-- pages/base/base_page.lua
-- 所有页面的基类

import "androidx.activity.OnBackPressedCallback"
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

-- 返回键回调挂载的 LifecycleOwner，子类可覆盖
function BasePage:getBackPressedOwner()
  return activity
end

--- 注册返回键回调
--- @param options table handleOnBackPressed / onBackStarted / onBackProgressed / onBackCancelled / enabled（默认 true）
--- @return OnBackPressedCallback 注册后的回调实例
function BasePage:addBackPressedCallback(options)
  if type(options) ~= "table" then
    error(self.name .. ":addBackPressedCallback 需要传入 table 参数")
  end

  local callback = luajava.override(OnBackPressedCallback, {
    handleOnBackPressed = options.handleOnBackPressed,
    handleOnBackStarted = options.onBackStarted,
    handleOnBackProgressed = options.onBackProgressed,
    handleOnBackCancelled = options.onBackCancelled,
  }, options.enabled == nil or options.enabled)

  activity.onBackPressedDispatcher.addCallback(self:getBackPressedOwner(), callback)

  if not self.backPressedCallbacks then
    self.backPressedCallbacks = {}
  end
  table.insert(self.backPressedCallbacks, callback)

  return callback
end

--- 移除全部返回键回调
function BasePage:removeAllBackPressedCallbacks()
  if self.backPressedCallbacks then
    for _, callback in ipairs(self.backPressedCallbacks) do
      callback.remove()
    end
    self.backPressedCallbacks = nil
  end
end

local EdgeToEdgeUtils = require("pages.base.edge_to_edge_utils")

-- 配置 EdgeToEdge
-- @param options table
--   options.top: View|table 需要适配状态栏的视图
--   options.bottom: View|table 需要适配导航栏的视图
--   options.start: View|table 需要适配左边的视图
--   options["end"]: View|table 需要适配右边的视图
--   options.lazy: lazy 模式，decorView 自动处理 left/right（默认 true）
--   各方向的视图项可为 View，或 { view = View, useMargin = true }（用 margin 适配，默认 padding）
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
-- @param useMargin true 时用 margin 适配，false（默认）用 padding
function BasePage:addEdgeToEdgeView(view, direction, useMargin)
  if not view then return end
  EdgeToEdgeUtils.add(view, direction, useMargin)
  table.insert(self.edgeToEdgeViews, view)
end

--- 收集 model 暴露的全部 RecyclerView，置 clipToPadding 后追加进 list
--- @param model table|nil 页面数据模型，须实现 getAllRecyclerViews
--- @param list table|nil 追加目标列表，nil 时新建
--- @return table 收集后的列表；model 为空或未实现 getAllRecyclerViews 时原样返回 list
function BasePage:collectModelBottomViews(model, list)
  list = list or {}
  if not model or not model.getAllRecyclerViews then
    return list
  end
  for _, rv in ipairs(model:getAllRecyclerViews()) do
    rv.clipToPadding = false
    table.insert(list, rv)
  end
  return list
end

function BasePage:onCreate(params) end
function BasePage:onResume() end
function BasePage:onPause() end

function BasePage:onDestroy()
  -- 先置位再清理：EdgeToEdgeUtils.remove 里的 luajava.clear 会掏空视图的 Java 载荷，
  -- 置位早于 clear 才能保证存活守卫在清理中途抛错时也拦住后续回调
  self.isDestroyed = true

  -- 销毁时移除所有 EdgeToEdge 添加的视图
  if self.edgeToEdgeViews and #self.edgeToEdgeViews > 0 then
    EdgeToEdgeUtils.remove(self.edgeToEdgeViews)
    self.edgeToEdgeViews = nil
  end

  self:removeAllBackPressedCallbacks()

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
    -- 继续抛出，让携带 traceback 的真实错误到达调用栈顶端
    error(err, 0)
  end

  return self.root_view
end

BasePage:final("build", "isAlive", "runIfAlive", "setupEdgeToEdge", "addEdgeToEdgeView")
BasePage:abstract("initLayout")

return BasePage