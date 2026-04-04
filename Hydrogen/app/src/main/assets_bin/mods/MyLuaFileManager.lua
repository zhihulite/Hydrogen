local MyLuaFileManager = {}
MyLuaFileManager.__index = MyLuaFileManager

local MaterialCardView = luajava.bindClass("com.google.android.material.card.MaterialCardView")
local LinearLayout = luajava.bindClass("android.widget.LinearLayout")
local FrameLayout = luajava.bindClass("android.widget.FrameLayout")
local View = luajava.bindClass("android.view.View")

local function newFrameLayout(activity)
  local frame = FrameLayout(activity)
  frame.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
  frame.setId(View.generateViewId())
  return frame
end

local function newCardContainer(activity)
  local card = MaterialCardView(activity)
  card.setLayoutParams(LinearLayout.LayoutParams(0, -1, 1.0))
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
  self.root.setOrientation(LinearLayout.HORIZONTAL)

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

  self:setParallelMode(false, activity.getDecorView().width)
  return self
end

function MyLuaFileManager:getPrimaryContainer()
  return self.containers[1].frame
end

function MyLuaFileManager:getSecondaryContainer()
  return self.containers[2].frame
end

function MyLuaFileManager:getContainerPair()
  return self.containers[1].frame, self.containers[2].frame
end

function MyLuaFileManager:setParallelMode(enabled, width)
  self.inSekai = enabled
  local firstCard = self.containers[1].card
  local secondCard = self.containers[2].card

  local firstParams = LinearLayout.LayoutParams(0, -1, 1.0)
  local secondParams = LinearLayout.LayoutParams(0, -1, 1.0)

  if enabled and width and width > 0 then
    firstParams.width = math.floor(width * 0.5)
    secondParams.width = 0
    secondParams.setMarginStart(dp2px(8))
  else
    local overlapWidth = width or activity.getDecorView().width
    firstParams.width = overlapWidth
    secondParams.width = overlapWidth
    secondParams.setMarginStart(-1 * overlapWidth)
  end

  firstCard.setLayoutParams(firstParams)
  secondCard.setLayoutParams(secondParams)
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
