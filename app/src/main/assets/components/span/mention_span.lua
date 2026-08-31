-- components/span/mention_span.lua
-- mention span

local M = {}

import "android.text.style.ReplacementSpan"

local SpanUtil = require("components.span.span_util")

function M.new(userId, userName, repinInfo)
  local displayText = "@" .. userName .. " "
  local repinInfo = repinInfo or ""
  -- 拼进 HTML 的昵称需实体转义；displayText 用于画布绘制，保持原文
  local safeDisplayText = "@" .. Helpers.ZhihuParser.escapeHtml(userName) .. " "

  local htmlTag
  if repinInfo ~= "" then
    htmlTag = '<a data-hash="' .. userId .. '" href="/people/' .. userId .. '" class="member_mention" data-repin="' .. repinInfo .. '">' .. safeDisplayText .. '</a>'
   else
    htmlTag = '<a data-hash="' .. userId .. '" href="/people/' .. userId .. '" class="member_mention">' .. safeDisplayText .. '</a>'
  end

  -- ReplacementSpan 用于显示
  local span = luajava.override(ReplacementSpan, {
    getSize = function(super, paint, cs, start, end_, fm)
      if start >= end_ then return 0 end
      -- 必须 int, 否则过桥截断会丢小数导致宽度偏窄
      return int(math.ceil(paint.measureText(displayText)))
    end,
    draw = function(super, canvas, cs, start, end_, x, top, y, bottom, paint)
      if start >= end_ then return end
      local colors = AppTheme.colors
      local originalColor = paint.color
      paint.color = colors.primary
      canvas.drawText(displayText, x, y, paint)
      paint.color = originalColor
    end,
    toString = function(super)
      return htmlTag
    end
  })

  -- ClickableSpan 用于点击
  return SpanUtil.bundle(span, SpanUtil.clickable(function()
    Router.go("people", { id = userId })
  end))
end

return M
