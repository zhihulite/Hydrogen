import "android.view.MotionEvent"
import "androidx.viewpager.widget.ViewPager"

local MyViewPager = {}
MyViewPager.__index = MyViewPager

-- 构造函数
function MyViewPager.new(context, attrs)
  local self = setmetatable({}, MyViewPager)

  self.noScroll = false -- 是否禁止滑动
  self.startX = 0
  self.startY = 0

  self.instance = luajava.override(ViewPager, {
    onInterceptTouchEvent = function(super, ev)
      if not self.noScroll then
        return super(ev)
       else
        return false
      end
    end,

    onTouchEvent = function(super, ev)
      if not self.noScroll then
        return super(ev)
       else
        return false
      end
    end,

    dispatchTouchEvent = function(super, ev)
      local view = self.instance
      local parent = view.getParent()
      local action = ev.getAction()

      switch(action)
       case MotionEvent.ACTION_DOWN
        self.startX = ev.getX()
        self.startY = ev.getY()
        parent.requestDisallowInterceptTouchEvent(true)
       case MotionEvent.ACTION_MOVE
        local endX = ev.getX()
        local endY = ev.getY()
        local distanceX = endX - self.startX
        local distanceY = endY - self.startY

        if Math.abs(distanceX) > Math.abs(distanceY) then
          local currentItem = view.getCurrentItem()
          local pageCount = view.getAdapter().getCount()

          if currentItem == 0 and distanceX > 0 then
            -- 第一页向右滑动，允许父容器拦截
            parent.requestDisallowInterceptTouchEvent(false)
           elseif currentItem == pageCount - 1 and distanceX < 0 then
            -- 最后一页向左滑动，禁止父容器拦截
            parent.requestDisallowInterceptTouchEvent(true)
           else
            -- 中间页面，禁止父容器拦截
            parent.requestDisallowInterceptTouchEvent(true)
          end
         else
          -- 垂直方向滑动，禁止父容器拦截
          parent.requestDisallowInterceptTouchEvent(true)
        end
       case MotionEvent.ACTION_UP
        -- 可选：处理抬起事件
       default
      end

      return super(ev)
    end
  })

  -- 绑定自身用于外部调用
  self.instance.tag = self
  return self.instance
end

-- 设置是否禁止滑动
function MyViewPager:setNoScroll(noScroll)
  self.noScroll = noScroll
end

return MyViewPager.new