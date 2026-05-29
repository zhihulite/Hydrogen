-- pages/base/EdgeToEdgeUtils.lua
-- EdgeToEdge 工具类
--
-- 方案说明：
-- 在 target29 某个 View 消费 insets 会导致其他 View 收不到回调
-- 虽然 AndroidX 的 ViewCompat.setOnApplyWindowInsetsListener 已做底层兼容，也可用 installCompatInsetsDispatch，
-- 但本工具采用更简单可控的方式：只在 decorView 注册监听，手动遍历所有业务 View。
--
-- 特性：
-- - 支持 RTL，偷懒模式：decorView 自动处理 left/right
-- - 页面销毁时务必调用 remove 清理
--
-- 注意：偷懒模式下会自动为 decorView 设置 left/right padding，
--       此时不应再传入 start/end 方向的 View，否则会有冲突

import "androidx.activity.EdgeToEdge"
import "androidx.core.view.ViewCompat"
import "androidx.core.view.WindowInsetsCompat"
import "androidx.core.view.MarginLayoutParamsCompat"
import "android.view.View"
import "android.view.ViewGroup"
import "java.lang.System"

local M = {}

local records = {}
local listenerReady = false
local rtl = false
local useLazyMode = true

-- 获取 View 唯一 key
local function getViewKey(view)
  if not view then return nil end
  return tostring(System.identityHashCode(view))
end

-- 更新 RTL 状态
local function updateRtl()
  local root = activity and activity.window and activity.window.decorView
  if root then
    rtl = root.getLayoutDirection() == View.LAYOUT_DIRECTION_RTL
  end
end

-- 将 left/right 转换为 start/end（根据 RTL）
local function getStartEndInset(insets)
  if rtl then
    return insets.right, insets.left
   else
    return insets.left, insets.right
  end
end


-- 保存原始 Padding
local function savePadding(view)
  return {
    type = "padding",
    view = view,
    start = view.paddingStart,
    top = view.paddingTop,
    ["end"] = view.paddingEnd,
    bottom = view.paddingBottom
  }
end
-- 设置 Padding
local function setPadding(view, start, top, ending, bottom)
  if not view then return end
  view.setPaddingRelative(start, top, ending, bottom)
end

local MarginLayoutParams = ViewGroup.MarginLayoutParams
-- 保存原始 Margin
local function saveMargin(view)
  local lp = view.layoutParams
  if not lp then
    error("EdgeToEdgeUtils: View 没有 LayoutParams，无法使用 margin 模式")
  end
  if not luajava.instanceof(lp, MarginLayoutParams) then
    error("EdgeToEdgeUtils: LayoutParams 不是 MarginLayoutParams 类型，无法使用 margin 模式")
  end
  return {
    type = "margin",
    view = view,
    lp = lp,
    start = MarginLayoutParamsCompat.getMarginStart(lp),
    top = lp.topMargin,
    ["end"] = MarginLayoutParamsCompat.getMarginEnd(lp),
    bottom = lp.bottomMargin
  }
end
-- 设置 Margin
local function setMargin(view, start, top, ending, bottom)
  if not view then return end
  local lp = view.getLayoutParams()
  if lp and luajava.instanceof(lp, MarginLayoutParams) then
    MarginLayoutParamsCompat.setMarginStart(lp, start)
    lp.topMargin = top
    MarginLayoutParamsCompat.setMarginEnd(lp, ending)
    lp.bottomMargin = bottom
    view.setLayoutParams(lp)
  end
end


-- 恢复原始值
local function restore(record)
  if record.type == "padding" then
    setPadding(record.view, record.start, record.top, record["end"], record.bottom)
   else
    setMargin(record.view, record.start, record.top, record["end"], record.bottom)
  end
end

-- 应用 insets
local function apply(record, insets, startInset, endInset)
  local start = record.start
  local top = record.top
  local ending = record["end"]
  local bottom = record.bottom
  local dir = record.dir

  if dir == "top" then
    top = top + insets.top
   elseif dir == "bottom" then
    bottom = bottom + insets.bottom
   elseif dir == "start" then
    start = start + startInset
   elseif dir == "end" then
    ending = ending + endInset
  end

  if record.type == "padding" then
    setPadding(record.view, start, top, ending, bottom)
   else
    setMargin(record.view, start, top, ending, bottom)
  end
end

-- 全局监听
local function setupListener()
  if listenerReady then return end
  listenerReady = true

  ViewCompat.setOnApplyWindowInsetsListener(activity.window.decorView, function(view, insets)
    local bars = WindowInsetsCompat.Type.systemBars()
    local cutout = WindowInsetsCompat.Type.displayCutout()
    local val = insets.getInsets(bit32.bor(bars, cutout))

    updateRtl()

    if useLazyMode then
      local s, e = getStartEndInset(val)
      view.setPadding(s, 0, e, 0)
    end

    local s, e = getStartEndInset(val)
    for _, r in pairs(records) do
      if r.view then apply(r, val, s, e) end
    end

    return insets
  end)
end

-- 解析单个配置项
local function parseItem(item, dir)
  local view, useMargin = nil, false
  if type(item) == "table" then
    view = item.view
    useMargin = item.useMargin or false
   else
    view = item
  end
  if not view then return nil end

  local key = getViewKey(view)
  if records[key] then return nil end

  local record = useMargin and saveMargin(view) or savePadding(view)
  if not record then return nil end

  record.dir = dir
  records[key] = record
  return view
end

-- ============ 公开 API ============

function M.setup(options)
  options = options or {}
  if options.lazy == false then useLazyMode = false end

  if useLazyMode and (options.start or options["end"]) then
    print("警告: EdgeToEdge 当前为偷懒模式，decorView 已自动处理 left/right")
    print("建议只使用 top/bottom，如需使用 start/end 请设置 lazy = false")
  end

  EdgeToEdge.enable(activity)
  updateRtl()
  setupListener()

  local added = {}
  local dirs = {"top", "bottom", "start", "end"}

  for _, dir in ipairs(dirs) do
    local list = options[dir]
    if list then
      local arr = type(list) == "table" and list or { list }
      for _, item in ipairs(arr) do
        local view = parseItem(item, dir)
        if view then table.insert(added, view) end
      end
    end
  end

  return added
end

function M.add(view, direction, useMargin)
  if not view then return end
  local key = getViewKey(view)
  if records[key] then return end

  local record = useMargin and saveMargin(view) or savePadding(view)
  if not record then return end

  record.dir = direction
  records[key] = record
end

function M.remove(view)
  if not view then return end
  if type(view) == "table" then
    for _, v in ipairs(view) do M.remove(v) end
    return
  end

  local key = getViewKey(view)
  local record = records[key]
  if record then
    restore(record)
    records[key] = nil
    luajava.clear(view)
  end
end

function M.clear()
  for _, record in pairs(records) do restore(record) end
  records = {}
  listenerReady = false
end

function M.refresh()
  ViewCompat.requestApplyInsets(activity.window.decorView)
end

return M