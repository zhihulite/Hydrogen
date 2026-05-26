-- components/dialog/ColumnMoveSheet.lua
-- 选择专栏 BottomSheet（用于将内容移动到专栏）

local M = {}

import "android.view.Gravity"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.recyclerview.widget.LinearLayoutManager"
import "androidx.recyclerview.widget.RecyclerView"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.bottomsheet.BottomSheetDialog"
import "com.google.android.material.divider.MaterialDivider"

local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

--- 显示专栏选择 BottomSheet（将内容移动到专栏）
--- @param options table
---   options.contentId   string 内容 ID
---   options.contentType string 内容类型 (answer/article)
---   options.onSuccess   function(columnId, columnTitle)|nil
---   options.onError     function(err)|nil
function M.show(options)
  options = options or {}

  local contentId = tostring(options.contentId or "")
  local contentType = options.contentType or "answer"

  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用本功能")
    return
  end

  local selectedColumnId
  local selectedColumnTitle = ""
  local tipView
  local adapter = nil
  local dataList = {}
  local nextUrl = nil

  local headers = Headers["app"] or {}
  local colors = AppTheme.colors

  -- 弹窗布局（对齐 CollectionMoveSheet 风格）
  local dialogViews = {}
  local layout = {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    -- 标题栏
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "match_parent",
      layout_height = "56dp",
      gravity = Gravity.CENTER_VERTICAL,
      paddingLeft = "16dp",
      paddingRight = "16dp",
      {
        MaterialTextView,
        layout_width = 0,
        layout_weight = 1,
        text = "选择专栏",
        textSize = AppTextStyle.titleSmall.size,
        textColor = AppTextStyle.titleSmall.color,
        typeface = AppTextStyle.titleSmall.font,
      },
      {
        Helpers.MaterialWidgets.Button_Text,
        id = "new_btn",
        text = "新建专栏",
        textColor = colors.primary,
        textSize = AppTextStyle.bodySmall.size,
      },
      {
        Helpers.MaterialWidgets.Button_Text,
        id = "close_btn",
        text = "✕",
        textColor = colors.onSurfaceVariant,
        textSize = "20sp",
        layout_marginLeft = "8dp",
      }
    },
    -- 分割线
    {
      MaterialDivider,
      layout_width = "match_parent",
      layout_height = "wrap_content",
    },
    -- 选中提示
    {
      MaterialTextView,
      id = "tip",
      text = "待选中专栏",
      textSize = AppTextStyle.bodySmall.size,
      textColor = AppTextStyle.bodySmall.color,
      typeface = AppTextStyle.bodySmall.font,
      gravity = Gravity.CENTER,
      padding = "12dp",
    },
    -- 专栏列表
    {
      RecyclerView,
      id = "recycler",
      layout_width = "match_parent",
      layout_height = "400dp",
    },
    -- 分割线
    {
      MaterialDivider,
      layout_width = "match_parent",
      layout_height = "wrap_content",
    },
    -- 确认按钮
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      padding = "16dp",
      {
        MaterialButton,
        id = "confirm_btn",
        layout_width = "match_parent",
        layout_height = "48dp",
        text = "移动到专栏",
        cornerRadius = "12dp",
      }
    }
  }

  local root = loadlayout(layout, dialogViews)
  tipView = dialogViews.tip
  local recyclerView = dialogViews.recycler

  -- 关闭按钮
  dialogViews.close_btn.onClick = function()
    if bottomSheet then bottomSheet.dismiss() end
  end

  -- 新建专栏
  dialogViews.new_btn.onClick = function()
    Router.go("browser", { url = "https://www.zhihu.com/column/request" })
    tip("请自行在浏览器中创建专栏")
  end

  -- 适配器
  adapter = SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate({
        LinearLayoutCompat,
        orientation = "vertical",
        layout_width = "match_parent",
        padding = "16dp",
        {
          MaterialTextView,
          id = "title",
          layout_width = "match_parent",
          textSize = AppTextStyle.bodyMedium.size,
          textColor = AppTextStyle.bodyMedium.color,
          typeface = AppTextStyle.bodyMedium.font,
          ellipsize = "end",
          maxLines = 1,
        },
      })
    end,
    onBind = function(views, item, position, holder)
      views.title.text = item.title or ""

      holder.itemView.onClick = function()
        selectedColumnId = item.id
        selectedColumnTitle = item.title
        tipView.text = "当前选中专栏：" .. selectedColumnTitle
      end
    end,
  })

  recyclerView.layoutManager = LinearLayoutManager(activity)
  recyclerView.adapter = adapter

  -- 加载专栏列表（分页）
  local function loadColumns()
    local url = nextUrl or "https://api.zhihu.com/members/" .. Extensions.Config.get(Constants.SharedDataKeys.USER_ID) .. "/owned-columns?type=" .. contentType .. "&id=" .. contentId

    NetWork.get(url, headers, function(code, content)
      if code ~= 200 then
        tip("专栏列表加载失败")
        if options.onError then options.onError("专栏列表加载失败") end
        return
      end

      local result = json.decode(content)
      if not result or not result.data then return end

      for _, v in ipairs(result.data) do
        table.insert(dataList, {
          id = tostring(v.id),
          title = v.title
        })
      end

      adapter.notifyDataSetChanged()

      if result.paging and not result.paging.is_end then
        nextUrl = result.paging.next
        loadColumns()
      end
    end)
  end

  loadColumns()

  -- BottomSheet 对话框
  local bottomSheet = BottomSheetDialog(activity)
  bottomSheet.contentView = root

  -- 确认按钮
  dialogViews.confirm_btn.onClick = function()
    if not selectedColumnId then
      tip("请先选中一个专栏")
      return
    end

    local postUrl = "https://api.zhihu.com/" .. contentType .. "s/" .. contentId .. "/republish"
    local postData = json.encode({ action = "create", column = selectedColumnId })

    NetWork.post(postUrl, postData, headers, function(code, _)
      if code == 200 then
        tip("已移动到专栏：" .. selectedColumnTitle)
        if options.onSuccess then options.onSuccess(selectedColumnId, selectedColumnTitle) end
       else
        tip("移动失败")
        if options.onError then options.onError("移动失败") end
      end
      bottomSheet.dismiss()
    end)
  end

  bottomSheet.show()
end

return M