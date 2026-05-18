-- components/span/MentionSpan.lua
local M = {}

import "android.text.style.ReplacementSpan"
import "android.text.style.ClickableSpan"
import "android.graphics.Canvas"

function M.new(userId, userName, repinInfo)
  local displayText = "@" .. userName .. " "
  local repinInfo = repinInfo or ""

  local htmlTag
  if repinInfo ~= "" then
    htmlTag = '<a data-hash="' .. userId .. '" href="/people/' .. userId .. '" class="member_mention" data-repin="' .. repinInfo .. '">' .. displayText .. '</a>'
   else
    htmlTag = '<a data-hash="' .. userId .. '" href="/people/' .. userId .. '" class="member_mention">' .. displayText .. '</a>'
  end

  -- ReplacementSpan 用于显示
  local span = luajava.override(ReplacementSpan, {
    getSize = function(super, paint, cs, start, end_, fm)
      if start >= end_ then return 0 end
      return paint.measureText(displayText)
    end,
    draw = function(super, canvas, cs, start, end_, x, top, y, bottom, paint)
      if start >= end_ then return end
      local colors = AppTheme.getColors()
      local originalColor = paint.getColor()
      paint.setColor(colors.primary)
      canvas.drawText(displayText, x, y, paint)
      paint.setColor(originalColor)
    end,
    toString = function(super)
      return htmlTag
    end
  })

  -- ClickableSpan 用于点击
  local clickSpan = luajava.override(ClickableSpan, {
    onClick = function(super, widget)
      Router.go("people", { id = userId })
    end,
    updateDrawState = function(super, ds)
      super.updateDrawState(ds)
      local colors = AppTheme.getColors()
      ds.setColor(colors.primary)
      ds.setUnderlineText(false)
    end
  })

  return {
    setSpan = function(editable, start, end_, flags)
      editable.setSpan(span, start, end_, flags)
      editable.setSpan(clickSpan, start, end_, flags)
    end
  }
end

return M