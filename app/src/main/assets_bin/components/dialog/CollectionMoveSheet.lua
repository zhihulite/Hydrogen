-- components/dialog/CollectionMoveSheet.lua
-- 收藏夹操作弹窗（选择收藏夹移动 / 自动切换默认收藏夹）

local M = {}

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.bottomsheet.BottomSheetDialog"
import "com.google.android.material.bottomsheet.BottomSheetBehavior"
import "com.google.android.material.textview.MaterialTextView"
import "android.view.View"
import "androidx.recyclerview.widget.RecyclerView"
import "androidx.recyclerview.widget.LinearLayoutManager"
import "com.google.android.material.checkbox.MaterialCheckBox"
import "com.google.android.material.divider.MaterialDivider"

local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")
local CollectionEditSheet = require("components.dialog.CollectionEditSheet")

--- 收藏夹操作
--- @param opts table
--- @param opts.contentId string 内容ID
--- @param opts.contentType string 内容类型
--- @param opts.autoToggle boolean 是否自动切换默认收藏夹（true: 自动取反第一个收藏夹，不显示对话框；false: 显示对话框让用户选择）
--- @param opts.onSuccess function(stillInAnyCollection, addedCount, removedCount) 成功回调，stillInAnyCollection 表示操作后是否还在任何收藏夹中
--- @param opts.onError function(err) 失败回调
function M.show(opts)
  if opts.autoToggle then
    M:autoToggleDefault(opts)
   else
    M:showSelectionDialog(opts)
  end
end

--- 自动切换默认收藏夹（取反操作）
function M:autoToggleDefault(opts)
  local url = "https://www.zhihu.com/api/v4/collections/contents/" .. opts.contentType .. "/" .. opts.contentId

  NetWork.get(url, Headers.defaultHead, function(code, content)
    if code ~= 200 then
      if opts.onError then
        opts.onError("获取收藏夹列表失败")
      end
      return
    end

    local data = json.decode(content)
    local collections = data.data or {}

    -- 找到默认收藏夹（第一个）
    local defaultColl = collections[1]
    if not defaultColl then
      tip("未找到收藏夹")
      if opts.onError then
        opts.onError("未找到收藏夹")
      end
      return
    end

    local isFavorited = defaultColl.is_favorited
    local action = isFavorited and "remove" or "add"
    local putUrl = "https://api.zhihu.com/collections/contents/" .. opts.contentType .. "/" .. opts.contentId
    local putData = action .. "_collections=" .. defaultColl.id

    NetWork.put(putUrl, putData, Headers.defaultHead, function(code)
      if code == 200 then
        tip(isFavorited and "已取消收藏" or "收藏成功")
        if opts.onSuccess then
          -- 计算操作后是否还在任何收藏夹中
          local stillInAnyCollection
          if action == "add" then
            -- 添加操作：肯定在收藏夹中
            stillInAnyCollection = true
           else
            -- 移除操作：检查除了默认收藏夹外，是否还有其他收藏夹
            local hasOther = false
            for i = 2, #collections do
              if collections[i].is_favorited then
                hasOther = true
                break
              end
            end
            stillInAnyCollection = hasOther
          end

          opts.onSuccess(stillInAnyCollection, action == "add" and 1 or 0, action == "remove" and 1 or 0)
        end
       else
        tip(isFavorited and "取消收藏失败" or "收藏失败")
        if opts.onError then
          opts.onError(isFavorited and "取消收藏失败" or "收藏失败")
        end
      end
    end)
  end)
end

--- 显示选择对话框
function M:showSelectionDialog(opts)
  local self = {}
  setmetatable(self, { __index = M })

  self.opts = opts
  self.views = {}
  self.collections = {}
  self.adapter = nil
  self.nextUrl = nil
  self.isLoading = false
  self.isSaving = false

  local colors = AppTheme.colors

  local layout = {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "match_parent",
    layout_height = "wrap_content",
    {
      LinearLayoutCompat,
      orientation = "vertical",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "56dp",
        gravity = "center_vertical",
        paddingLeft = "16dp",
        paddingRight = "16dp",
        {
          MaterialTextView,
          layout_width = 0,
          layout_weight = 1,
          text = "选择收藏夹",
          textSize = AppTextStyle.titleSmall.size,
          textColor = AppTextStyle.titleSmall.color,
          typeface = AppTextStyle.titleSmall.font,
        },
        {
          Helpers.MaterialWidgets.Button_Text,
          id = "new_btn",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
          text = "新建收藏夹",
          textColor = colors.primary,
        },
        {
          Helpers.MaterialWidgets.Button_Text,
          id = "close_btn",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
          text = "✕",
          textSize = "20sp",
          textColor = colors.onSurfaceVariant,
          layout_marginLeft = "8dp",
        }
      },
      {
        MaterialDivider,
        layout_width = "match_parent",
        layout_height = "1dp",
      },
      {
        LinearLayoutCompat,
        orientation = "vertical",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        layout_weight = 1,
        {
          RecyclerView,
          id = "recycler_view",
          layout_width = "match_parent",
          layout_height = "wrap_content",
        },
        {
          LinearLayoutCompat,
          id = "loading_layout",
          orientation = "horizontal",
          layout_width = "match_parent",
          layout_height = "56dp",
          gravity = "center",
          visibility = View.GONE,
          {
            MaterialTextView,
            text = " 加载中...",
            textSize = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
          }
        },
      },
      {
        MaterialDivider,
        layout_width = "match_parent",
        layout_height = "wrap_content",
      },
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
          text = "确认选择",
          cornerRadius = "12dp",
        }
      }
    }
  }

  self.root = loadlayout(layout, self.views)

  -- 关闭按钮
  self.views.close_btn.onClick = function()
    self.bottomSheet.dismiss()
  end

  -- 新建收藏夹按钮
  self.views.new_btn.onClick = function()
    CollectionEditSheet.show({
      onSuccess = function(collectionId, name)
        table.insert(self.collections, 1, {
          id = collectionId,
          title = name,
          checked = true,
          originalChecked = false,
          count = 0,
        })
        self.adapter.notifyItemInserted(0)
      end,
      onError = function(err)
        tip(err or "创建失败")
      end
    })
  end

  -- 确认按钮
  self.views.confirm_btn.onClick = function()
    if self.isSaving then return end

    local toAdd = {}
    local toRemove = {}

    for _, item in ipairs(self.collections) do
      if item.checked and not item.originalChecked then
        table.insert(toAdd, item.id)
       elseif not item.checked and item.originalChecked then
        table.insert(toRemove, item.id)
      end
    end

    if #toAdd == 0 and #toRemove == 0 then
      self.bottomSheet.dismiss()
      return
    end

    self.isSaving = true
    self.views.confirm_btn.enabled = false

    local putUrl = "https://api.zhihu.com/collections/contents/" .. self.opts.contentType .. "/" .. self.opts.contentId
    local params = {}
    if #toAdd > 0 then
      table.insert(params, "add_collections=" .. table.concat(toAdd, ","))
    end
    if #toRemove > 0 then
      table.insert(params, "remove_collections=" .. table.concat(toRemove, ","))
    end
    local putData = table.concat(params, "&")

    NetWork.put(putUrl, putData, Headers.defaultHead, function(code)
      self.isSaving = false
      self.views.confirm_btn.enabled = true

      if code == 200 then
        -- 计算操作后的收藏状态：是否至少还有一个收藏夹被选中
        local stillInAnyCollection = false
        for _, item in ipairs(self.collections) do
          -- 注意：需要排除正在删除的项，使用操作后的最终状态
          local isItemChecked = item.checked
          -- 如果该项即将被移除，则最终状态为 false
          for _, removeId in ipairs(toRemove) do
            if item.id == removeId then
              isItemChecked = false
              break
            end
          end
          if isItemChecked then
            stillInAnyCollection = true
            break
          end
        end

        tip("操作成功")
        if self.opts.onSuccess then
          -- 第三个参数：操作后是否还在任何收藏夹中
          self.opts.onSuccess(stillInAnyCollection, #toAdd, #toRemove)
        end
        self.bottomSheet.dismiss()
       else
        tip("操作失败")
        if self.opts.onError then
          self.opts.onError("操作失败")
        end
      end
    end)
  end

  -- 初始化 RecyclerView
  local lm = LinearLayoutManager(activity)
  self.views.recycler_view.layoutManager = lm

  -- 创建适配器
  self.adapter = SimpleRecyclerAdapter.new({
    items = self.collections,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate({
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        padding = "12dp",
        gravity = "center_vertical",
        onClick=function(itemView)
          local position = self.views.recycler_view.getChildAdapterPosition(itemView)
          if position ~= -1 then
            local item = self.collections[position + 1]
            if item then
              item.checked = not item.checked
            end
            self.adapter.notifyItemChanged(position)
          end
        end,
        {
          MaterialCheckBox,
          id = "checkbox",
          layout_width = "wrap_content",
          layout_height = "wrap_content",
          layout_marginRight = "12dp",
          focusable = false,
          clickable = false,
        },
        {
          LinearLayoutCompat,
          orientation = "vertical",
          layout_width = 0,
          layout_weight = 1,
          {
            MaterialTextView,
            id = "title",
            textSize = AppTextStyle.bodyMedium.size,
            textColor = AppTextStyle.bodyMedium.color,
            typeface = AppTextStyle.bodyMedium.font,
          },
          {
            MaterialTextView,
            id = "count",
            textSize = AppTextStyle.bodySmall.size,
            textColor = AppTextStyle.bodySmall.color,
            typeface = AppTextStyle.bodySmall.font,
            visibility = View.GONE,
          }
        }
      })
    end,
    onBind = function(views, item, position)
      views.title.text = item.title or ""
      views.checkbox.checked = item.checked or false
      if item.count and item.count > 0 then
        views.count.text = tostring(item.count) .. "个内容"
        views.count.visibility = View.VISIBLE
       else
        views.count.visibility = View.GONE
      end
    end
  })
  self.views.recycler_view.adapter = self.adapter

  self.bottomSheet = BottomSheetDialog(activity)
  self.bottomSheet.contentView = self.root

  local behavior = self.bottomSheet.behavior
  behavior.skipCollapsed = true
  behavior.peekHeight = -1

  self.bottomSheet.show()

  -- 加载数据
  self:loadMoreCollections()
end

function M:loadMoreCollections()
  if self.isLoading then return end

  local url = self.nextUrl
  if not url then
    url = "https://www.zhihu.com/api/v4/collections/contents/" .. self.opts.contentType .. "/" .. self.opts.contentId
  end
  if not url then return end

  self.isLoading = true
  self.views.loading_layout.visibility = View.VISIBLE

  NetWork.get(url, Headers.defaultHead, function(code, content)
    self.isLoading = false
    self.views.loading_layout.visibility = View.GONE

    if code ~= 200 then
      return
    end

    local data = json.decode(content)
    local items = data.data or {}

    for _, item in ipairs(items) do
      table.insert(self.collections, {
        id = tostring(item.id),
        title = item.title,
        count = item.item_count or 0,
        checked = item.is_favorited or false,
        originalChecked = item.is_favorited or false,
      })
    end

    self.adapter.notifyDataSetChanged()
    self.nextUrl = data.paging and data.paging.next or nil
  end)
end

return M