-- models/user/at_user_model.lua
-- @用户搜索模型（使用 PageToolModel，自带搜索和分页）

local PageToolModel = require("models.base.page_tool_model")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.imageview.ShapeableImageView"
import "android.view.View"
import "android.view.Gravity"

local AtUserModel = Extensions.Class(PageToolModel)

function AtUserModel:ctor(scene)
  self.scene = scene or "comment_editor"
  self.keyword = nil
  self.requestHeadKey = Constants.RequestHeadKeys.DEFAULT_HEAD
  self.needLogin = true
  self.onUserSelected = nil -- 用户选中回调
  self.bottomSheet = nil -- BottomSheet 引用，用于关闭
end

-- 设置搜索关键词，300ms 防抖后刷新：连续输入只触发最后一次请求，
-- 序号校验丢弃过期回调，避免先后响应乱序覆盖列表
function AtUserModel:setKeyword(keyword)
  if self.keyword == keyword then return end
  self.keyword = keyword
  self.searchSeq = (self.searchSeq or 0) + 1
  local seq = self.searchSeq
  Helpers.UI.runDelayed(300, self:runIfAlive(function()
    if seq == self.searchSeq then
      self:refresh()
    end
  end))
end

-- 获取请求 URL
function AtUserModel:getInitialUrl()
  local url = string.format("https://api.zhihu.com/people/ats?offset=0&limit=20&scene=%s", self.scene)
  if self.keyword and self.keyword ~= "" then
    url = url .. "&q=" .. NetWork.urlEncode(self.keyword)
  end
  return url
end

-- 解析数据
function AtUserModel:parseItem(rawItem, key)
  return Helpers.ZhihuItem.authorOf(rawItem)
end

-- 创建适配器（自带布局和点击事件）
function AtUserModel:createAdapter(dataList, key)

  local circleShapeModel = Helpers.Layout.circleShape()

  return SimpleRecyclerAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate({
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        gravity = Gravity.CENTER_VERTICAL,
        padding = "12dp",
        {
          ShapeableImageView,
          id = "avatar",
          layout_width = "40dp",
          layout_height = "40dp",
          shapeAppearanceModel = circleShapeModel,
        },
        {
          LinearLayoutCompat,
          orientation = "vertical",
          layout_width = 0,
          layout_weight = 1,
          layout_marginLeft = "12dp",
          Helpers.Layout.text("name", AppTextStyle.bodyMedium),
          Helpers.Layout.text("headline", AppTextStyle.bodySmall, nil, { visibility = View.GONE }),
        },
      })
    end,
    onBind = function(v, item, position, holder)
      v.name.text = item.name or ""
      if item.headline and item.headline ~= "" then
        v.headline.text = item.headline
        v.headline.visibility = View.VISIBLE
       else
        v.headline.visibility = View.GONE
      end
      Helpers.Image.load(v.avatar, item.avatarUrl)

      holder.itemView.onClick = function()
        if self.onUserSelected then
          self.onUserSelected(item.id, item.name)
        end
        if self.bottomSheet then
          self.bottomSheet.dismiss()
        end
      end
    end,
  })
end

-- 设置选中回调
function AtUserModel:setOnUserSelected(callback)
  self.onUserSelected = callback
end

-- 设置 BottomSheet 引用
function AtUserModel:setBottomSheet(sheet)
  self.bottomSheet = sheet
end

-- 销毁时清理
function AtUserModel:destroy()
  self.bottomSheet = nil
  self.onUserSelected = nil
end

return AtUserModel