-- pages/fragment/feedback/FeedbackFragment.lua
-- 反馈页面 Fragment

import "androidx.recyclerview.widget.LinearLayoutManager"
import "com.google.android.material.divider.MaterialDividerItemDecoration"

local BaseFragment = require("pages.base.BaseFragment")
local SimpleAdapter = require("components.adapter.SimpleRecyclerAdapter")

local FeedbackFragment = Extensions.Class(BaseFragment, {"feedback"})
FeedbackFragment:chainUp("onDestroy")

function FeedbackFragment:ctor()
  self.adapter = nil
  self.items = {}
end

function FeedbackFragment:onCreate(params)
  self:buildFeedbackData()
end

function FeedbackFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.feedback.main, self.views)
end

function FeedbackFragment:initViews()
  local views = self.views
  self:setupEdgeToEdge({
    top = { self.views.main_container },
    bottom = { self.views.recycler_view },
  })
  Helpers.UI.setupToolbar(views.toolbar, { title = "反馈" })
  self:initListView()
end

function FeedbackFragment:buildFeedbackData()
  self.items = {
    { type = "title", title = "提示", content = " (๑•̀ㅂ•́)و✧ 以下是一些常见问题～ 如果没有你的问题，请滑到底部戳「仍要反馈问题」哦！" },
    { type = "title", title = "权限", content = " (｡•ᴗ-)✧ Hydrogen 只会申请本地存储权限，用来保存收藏的文章啦～ 用不到的话不授予也完全没问题！" },
    { type = "title", title = "声明", content = " (￣▽￣)~* 这个应用只是个人兴趣开发，不赚钱，也不是破解版！只是一个简化浏览的小工具～ 付费内容仍需购买，版权归知乎和原作者。绝不会偷窥你的隐私，所有数据都在本地乖乖待着！" },
    { type = "title", title = "视频无法播放？页面无法加载？", content = " (；′⌒`) 视频或者页面加载不出来？试试升级系统 WebView 或者装个 Chrome 浏览器，然后在设置里点「切换 WebView」就能用 Chrome 内核啦！" },
    { type = "title", title = "软件有点卡？", content = " (´；ω；`) 因为是基于 AndroLua+ 框架跑的，性能有限可能会卡顿，请多担待啦～ 抱歉抱歉！" },
    { type = "title", title = "为什么出现乱码？", content = " (°ー°〃) 可能是账号被知乎限制登录了… 这种情况只能等平台解封，没有别的办法呢！" },
    { type = "title", title = "为什么显示不全？", content = " (｡ŏ_ŏ) 知乎在 2024 年 5 月开始对没登录的账号限制看全文了…… 所以未登录时内容会显示不全哦。" },
    { type = "title", title = "软件安不安全？", content = " (•̤̀ᵕ•̤́) 放心！通过网页登录不会保存你的账号密码，所有信息都是直接问知乎官方要的，安全得很～" },
    { type = "title", title = "为什么刷新出重复内容", content = " (╥﹏╥) 往上滑是刷新以前的内容，往下滑是加载更多。如果经常重复… 可能得清理缓存或者等下再试试啦！" },
    { type = "button", title = " (๑•̀ㅂ•́)و✧ 戳我反馈" },
  }
end

function FeedbackFragment:initListView()
  local views = self.views
  if not views.recycler_view then return end

  local titleLayout = Layouts.pages.feedback.items.title_content
  local buttonLayout = Layouts.pages.feedback.items.button

  local divider = MaterialDividerItemDecoration(activity, LinearLayoutManager.VERTICAL)
  views.recycler_view.addItemDecoration(divider)

  local selfRef = self
  self.adapter = SimpleAdapter.new({
    items = self.items,
    getItemViewType = function(position, item)
      if item.type == "title" then return 0
       elseif item.type == "button" then return 1
      end
      return 0
    end,
    onCreateView = function(viewType)
      if viewType == 0 then
        return SimpleAdapter.inflate(titleLayout)
       elseif viewType == 1 then
        return SimpleAdapter.inflate(buttonLayout)
      end
      return SimpleAdapter.inflate(titleLayout)
    end,
    onBind = function(views, item, position, holder)
      if item.type == "title" then
        views.title.text = item.title or ""
        views.content.text = item.content or ""
       elseif item.type == "button" then
        views.button.text = item.title or ""
        views.button.onClick = function()
          selfRef:openGithubIssues()
        end
      end
    end
  })

  views.recycler_view.setLayoutManager(LinearLayoutManager(activity))
  views.recycler_view.setAdapter(self.adapter)
end

function FeedbackFragment:openGithubIssues()
  Helpers.UI.openUrl("https://github.com/zhihulite/Hydrogen/issues")
end

function FeedbackFragment:onDestroy()
  if self.adapter then self.adapter = nil end
end

return FeedbackFragment