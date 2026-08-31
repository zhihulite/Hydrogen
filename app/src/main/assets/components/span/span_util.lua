-- components/span/span_util.lua
-- 各文本 span 的公共封装：主题色可点击 span 与多 span 打包

local M = {}

import "android.text.style.ClickableSpan"

-- 生成带主题色样式的可点击 span，onClick(widget) 为点击回调
function M.clickable(onClick)
  return luajava.override(ClickableSpan, {
    onClick = function(super, widget)
      onClick(widget)
    end,
    updateDrawState = function(super, ds)
      super.updateDrawState(ds)
      local colors = AppTheme.colors
      ds.color = colors.primary
      ds.underlineText = false
    end
  })
end

-- 把多个 span 打包成一个返回对象，setSpan 时逐个挂到同一区间
function M.bundle(...)
  local spans = {...}
  return {
    setSpan = function(editable, start, end_, flags)
      for _, s in ipairs(spans) do
        editable.setSpan(s, start, end_, flags)
      end
    end
  }
end

return M
