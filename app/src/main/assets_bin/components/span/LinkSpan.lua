-- components/span/LinkSpan.lua
local M = {}

import "android.text.style.ReplacementSpan"
import "android.text.style.ClickableSpan"
import "android.graphics.Canvas"

function M.new(url, title, iconName)
  local displayText = title or url
  local originalUrl = url
  local iconDrawable = nil
  local iconSize = dp2px(16)
  local iconSpacing = dp2px(4)

  local htmlTag = '<a href="' .. originalUrl .. '" data-insert-way="url" data-draft-type="text-link"'
  if iconName and iconName ~= "" then
    htmlTag = htmlTag .. ' data-icon-name="' .. iconName .. '"'
  end
  htmlTag = htmlTag .. ' data-draft-title="' .. displayText .. '">' .. displayText .. '</a>'

  if iconName and iconName ~= "" then
    iconDrawable = Helpers.Static.imageDrawable(iconName, iconSize, true)
    if iconDrawable then
      iconDrawable.setBounds(0, 0, iconSize, iconSize)
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
        iconDrawable.tint = colors.primary
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
  local clickSpan = luajava.override(ClickableSpan, {
    onClick = function(super, widget)
      Helpers.ZhihuParser.goUrl(originalUrl)
    end,
    updateDrawState = function(super, ds)
      super.updateDrawState(ds)
      local colors = AppTheme.colors
      ds.color = colors.primary
      ds.underlineText = false
    end
  })

  -- 返回设置函数
  return {
    setSpan = function(editable, start, end_, flags)
      editable.setSpan(span, start, end_, flags)
      editable.setSpan(clickSpan, start, end_, flags)
    end
  }
end

return M