-- pages/base/EdgeToEdgeUtils.lua
-- EdgeToEdge 工具类
-- 支持 RTL，偷懒模式：decorView 自动处理 left/right
-- 请在页面销毁手动调用 remove 销毁 View 监听
-- 配置 EdgeToEdge（直接拿当前 insets 设置，不注册监听器）
-- https://github.com/material-components/material-components-android/blob/master/lib/java/com/google/android/material/appbar/CollapsingToolbarLayout.java
-- CollapsingToolbarLayout onWindowInsetChanged 返回 insets.consumeSystemWindowInsets() 会吞掉 insets 所以不注册回调了

import "androidx.activity.EdgeToEdge"
import "androidx.core.view.ViewCompat"
import "androidx.core.view.WindowInsetsCompat"
import "android.view.View"

local M = {}

local views = {}
local listenerReady = false
local rtl = false
local useLazyMode = true

local function updateRtl()
  local root = activity and activity.window and activity.window.decorView
  if root then
    rtl = root.layoutDirection == View.LAYOUT_DIRECTION_RTL
  end
end

local function getInset(insets, dir)
  if dir == "start" then
    return rtl and insets.right or insets.left
   elseif dir == "end_" then
    return rtl and insets.left or insets.right
  end
  return insets[dir] or 0
end

local MarginLayoutParams = luajava.bindClass("android.view.ViewGroup$MarginLayoutParams")

local function record(view, cfg)
  if not cfg.pad then
    cfg.pad = {
      left = view.paddingLeft,
      top = view.paddingTop,
      right = view.paddingRight,
      bottom = view.paddingBottom
    }
  end
  if cfg.useMargin and not cfg.margin then
    local p = view.layoutParams
    if p and luajava.instanceof(p, MarginLayoutParams) then
      cfg.margin = {
        left = p.leftMargin,
        top = p.topMargin,
        right = p.rightMargin,
        bottom = p.bottomMargin
      }
    end
  end
end

local function restore(view, cfg)
  if cfg.pad then
    view.setPadding(cfg.pad.left, cfg.pad.top, cfg.pad.right, cfg.pad.bottom)
  end
  if cfg.margin then
    local m = cfg.margin
    local p = view.layoutParams
    if p then
      p.leftMargin = m.left
      p.topMargin = m.top
      p.rightMargin = m.right
      p.bottomMargin = m.bottom
      view.layoutParams = p
    end
  end
end

local function applyWithOriginal(original, dir, insetsValue, isMargin, view)
  local newValues = {
    left = original.left,
    top = original.top,
    right = original.right,
    bottom = original.bottom
  }

  local p = nil
  if isMargin then
    p = view.layoutParams
    if not p then
      error("EdgeToEdgeUtils: view 没有 LayoutParams")
    end
    if not luajava.instanceof(p, MarginLayoutParams) then
      error("EdgeToEdgeUtils: LayoutParams 不是 MarginLayoutParams 类型")
    end
  end

  if dir == "start" then
    if rtl then
      newValues.right = original.right + insetsValue
     else
      newValues.left = original.left + insetsValue
    end
   elseif dir == "end_" then
    if rtl then
      newValues.left = original.left + insetsValue
     else
      newValues.right = original.right + insetsValue
    end
   elseif dir == "top" then
    newValues.top = original.top + insetsValue
   elseif dir == "bottom" then
    newValues.bottom = original.bottom + insetsValue
  end

  if isMargin then
    p.leftMargin = newValues.left
    p.topMargin = newValues.top
    p.rightMargin = newValues.right
    p.bottomMargin = newValues.bottom
    view.layoutParams = p
   else
    view.setPadding(newValues.left, newValues.top, newValues.right, newValues.bottom)
  end
end

local function apply(view, cfg, ins)
  local dir = cfg.direction
  local insetsValue = getInset(ins, dir)

  if cfg.useMargin then
    applyWithOriginal(cfg.margin, dir, insetsValue, true, view)
   else
    applyWithOriginal(cfg.pad, dir, insetsValue, false, view)
  end
end


local function applyAll(ins)
  local toRemove = {}
  for key, cfg in pairs(views) do
    local view = cfg.view
    if view then
      apply(view, cfg, ins)
     else
      table.insert(toRemove, key)
    end
  end

  for _, key in ipairs(toRemove) do
    views[key] = nil
  end
end

local function setupListener()
  if listenerReady then return end
  listenerReady = true

  ViewCompat.setOnApplyWindowInsetsListener(activity.window.decorView, luajava.createProxy("androidx.core.view.OnApplyWindowInsetsListener", {
    onApplyWindowInsets = function(view, insets)
      local success, err = xpcall(function()
        local bars = WindowInsetsCompat.Type.systemBars()
        local cutout = WindowInsetsCompat.Type.displayCutout()
        local val = insets.getInsets(bit32.bor(bars, cutout))

        if useLazyMode then
          -- 偷懒模式：decorView 自动处理左右
          local leftInset = rtl and val.right or val.left
          local rightInset = rtl and val.left or val.right
          view.setPadding(leftInset, 0, rightInset, 0)
        end

        updateRtl()
        applyAll(val)
        end, function(err)
        print("EdgeToEdge onApplyWindowInsets 错误:", err)
        return insets
      end)

      if not success then
        return insets
      end

      return insets
    end
  }))
end

import "java.lang.System"
local function getViewKey(view)
  if not view then return nil end
  local hashCode = System.identityHashCode(view)
  return tostring(hashCode)
end

-- ============ API ============

function M.setup(opt)
  opt = opt or {}

  if opt.lazy == false then
    useLazyMode = false
  end

  if useLazyMode and (opt.start or opt.end_) then
    print("警告: EdgeToEdge 当前为偷懒模式，decorView 已自动处理 left/right")
    print("建议只使用 top/bottom，后续业务扩展可设置 lazy = false 自行控制")
  end

  EdgeToEdge.enable(activity)
  updateRtl()
  setupListener()

  local addedViews = {} -- 返回本次添加的视图表

  for _, dir in ipairs({"start", "end_", "top", "bottom"}) do
    local list = opt[dir]
    if list then
      local arr = type(list) == "table" and list or { list }
      for _, it in ipairs(arr) do
        local view, useMargin = nil, nil
        if type(it) == "table" and it.view then
          view, useMargin = it.view, it.useMargin
         else
          view, useMargin = it, opt.useMargin
        end
        if view then
          M.add(view, dir, useMargin)
          table.insert(addedViews, view)
        end
      end
    end
  end

  return addedViews -- 返回所有添加的视图表，用于页面结束统一移除
end

function M.add(view, direction, useMargin)
  if not view then return end
  local key = getViewKey(view)
  if not views[key] then
    views[key] = { view = view, direction = direction, useMargin = useMargin or false }
    record(view, views[key])
  end

  local ins = ViewCompat.getRootWindowInsets(activity.window.decorView)
  if ins then
    local bars = WindowInsetsCompat.Type.systemBars()
    local cutout = WindowInsetsCompat.Type.displayCutout()
    local val = ins.getInsets(bit32.bor(bars, cutout))
    apply(view, views[key], val)
  end
end

function M.remove(view)
  if not view then return end

  -- 支持传入 table 批量移除
  if type(view) == "table" then
    for _, v in ipairs(view) do
      M.remove(v)
    end
    return
  end

  local key = getViewKey(view)
  local cfg = views[key]
  if cfg then
    restore(view, cfg)
    views[key] = nil
  end
  luajava.clear(view)
end

function M.clear()
  for _, cfg in pairs(views) do
    if cfg.view then restore(cfg.view, cfg) end
  end
  views = {}
end

return M