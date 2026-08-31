-- components/span/link_span.lua
-- link span

local M = {}

import "android.text.style.ReplacementSpan"

local SpanUtil = require("components.span.span_util")

function M.new(url, title, iconName)
  local displayText = title or url
  local originalUrl = url
  local iconDrawable = nil
  local ICON_DP = 16
  local iconSize = dp2px(ICON_DP)
  local iconSpacing = dp2px(4)

  local escapeHtml = Helpers.ZhihuParser.escapeHtml
  local htmlTag = '<a href="' .. escapeHtml(originalUrl) .. '" data-insert-way="url" data-draft-type="text-link"'
  if iconName and iconName ~= "" then
    htmlTag = htmlTag .. ' data-icon-name="' .. iconName .. '"'
  end
  htmlTag = htmlTag .. ' data-draft-title="' .. escapeHtml(displayText) .. '">' .. escapeHtml(displayText) .. '</a>'

  if iconName and iconName ~= "" then
    -- imageDrawable 的第二个参数是 dp，内部自行换算像素
    iconDrawable = Helpers.Static.imageDrawable(iconName, ICON_DP, true)
    if iconDrawable then
      iconDrawable.setBounds(0, 0, iconSize, iconSize)
      iconDrawable.tint = AppTheme.colors.primary
    end
  end

  -- ReplacementSpan 用于绘制
  local span = luajava.override(ReplacementSpan, {
    getSize = function(super, paint, cs, start, end_, fm)
      if start >= end_ then return 0 end
      local textWidth = paint.measureText(displayText)
      local totalWidth = textWidth
      if iconDrawable then
        totalWidth = totalWidth + iconSize + iconSpacing
      end
      -- 必须 int, 否则自动转为long
      return int(math.ceil(totalWidth))
    end,
    draw = function(super, canvas, cs, start, end_, x, top, y, bottom, paint)
      if start >= end_ then return end

      local colors = AppTheme.colors
      local originalColor = paint.color
      local currentX = x

      if iconDrawable then
        local iconTop = top + (bottom - top - iconSize) / 2
        canvas.save()
        canvas.translate(currentX, iconTop)
        iconDrawable.draw(canvas)
        canvas.restore()
        currentX = currentX + iconSize + iconSpacing
      end

      paint.color = colors.primary
      canvas.drawText(displayText, currentX, y, paint)
      paint.color = originalColor
    end,
    toString = function(super)
      return htmlTag
    end
  })

  -- ClickableSpan 用于点击
  return SpanUtil.bundle(span, SpanUtil.clickable(function()
    Helpers.ZhihuParser.goUrl(originalUrl)
  end))
end

return M