-- pages/fragment/people/PeopleFragment.lua

import "com.google.android.material.tabs.TabLayout"
import "androidx.coordinatorlayout.widget.CoordinatorLayout"
import "android.view.View"
import "androidx.appcompat.widget.PopupMenu"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

local BaseFragment = require("pages.base.BaseFragment")
local PeopleModel = require("models.user.PeopleModel")
local RecyclerViewHelper = require("components.views.RecyclerViewHelper")

local PeopleFragment = Extensions.Class(BaseFragment, { "people" })

function PeopleFragment:ctor()
  self.userId = nil
  self.peopleModel = nil
  self.currentUserData = nil
  self.isFollowing = false
  self.sortHeaderHelper = nil
  self.sortViews = nil
end

function PeopleFragment:onCreate(params)
  self.userId = params.id
  self.peopleModel = PeopleModel(self.userId)

  self.peopleModel:addListener("userInfoChanged", function(data)
    self:updateUserInfo(data)
    self:setupActionButtons(data)
  end)
end

function PeopleFragment:onDestroy()
  if self.peopleModel then
    self.peopleModel:destroy()
    self.peopleModel = nil
  end
  self.sortHeaderHelper = nil
  self.sortViews = nil
end

function PeopleFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.people.main, self.views)
end

-- 收集所有需要底部导航栏避让的页面并设置 clipToPadding
function PeopleFragment:collectAllBottomViews()
  local bottomViews = {}

  -- 收集 peopleModel 中的所有 RecyclerView
  if self.peopleModel then
    for _, rv in ipairs(self.peopleModel:getAllRecyclerViews()) do
      rv.clipToPadding = false
      table.insert(bottomViews, rv)
    end
  end

  return bottomViews
end

function PeopleFragment:initViews()
  local views = self.views

  -- 收集所有需要底部避让的视图
  local bottomViews = self:collectAllBottomViews()

  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = bottomViews
  })

  Helpers.UI.setupToolbar(views.toolbar, {
    menu = {
      { id = "share", title = "分享", click = function() self:shareUser() end },
      { id = "copy", title = "复制链接", click = function() self:copyUserLink() end },
      { id = "search_content", title = "搜索内容", click = function() self:showSearchContentDialog() end },
      { id = "report", title = "举报", click = function() self:reportUser() end },
      { id = "block", title = "拉黑", click = function(menuItem) self:blockUser(menuItem) end },
    }
  })

  self:loadUserInfo()
  self:loadTabsAndInitPager()
end

function PeopleFragment:loadUserInfo()
  self.peopleModel:loadUserInfo(function(success, data)
    if success then self.isFollowing = data.isFollowing or false end
  end)
end

function PeopleFragment:updateUserInfo(data)
  local views = self.views
  if not data then return end
  self.currentUserData = data

  if views.user_name then views.user_name.text = data.name or "" end
  if views.user_signature then
    local sig = data.headline or ""
    views.user_signature.text = sig ~= "" and sig or "暂无签名"
  end
  if views.avatar then Helpers.Image.load(views.avatar, data.avatarUrl) end
  if views.voteup_count then views.voteup_count.text = self:formatNumber(data.voteupCount) .. " 获赞" end
  if views.fans_count then views.fans_count.text = self:formatNumber(data.followerCount) .. " 粉丝" end
  if views.follow_count then views.follow_count.text = self:formatNumber(data.followingCount) .. " 关注" end
  if views.toolbar then views.toolbar.title = data.name or "用户详情" end
end

function PeopleFragment:setupActionButtons(data)
  local views = self.views
  local currentUserId = Extensions.Config.get(Constants.SharedDataKeys.USER_ID)

  if currentUserId == self.userId then
    if views.follow_btn then views.follow_btn.visibility = View.GONE end
    if views.message_btn then views.message_btn.visibility = View.GONE end
  end

  if views.action_buttons then views.action_buttons.visibility = View.VISIBLE end

  if views.follow_btn then
    views.follow_btn.text = self.isFollowing and "已关注" or "关注"
    views.follow_btn.onClick = function() self:onFollowClick() end
  end
  if views.message_btn then views.message_btn.onClick = function() self:onMessageClick() end end
  if views.fans_card then views.fans_card.onClick = function() self:onFansClick() end end
  if views.follow_card then views.follow_card.onClick = function() self:onFollowListClick() end end
end

function PeopleFragment:loadTabsAndInitPager()
  self.peopleModel:loadTabs(function()
    local viewPager = self.views.view_pager
    local tabLayout = self.views.tab_layout
    if not viewPager or not tabLayout then return end

    self.peopleModel:setupTabs(viewPager, tabLayout)
    self.peopleModel:ensureLoaded()

    -- 重新收集所有 RecyclerView（因为 tabs 加载完成后才会创建）
    local bottomViews = self:collectAllBottomViews()
    -- 重新设置 EdgeToEdge bottom
    if bottomViews and #bottomViews > 0 then
      self:setupEdgeToEdge({
        bottom = bottomViews
      })
    end

    self:addSortBarToAnswerTab()
  end)
end

function PeopleFragment:addSortBarToAnswerTab()
  local answerKey = self.peopleModel:getAnswerKey()
  if not answerKey then return end

  -- 获取回答 Tab 的 RecyclerView
  local rv, sr = self.peopleModel.pageTool:getPageView(answerKey)
  if not rv then return end

  -- 获取当前 adapter
  local originalAdapter = rv.adapter
  if not originalAdapter then return end

  -- 检查是否已经添加过 Header
  if self.sortHeaderHelper then return end

  -- 创建排序栏视图
  self.sortViews = {}
  local sortBar = loadlayout(Layouts.pages.people.sort_bar, self.sortViews)

  -- 设置当前排序名称
  self.sortViews.sort_name.text = self.peopleModel:getCurrentSortName()

  -- 点击排序按钮显示选项菜单
  self.sortViews.sort_btn.onClick = function()
    self:showSortMenu()
  end

  -- 使用 RecyclerViewHelper 包装添加 Header
  self.sortHeaderHelper = RecyclerViewHelper.new(originalAdapter)
  self.sortHeaderHelper:addHeader(sortBar)
  rv.adapter = self.sortHeaderHelper:getAdapter()
end

function PeopleFragment:showSortMenu()
  local popup = PopupMenu(activity, self.sortViews.sort_btn)
  local options = self.peopleModel:getSortOptions()
  local currentIndex = self.peopleModel:getCurrentSortIndex()

  for i, option in ipairs(options) do
    popup.menu.add(0, i, i, option.name)
  end

  popup.onMenuItemClick = function(menuItem)
    local itemId = menuItem.itemId
    if itemId ~= currentIndex then
      self.sortViews.sort_name.text = options[itemId].name
      self.peopleModel:setSort(itemId, function(success)
        if success then
          tip("已切换到: " .. options[itemId].name)
        end
      end)
    end
    return true
  end
  popup.show()
end

function PeopleFragment:onFollowClick()
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    Router.go("login")
    return
  end

  local btn = self.views.follow_btn

  if self.isFollowing then
    self.peopleModel:unfollow(function(success)
      if success then
        self.isFollowing = false
        btn.text = "关注"
        tip("已取消关注")
      end
    end)
   else
    self.peopleModel:follow(function(success)
      if success then
        self.isFollowing = true
        btn.text = "已关注"
        tip("关注成功")
      end
    end)
  end
end

function PeopleFragment:onMessageClick()
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    Router.go("login")
    return
  end
  Router.go("browser", { url = "https://www.zhihu.com/messages/" .. self.userId })
end

function PeopleFragment:onFansClick()
  Router.go("people_list", {
    id = self.userId,
    type = "followers",
    title = (self.currentUserData and self.currentUserData.name or "用户") .. " 的粉丝"
  })
end

function PeopleFragment:onFollowListClick()
  Router.go("people_list", {
    id = self.userId,
    type = "followees",
    title = (self.currentUserData and self.currentUserData.name or "用户") .. " 的关注"
  })
end

function PeopleFragment:shareUser()
  local name = self.currentUserData and self.currentUserData.name or "用户"
  Helpers.UI.shareText(name .. "： https://www.zhihu.com/people/" .. self.userId)
end

function PeopleFragment:copyUserLink()
  Helpers.UI.copyText("https://www.zhihu.com/people/" .. self.userId)
end

function PeopleFragment:showSearchContentDialog()
  local views = {}
  MaterialAlertDialogBuilder(activity)
  .setTitle("搜索用户创作内容")
  .setView(loadlayout(Layouts.common.search_input, views))
  .setPositiveButton("搜索", function()
    local keyword = views.edit.text
    if keyword ~= "" then
      Router.go("search_result", {
        keyword = keyword,
        scope = "people",
        extraId = self.userId
      })
    end
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function PeopleFragment:reportUser()
  Router.go("browser", { url = "https://www.zhihu.com/report?id=" .. self.userId .. "&type=member&source=android" })
end

function PeopleFragment:blockUser(menuItem)
  if not self.currentUserData then return end

  local isBlocking = self.currentUserData.isBlocking
  local title = isBlocking and "取消拉黑" or "拉黑用户"
  local message = isBlocking and "确定要取消拉黑该用户吗？" or "确定要拉黑该用户吗？"

  MaterialAlertDialogBuilder(activity)
  .setTitle(title)
  .setMessage(message)
  .setPositiveButton("确定", function()
    local callback = function(success)
      if success then
        if isBlocking then
          tip("已取消拉黑")
          self.currentUserData.isBlocking = false
          menuItem.title = "拉黑"
         else
          tip("已拉黑")
          self.currentUserData.isBlocking = true
          menuItem.title = "取消拉黑"
        end
      end
    end

    if isBlocking then
      self.peopleModel:unblock(callback)
     else
      self.peopleModel:block(callback)
    end
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function PeopleFragment:formatNumber(num)
  if not num then return "0" end
  if num >= 100000000 then return string.format("%.1f亿", num / 100000000) end
  if num >= 10000 then return string.format("%.1f万", num / 10000) end
  return tostring(num)
end

return PeopleFragment