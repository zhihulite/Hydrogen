-- components/dialog/AtUserSheet.lua
-- @用户选择面板（简洁版，Model 一把梭）

local M = {}

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.recyclerview.widget.RecyclerView"
import "androidx.recyclerview.widget.LinearLayoutManager"
import "androidx.appcompat.widget.AppCompatEditText"
import "com.google.android.material.bottomsheet.BottomSheetDialog"
import "android.view.View"

local AtUserModel = require("models.user.AtUserModel")

function M.show(opts)
  opts = opts or {}

  -- 创建 Model
  local model = AtUserModel("comment_editor")
  model:setOnUserSelected(function(userId, userName)
    if opts.onSelected then
      opts.onSelected(userId, userName)
    end
  end)

  -- 构建布局
  local views = {}
  local layout = {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    {
      AppCompatEditText,
      id = "search_input",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      hint = "搜索用户",
      layout_margin = "12dp",
      textSize = AppTextStyle.bodyMedium.size,
    },
    {
      RecyclerView,
      id = "user_list",
      layout_width = "match_parent",
      layout_height = "400dp",
    },
  }

  local root = loadlayout(layout, views)

  -- 初始化列表
  views.user_list.setLayoutManager(LinearLayoutManager(activity))
  model:setupSingle(views.user_list, nil)
  model:ensureLoaded() -- 默认加载

  -- 搜索监听
  views.search_input.addTextChangedListener({
    onTextChanged = function(text)
      local keyword = tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
      model:setKeyword(keyword)
    end
  })

  -- 创建并显示 BottomSheet
  local bottomSheet = BottomSheetDialog(activity)
  bottomSheet.setContentView(root)
  model:setBottomSheet(bottomSheet)

  -- 关闭时销毁 Model
  bottomSheet.setOnDismissListener({
    onDismiss = function()
      model:destroy()
    end
  })

  bottomSheet.show()
end

return M