-- 以 view[key](value) 形式为主
local require = require
local luajava = luajava
local table = require "table"
local ids = luajava.ids or {
  id = 0x7f000000
}
luajava.ids = ids
local _G = _G
local insert = table.insert
local new = luajava.new
local bindClass = luajava.bindClass
local ltrs = {}
local type = type
local context = activity or service

-- 各种类
local ViewGroup = bindClass("android.view.ViewGroup")
local ContextThemeWrapper=bindClass("androidx.appcompat.view.ContextThemeWrapper")
local String = bindClass("java.lang.String")
local Gravity = bindClass("android.view.Gravity")
local OnClickListener = bindClass("android.view.View$OnClickListener")
local TypedValue = bindClass("android.util.TypedValue")
local BitmapDrawable = bindClass("android.graphics.drawable.BitmapDrawable")
local LuaDrawable = bindClass "com.androlua.LuaDrawable"
local LuaBitmapDrawable = bindClass "com.androlua.LuaBitmapDrawable"
local LuaAdapter = bindClass "com.androlua.LuaAdapter"
local ArrayListAdapter = bindClass("android.widget.ArrayListAdapter")
local ArrayPageAdapter = bindClass("android.widget.ArrayPageAdapter")
local AdapterView = bindClass("android.widget.AdapterView")
local ScaleType = bindClass("android.widget.ImageView$ScaleType")
local TruncateAt = bindClass("android.text.TextUtils$TruncateAt")
local scaleTypes = ScaleType.values()
local android_R = bindClass("android.R")

local Context = bindClass("android.content.Context")
local DisplayMetrics = bindClass("android.util.DisplayMetrics")

local Glide = bindClass("com.bumptech.glide.Glide")

local TooltipCompat = bindClass("androidx.appcompat.widget.TooltipCompat")

local SDK_INT = bindClass("android.os.Build").VERSION.SDK_INT

-- 当前运行路径
local luadir = context.getLuaDir()

local function alyloader(path)
  local alypath = package.path:gsub("%.lua;", ".aly;")
  local path, msg = package.searchpath(path, alypath)
  if msg then
    return msg
  end
  local f = io.open(path)
  local s = f:read("*a")
  f:close()
  if string.sub(s, 1, 4) == "\27Lua" then
    return assert(loadfile(path)), path
   else
    local f, st = loadstring("return " .. s, path:match("[^/]+/[^/]+$"), "bt")
    if st then
      error(st:gsub("%b[]", path, 1), 0)
    end
    return f, st
  end
end
-- table.insert(package.searchers,alyloader)

local dm = context.getResources().getDisplayMetrics()
local id = 0x7f000000
local toint = {
  -- android:drawingCacheQuality
  auto = 0,
  low = 1,
  high = 2,

  -- android:importantForAccessibility
  auto = 0,
  yes = 1,
  no = 2,

  -- android:layerType
  none = 0,
  software = 1,
  hardware = 2,

  -- android:layoutDirection
  ltr = 0,
  rtl = 1,
  inherit = 2,
  locale = 3,

  -- android:scrollbarStyle
  insideOverlay = 0x0,
  insideInset = 0x01000000,
  outsideOverlay = 0x02000000,
  outsideInset = 0x03000000,

  -- android:visibility
  visible = 0,
  invisible = 4,
  gone = 8,

  wrap_content = -2,
  fill_parent = -1,
  match_parent = -1,
  wrap = -2,
  fill = -1,
  match = -1,

  -- android:autoLink
  none = 0x00,
  web = 0x01,
  email = 0x02,
  phon = 0x04,
  map = 0x08,
  all = 0x0f,

  -- android:orientation
  vertical = 1,
  horizontal = 0,

  -- android:gravity
  axis_clip = 8,
  axis_pull_after = 4,
  axis_pull_before = 2,
  axis_specified = 1,
  axis_x_shift = 0,
  axis_y_shift = 4,
  bottom = 80,
  center = 17,
  center_horizontal = 1,
  center_vertical = 16,
  clip_horizontal = 8,
  clip_vertical = 128,
  display_clip_horizontal = 16777216,
  display_clip_vertical = 268435456,
  -- fill = 119,
  fill_horizontal = 7,
  fill_vertical = 112,
  horizontal_gravity_mask = 7,
  left = 3,
  no_gravity = 0,
  relative_horizontal_gravity_mask = 8388615,
  relative_layout_direction = 8388608,
  right = 5,
  start = 8388611,
  top = 48,
  vertical_gravity_mask = 112,
  ["end"] = 8388613,

  -- android:textAlignment
  inherit = 0,
  gravity = 1,
  textStart = 2,
  textEnd = 3,
  textCenter = 4,
  viewStart = 5,
  viewEnd = 6,

  -- android:inputType
  none = 0x00000000,
  text = 0x00000001,
  textCapCharacters = 0x00001001,
  textCapWords = 0x00002001,
  textCapSentences = 0x00004001,
  textAutoCorrect = 0x00008001,
  textAutoComplete = 0x00010001,
  textMultiLine = 0x00020001,
  textImeMultiLine = 0x00040001,
  textNoSuggestions = 0x00080001,
  textUri = 0x00000011,
  textEmailAddress = 0x00000021,
  textEmailSubject = 0x00000031,
  textShortMessage = 0x00000041,
  textLongMessage = 0x00000051,
  textPersonName = 0x00000061,
  textPostalAddress = 0x00000071,
  textPassword = 0x00000081,
  textVisiblePassword = 0x00000091,
  textWebEditText = 0x000000a1,
  textFilter = 0x000000b1,
  textPhonetic = 0x000000c1,
  textWebEmailAddress = 0x000000d1,
  textWebPassword = 0x000000e1,
  number = 0x00000002,
  numberSigned = 0x00001002,
  numberDecimal = 0x00002002,
  numberPassword = 0x00000012,
  phone = 0x00000003,
  datetime = 0x00000004,
  date = 0x00000014,
  time = 0x00000024,

  -- android:imeOptions
  normal = 0x00000000,
  actionUnspecified = 0x00000000,
  actionNone = 0x00000001,
  actionGo = 0x00000002,
  actionSearch = 0x00000003,
  actionSend = 0x00000004,
  actionNext = 0x00000005,
  actionDone = 0x00000006,
  actionPrevious = 0x00000007,
  flagNoFullscreen = 0x2000000,
  flagNavigatePrevious = 0x4000000,
  flagNavigateNext = 0x8000000,
  flagNoExtractUi = 0x10000000,
  flagNoAccessoryAction = 0x20000000,
  flagNoEnterAction = 0x40000000,
  flagForceAscii = 0x80000000

}

local scaleType = {
  -- android:scaleType
  matrix = 0,
  fitXY = 1,
  fitStart = 2,
  fitCenter = 3,
  fitEnd = 4,
  center = 5,
  centerCrop = 6,
  centerInside = 7
}

local rules = {
  layout_above = 2,
  layout_alignBaseline = 4,
  layout_alignBottom = 8,
  layout_alignEnd = 19,
  layout_alignLeft = 5,
  layout_alignParentBottom = 12,
  layout_alignParentEnd = 21,
  layout_alignParentLeft = 9,
  layout_alignParentRight = 11,
  layout_alignParentStart = 20,
  layout_alignParentTop = 10,
  layout_alignRight = 7,
  layout_alignStart = 18,
  layout_alignTop = 6,
  layout_alignWithParentIfMissing = 0,
  layout_below = 3,
  layout_centerHorizontal = 14,
  layout_centerInParent = 13,
  layout_centerVertical = 15,
  layout_toEndOf = 17,
  layout_toLeftOf = 0,
  layout_toRightOf = 1,
  layout_toStartOf = 16
}

local types = {
  px = 0,
  dp = 1,
  sp = 2,
  pt = 3,
  ["in"] = 4,
  mm = 5
}

local function checkType(v)
  local n, ty = string.match(v, "^(%-?[%.%d]+)(%a%a)$")
  return tonumber(n), types[ty]
end

local function split(s, t)
  local idx = 1
  local l = #s
  return function()
    local i = s:find(t, idx)
    if idx >= l then
      return nil
    end
    if i == nil then
      i = l + 1
    end
    local sub = s:sub(idx, i - 1)
    idx = i + 1
    return sub
  end
end

local function checkint(s)
  local ret = 0
  for n in split(s, "|") do
    if toint[n] then
      ret = ret | toint[n]
     else
      return nil
    end
  end
  return ret
end

local function checkNumber(var)
  if type(var) == "string" then
    -- true与false不再使用string
    if toint[var] then
      return toint[var]
    end

    local i = checkint(var)
    if i then
      return i
    end
    -- #XXX已去除

    local n, ty = checkType(var)
    if ty then
      return TypedValue.applyDimension(ty, n, dm)
    end
  end
end

local function checkValue(var)
  return checkNumber(var) or var
end

local function checkValues(...)
  local vars = {...}
  for n = 1, #vars do
    vars[n] = checkValue(vars[n])
  end
  return unpack(vars)
end

local function getIdentifier(name)
  return context.getResources().getIdentifier(name, nil, nil)
end

local function dump2(t)
  local _t = {}
  table.insert(_t, tostring(t))
  table.insert(_t, "\t{")
  for k, v in pairs(t) do
    if type(v) == "table" then
      table.insert(_t, "\t\t" .. tostring(k) .. "={" .. tostring(v[1]) .. " ...}")
     else
      table.insert(_t, "\t\t" .. tostring(k) .. "=" .. tostring(v))
    end
  end
  table.insert(_t, "\t}")
  t = table.concat(_t, "\n")
  return t
end

-- Jesse205Library不支持api21以下，所以没必要做低于api16检查
local nowRoot, nowView, nowParams, nowKey, nowValue, nowKeyType, nowValueType, nowIds
local attributeSetterMap = {
  pages = function()
    if nowValueType == "table" then
      local ps = {}
      for n, o in ipairs(nowValue) do
        local tp = type(o)
        if tp == "string" or tp == "table" then
          table.insert(ps, loadlayout(o, nowRoot))
         else
          table.insert(ps, o)
        end
      end
      local adapter = ArrayPageAdapter(View(ps))
      nowView.setAdapter(adapter)
    end
  end,
  textSize = function()
    if tonumber(nowValue) then
      nowView.setTextSize(tonumber(nowValue))
     elseif type(nowValue) == "string" then
      local n, ty = checkType(nowValue)
      if ty then
        nowView.setTextSize(ty, n)
      end
     else
      nowView.setTextSize(nowValue)
    end
  end,
  textAppearance = function()
    nowView.setTextAppearance(context, nowValue)
  end,
  ellipsize = function()
    nowView.setEllipsize(TruncateAt[string.upper(nowValue)])
  end,
  url = function()
    nowView.loadUrl(nowValue)
  end,
  tooltip = function()
    TooltipCompat.setTooltipText(nowView, nowValue)
    nowView.setContentDescription(nowValue)
  end,
  src = function()
    if nowValue:find("^%?") then
      nowView.setImageResource(getIdentifier(nowValue:sub(2, -1)))
     else
      if not (nowValue:find("^/") or nowValue:find("^.+://")) then
        nowValue = luadir .. "/" .. nowValue
      end
      Glide.with(context).load(nowValue).into(nowView)
    end
  end,
  scaleType = function()
    nowView.setScaleType(scaleTypes[scaleType[nowValue]])
  end,
  background = function()
    if nowValueType == "string" then
      if not nowValue:find("^/") then
        nowValue = luadir .. "/" .. nowValue
      end
      if nowValue:find("%.9%.png") then
        nowView.setBackground(NineBitmapDrawable(loadbitmap(nowValue)))
       else
        nowView.setBackground(LuaBitmapDrawable(context, nowValue))
      end
     elseif nowValueType == "userdata" or nowValueType == "number" then
      nowView.setBackground(nowValue)
    end
  end,
  onClick = function() -- 设置onClick事件接口
    if nowValueType == "function" then
      nowView.onClick = nowValue
     elseif nowValueType == "userdata" then
      nowView.setOnClickListener(nowValue)
    end
  end,
  getView= function()
    if nowValueType=="function" then
      nowValue(nowView)
     else
      error(string.format(
      "getView必须要是function 当前type:%s", nowValueType
      ))
    end
  end
}

local function setattribute(root, view, params, k, v, ids)
  local keyType, valueType = type(k), type(v)
  if rules[k] then
    if v==true then
      params.addRule(rules[k])
     else
      params.addRule(rules[k],ids[v])
    end
    return
  end

  local setter = attributeSetterMap[k]
  if setter then
    nowRoot, nowView, nowParams, nowKey, nowValue, nowKeyType, nowValueType, nowIds=root, view, params, k, v, keyType, valueType, ids
    return setter()
  end

  if keyType == "string" then
    local paramsAttr = k:match("^layout_(.+)")
    if paramsAttr == "margin" or paramsAttr == "marginRight" or paramsAttr == "marginLeft" or paramsAttr ==
      "marginTop" or paramsAttr == "marginBottom" then
      return
    end
    if paramsAttr then
      params[paramsAttr] = checkValue(v)
     elseif not (k:find("padding")) and k ~= "style" and k ~= "theme" then -- 设置属性
      k = string.gsub(k, "^(%w)", string.upper)
      if k == "Text" or k == "Title" or k == "Subtitle" or k == "Hint" then
        view["set" .. k](v)
       elseif not (k:find("^On") or k:find("^Tag")) and type(v) == "table" then
        view["set" .. k](checkValues(unpack(v)))
       else
        view["set" .. k](checkValue(v))
      end
    end
  end
end

local function copytable(f, t, b)
  for k, v in pairs(f) do
    if k == 1 then
     elseif b or t[k] == nil then
      t[k] = v
    end
  end
end

local function getRealClass(class)
  if type(class) == "table" then
    return class._baseClass
   else
    return class
  end
end

local function loadlayout(t, root, group)
  local tType=type(t)
  if tType == "string" then
    t = require(t)
   elseif tType ~= "table" then
    error(string.format("loadlayout error: Fist value Must be a table, checked import layout.", 0))
  end
  root = root or _G
  local view
  local style = t.style
  local theme=t.theme
  local viewClass=t[1]
  if not viewClass then
    error(string.format("loadlayout error: Fist value Must be a Class, checked import package.\n\tat %s", dump2(t)),
    0)
  end

  local context=context
  if theme then
    context=ContextThemeWrapper(context,theme)
  end

  if style then
    view = viewClass(context, nil, style)
   else
    view = viewClass(context) -- 创建view
  end

  local params = ViewGroup.LayoutParams(checkValue(t.layout_width) or -2, checkValue(t.layout_height) or -2) -- 设置layout属性
  if group then
    params = getRealClass(group).LayoutParams(params)
  end

  -- 设置layout_margin属性
  -- or t.layout_marginStart or t.layout_marginEnd
  if t.layout_margin or t.layout_marginLeft or t.layout_marginTop or t.layout_marginRight or t.layout_marginBottom then
    if not pcall(function() params.setMargins(0, 0, 0, 0) end) then
      params = ViewGroup.MarginLayoutParams(params)
    end
    params.setMargins(checkValues(t.layout_marginLeft or t.layout_margin or 0,
    t.layout_marginTop or t.layout_margin or 0,
    t.layout_marginRight or t.layout_margin or 0,
    t.layout_marginBottom or t.layout_margin or 0))
  end

  -- 设置padding属性
  if t.padding and type(t.padding) == "table" then
    view.setPadding(checkValues(unpack(t.padding)))
   elseif t.padding or t.paddingLeft or t.paddingTop or t.paddingRight or t.paddingBottom then
    view.setPadding(checkValues(t.paddingLeft or t.padding or 0, t.paddingTop or t.padding or 0,
    t.paddingRight or t.padding or 0, t.paddingBottom or t.padding or 0))
  end
  if t.paddingStart or t.paddingEnd then
    view.setPaddingRelative(checkValues(t.paddingStart or t.padding or 0, t.paddingTop or t.padding or 0,
    t.paddingEnd or t.padding or 0, t.paddingBottom or t.padding or 0))
  end

  --local instanceofAdapterView
  for k, v in pairs(t) do
    if k~=1 then
      if type(k)=="number" then -- 创建子view
        --取消了对适配器的兼容
        view.addView(loadlayout(v, root, viewClass))
       elseif k == "id" then -- 创建view的全局变量
        rawset(root, v, view)
        local id = ids.id
        ids.id = ids.id + 1
        view.setId(id)
        ids[v] = id
       else
        local e, s = pcall(setattribute, root, view, params, k, v, ids)
        if not e then
          local _, i = s:find(":%d+:")
          s = s:sub(i or 1, -1)
          local t, du = pcall(dump2, t)
          error(
          string.format("loadlayout error %s \n\tat %s\n\tat  key=%s value=%s\n\tat %s", s, view.toString(),
          k, v, du or ""), 0)
        end
      end
    end
  end
  view.setLayoutParams(params)
  return view
end

return loadlayout
