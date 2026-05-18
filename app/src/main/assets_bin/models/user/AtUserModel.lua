-- models/user/AtUserModel.lua
-- @用户搜索模型（使用 PageToolModel，自带搜索和分页）

local PageToolModel = require("models.base.PageToolModel")
local SimpleAdapter = require("components.adapter.SimpleRecyclerAdapter")

local AtUserModel = Extensions.Class(PageToolModel)
AtUserModel:chainUp("destroy")

function AtUserModel:ctor(scene)
  self.scene = scene or "comment_editor"
  self.keyword = nil
  self.requestHeadKey = "defaultHead"
  self.needLogin = true
  self.onUserSelected = nil -- 用户选中回调
  self.bottomSheet = nil -- BottomSheet 引用，用于关闭
end

-- 设置搜索关键词并刷新
function AtUserModel:setKeyword(keyword)
  self.keyword = keyword
  self:refresh()
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
  return {
    id = tostring(rawItem.id),
    name = rawItem.name,
    headline = rawItem.headline or "",
    avatarUrl = rawItem.avatar_url,
  }
end

import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.imageview.ShapeableImageView"
-- 创建适配器（自带布局和点击事件）
function AtUserModel:createAdapter(dataList, key)
  local selfRef = self
  local colors = AppTheme.getColors()

  return SimpleAdapter.new({
    items = dataList,
    onCreateView = function()
      return SimpleAdapter.inflate({
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
          shapeAppearanceModel = ShapeAppearanceModel.builder()
          .setAllCornerSizes(RelativeCornerSize(0.5))
          .build(),
        },
        {
          LinearLayoutCompat,
          orientation = "vertical",
          layout_width = "0dp",
          layout_weight = 1,
          layout_marginLeft = "12dp",
          {
            MaterialTextView,
            id = "name",
            textSize = AppTextStyle.body.size,
            textColor = AppTextStyle.body.color,
            typeface = AppTextStyle.body.font,
          },
          {
            MaterialTextView,
            id = "headline",
            textSize = AppTextStyle.caption.size,
            textColor = AppTextStyle.caption.color,
            visibility = View.GONE,
          },
        },
      })
    end,
    onBind = function(v, item, position, holder)
      v.name.text = item.name or ""
      if item.headline and item.headline ~= "" then
        v.headline.text = item.headline
        v.headline.setVisibility(View.VISIBLE)
       else
        v.headline.setVisibility(View.GONE)
      end
      Helpers.Image.load(v.avatar, item.avatarUrl)

      holder.itemView.onClick = function()
        if selfRef.onUserSelected then
          selfRef.onUserSelected(item.id, item.name)
        end
        if selfRef.bottomSheet then
          selfRef.bottomSheet.dismiss()
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
  self:super("destroy")
end

return AtUserModel