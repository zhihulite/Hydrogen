local MyLuaFileManager = {}
MyLuaFileManager.__index = MyLuaFileManager

local MaterialCardView = luajava.bindClass("com.google.android.material.card.MaterialCardView")
local FrameLayout = luajava.bindClass("android.widget.FrameLayout")
local View = luajava.bindClass("android.view.View")
local Gravity = luajava.bindClass("android.view.Gravity")

local function resolveWidth(root)
  local width = root.getWidth()
  if not width or width <= 0 then
    width = activity.getDecorView().getWidth()
  end
  if not width or width <= 0 then
    width = activity.getResources().getDisplayMetrics().widthPixels
  end
  return width
end

local function newFrameLayout(activity)
  local frame = FrameLayout(activity)
  frame.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
  frame.setId(View.generateViewId())
  return frame
end

local function newCardContainer(activity)
  local card = MaterialCardView(activity)
  card.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
  card.setCardElevation(0)
  card.setStrokeWidth(0)
  card.setRadius(0)
  card.setUseCompatPadding(false)
  card.setPreventCornerOverlap(false)
  return card
end

function MyLuaFileManager.new(rootContainer)
  local self = setmetatable({}, MyLuaFileManager)
  self.root = rootContainer
  self.inSekai = false
  self.containers = {}

  self.root.removeAllViews()

  local firstCard = newCardContainer(activity)
  local secondCard = newCardContainer(activity)
  local firstFrame = newFrameLayout(activity)
  local secondFrame = newFrameLayout(activity)

  firstCard.addView(firstFrame)
  secondCard.addView(secondFrame)
  self.root.addView(firstCard)
  self.root.addView(secondCard)

  self.containers[1] = {card = firstCard, frame = firstFrame}
  self.containers[2] = {card = secondCard, frame = secondFrame}

  self:setParallelMode(false)
  return self
end

function MyLuaFileManager:getContainerPair()
  return self.containers[1].frame, self.containers[2].frame
end

function MyLuaFileManager:getCardContainerByFrame(frame)
  for _, item in ipairs(self.containers) do
    if item.frame == frame then
      return item.card
    end
  end
  return frame
end

function MyLuaFileManager:getCardContainerByView(view)
  local current = view
  while current do
    for _, item in ipairs(self.containers) do
      if current == item.card then
        return item.card
      end
    end
    current = current.getParent and current.getParent() or nil
  end
  return nil
end

function MyLuaFileManager:setParallelMode(enabled, width)
  self.inSekai = enabled

  local firstCard = self.containers[1].card
  local secondCard = self.containers[2].card
  local rootWidth = width or resolveWidth(self.root)

  if enabled then
    local half = math.floor(rootWidth * 0.5)
    local gap = dp2px(8)

    local firstParams = FrameLayout.LayoutParams(half - math.floor(gap / 2), -1)
    firstParams.gravity = Gravity.START

    local secondParams = FrameLayout.LayoutParams(half - math.floor(gap / 2), -1)
    secondParams.gravity = Gravity.END

    firstCard.setLayoutParams(firstParams)
    secondCard.setLayoutParams(secondParams)
    firstCard.setVisibility(View.VISIBLE)
    secondCard.setVisibility(View.VISIBLE)
    firstCard.bringToFront()
  else
    local overlayParams = FrameLayout.LayoutParams(-1, -1)
    overlayParams.gravity = Gravity.START
    firstCard.setLayoutParams(overlayParams)
    secondCard.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
    firstCard.setVisibility(View.VISIBLE)
    secondCard.setVisibility(View.GONE)
    firstCard.bringToFront()
  end
end

function MyLuaFileManager:selectTargetContainer(pageTag)
  local f1, f2 = self:getContainerPair()
  local ff = f1

  if tonumber(f1.getTag(R.id.tag_last_time)) > tonumber(f2.getTag(R.id.tag_last_time)) then
    ff = f2
  else
    ff = f1
  end

  if f2.tag == pageTag then
    ff = f2
  end

  if not self.inSekai then
    ff = f1
  end

  return ff
end

function MyLuaFileManager:markContainer(container, pageTag)
  local nt = tonumber(os.time())
  container.tag = pageTag
  container.setTag(R.id.tag_last_time, nt)
end

function MyLuaFileManager:initDefaultTags()
  local f1, f2 = self:getContainerPair()
  f1.setTag("home")
  f1.setTag(R.id.tag_last_time, tonumber(os.time()))
  f2.setTag("empty")
  f2.setTag(R.id.tag_last_time, tonumber(os.time()) - 114514)
end

return MyLuaFileManager
