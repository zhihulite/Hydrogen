-- components/span/EmojiSpan.lua
local M = {}

import "android.text.style.ReplacementSpan"
import "android.graphics.Canvas"
import "android.graphics.Bitmap"

function M.new(emojiName, sizeDp)
  local sizePx = dp2px(sizeDp or 20)
  local textCode = "[" .. emojiName .. "]"

  local bitmap = Helpers.Static.zemoji(emojiName)
  if not bitmap then return nil end

  bitmap = Bitmap.createScaledBitmap(bitmap, sizePx, sizePx, true)

  local span = luajava.override(ReplacementSpan, {
    getSize = function(super, paint, cs, start, end_, fm)
      if fm then
        local paintFm = paint.getFontMetricsInt()
        local textHeight = paintFm.bottom - paintFm.top
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

      local segment = tostring(cs.subSequence(start, end_))
      if segment == "…" then
        canvas.drawText(segment, x, y, paint)
        return
      end

      if bitmap then
        local fm = paint.getFontMetricsInt()
        local imageTop = (fm.descent + y + y + fm.ascent) / 2 - sizePx / 2
        canvas.drawBitmap(bitmap, x, imageTop, paint)
      end
    end,
    toString = function(super)
      return textCode
    end
  })

  -- 表情包不需要点击，只返回 setSpan
  return {
    setSpan = function(editable, start, end_, flags)
      editable.setSpan(span, start, end_, flags)
    end
  }
end

return M