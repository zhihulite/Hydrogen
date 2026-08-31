-- components/span/emoji_span.lua
-- emoji span

local M = {}

import "android.text.style.ReplacementSpan"
import "android.graphics.Bitmap"

local SpanUtil = require("components.span.span_util")

local FontMetricsInt = luajava.bindClass("android.graphics.Paint$FontMetricsInt")

-- 缩放位图缓存：同一表情同一尺寸只缩放一次，命中直接复用
local scaledCache = {}

function M.new(emojiName, sizeDp)
  -- dp2px 的返回值自带四舍五入的 +0.5，floor 一次即得到确定整数；
  -- getSize 过桥要求 int，测量（getSize）与绘制/缩放（createScaledBitmap、draw）
  -- 必须共用同一个整数值
  local sizePx = math.floor(dp2px(sizeDp or 20))
  local textCode = "[" .. emojiName .. "]"

  local cacheKey = emojiName .. "@" .. sizePx
  local bitmap = scaledCache[cacheKey]
  if not bitmap then
    local source = Helpers.Static.zemoji(emojiName)
    if not source then return nil end
    bitmap = Bitmap.createScaledBitmap(source, sizePx, sizePx, true)
    rawset(scaledCache, cacheKey, bitmap)
  end

  -- draw/getSize 复用的字体度量容器，填充式接口不产生新分配
  local fmInt = FontMetricsInt()

  local span = luajava.override(ReplacementSpan, {
    getSize = function(super, paint, cs, start, end_, fm)
      if fm then
        paint.getFontMetricsInt(fmInt)
        local textHeight = fmInt.bottom - fmInt.top
        local imageHalf = sizePx / 2
        local quarter = math.floor(textHeight / 4)
        local bottomOffset = imageHalf - quarter
        local topOffset = -(imageHalf + quarter)
        fm.ascent = topOffset
        fm.top = topOffset
        fm.bottom = bottomOffset
        fm.descent = bottomOffset
      end
      return sizePx
    end,
    draw = function(super, canvas, cs, start, end_, x, top, y, bottom, paint)
      if start >= end_ then return end

      -- "…" 是单个字符，正常表情区间至少 3 字符，仅单字符时取文本判断
      if end_ - start == 1 then
        local segment = tostring(cs.subSequence(start, end_))
        if segment == "…" then
          canvas.drawText(segment, x, y, paint)
          return
        end
      end

      if bitmap then
        paint.getFontMetricsInt(fmInt)
        local imageTop = (fmInt.descent + y + y + fmInt.ascent) / 2 - sizePx / 2
        canvas.drawBitmap(bitmap, x, imageTop, paint)
      end
    end,
    toString = function(super)
      return textCode
    end
  })

  -- 表情包不需要点击，只打包 setSpan
  return SpanUtil.bundle(span)
end

return M
