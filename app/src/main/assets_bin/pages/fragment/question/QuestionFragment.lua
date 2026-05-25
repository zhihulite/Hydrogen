-- pages/fragment/question/QuestionFragment.lua

local BaseFragment = require("pages.base.BaseFragment")
local QuestionModel = require("models.content.QuestionModel")
local RecyclerViewHelper = require("components.views.RecyclerViewHelper")
local WebViewHelper = require("components.views.WebViewHelper")
local BottomDialog = require("helpers.bottom_dialog")

local QuestionFragment = Extensions.Class(BaseFragment, {"question"})
QuestionFragment:chainUp("onDestroy")

function QuestionFragment:ctor()
  self.model = nil
  self.questionId = nil
  self.questionTitle = nil
  self.questionData = nil
  self.headerView = nil
  self.headerViews = nil
  self.helper = nil
  self.followMenuItem = nil
end

function QuestionFragment:onCreate(params)
  self.questionId = tostring(params.id)
  self.questionTitle = params.title
  self.model = QuestionModel(self.questionId)
end

function QuestionFragment:onDestroy()
  if self.model then self.model:destroy() end
end

function QuestionFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.question.main, self.views)
end

function QuestionFragment:initViews()
  local views = self.views

  self:setupEdgeToEdge({
    top = { self.views.main_container },
    bottom = { self.views.recycler_view },
  })

  -- 设置 toolbar，并捕获关注菜单项
  local menuIdMap = Helpers.UI.setupToolbar(views.toolbar, {
    title = self.title,
    menu = {
      { id = "share", title = "分享", click = function() self:shareQuestion() end },
      { id = "copy", title = "复制链接", click = function() self:copyQuestionLink() end },
      { id = "follow", title = "关注问题", click = function() self:toggleFollow() end },
      { id = "sort_time", title = "时间排序", click = function() self:changeSortOrder("updated") end },
      { id = "sort_default", title = "默认排序", click = function() self:changeSortOrder("default") end },
      { id = "log", title = "问题日志", click = function() self:showQuestionLog() end },
      { id = "report", title = "举报", click = function() self:reportQuestion() end },
    }
  })

  -- 存储关注菜单项
  if menuIdMap and menuIdMap.follow then
    self.followMenuItem = menuIdMap.follow
  end

  Helpers.UI.setupSwipeRefresh(views.swipe_refresh, function() self:refresh() end)

  self:initAnswerList()
  self:loadQuestionDetail()
end

function QuestionFragment:initAnswerList()
  local views = self.views

  self:createQuestionHeader()
  self.model:setupSingle(views.recycler_view, views.swipe_refresh)
  self.model:ensureLoaded()
  self.helper = RecyclerViewHelper.new(views.recycler_view.getAdapter())
  self.helper:addHeader(self.headerView)
  self.helper:setup(views.recycler_view)
end

function QuestionFragment:createQuestionHeader()
  self.headerViews = {}
  self.headerView = loadlayout(Layouts.pages.question.header, self.headerViews)
  self.headerViews.excerpt.onClick = function() self:showExcerptDetail() end
end

function QuestionFragment:updateTopics(topics)
  if not self.headerViews or not self.headerViews.topics_container then return end

  local container = self.headerViews.topics_container
  container.removeAllViews()

  if not topics or #topics == 0 then
    container.setVisibility(View.GONE)
    return
  end

  container.setVisibility(View.VISIBLE)

  for i, topic in ipairs(topics) do
    local chip = self:createTopicChip(topic)
    container.addView(chip)
    if i < #topics then
      local spacer = luajava.bindClass("android.widget.Space")(activity)
      spacer.setLayoutParams(LinearLayoutCompat.LayoutParams(8, 0))
      container.addView(spacer)
    end
  end
end

function QuestionFragment:createTopicChip(topic)
  local colors = AppTheme.getColors()
  local chip = Helpers.MaterialWidgets.Chip_Assist_Elevated(activity)
  chip.setText(topic.name)
  chip.setTextColor(colors.primary)

  chip.setOnClickListener({
    onClick = function()
      local topicId = topic.id or topic.topicId
      if topicId then Router.go("topic", { id = topicId }) end
    end
  })

  return chip
end

function QuestionFragment:showExcerptDetail()
  if not self.questionData then return end

  local detail = self.questionData.detail
  local excerpt = self.questionData.excerpt
  local content = detail or excerpt or "暂无详情"

  local views = {}
  local scrollView = loadlayout(Layouts.pages.question.excerpt_dialog, views)

  local webHelper = WebViewHelper.new(views.webview)
  webHelper:initSettings():initNoImageMode():setWebViewNetWork():setWebChromeNetWork()
  :setWebViewNetWork{
    shouldOverrideUrlLoading = function(view, url)
      Helpers.ZhihuParser.goUrl(url)
      return true
    end,
    onPageFinished = function(view, url)
      webHelper:evaluateJavascript("document.querySelectorAll('img').forEach(i=>{i.style.maxWidth='100%';i.style.height='auto'})")
    end,
  }
  :setSettings({
    debug = false, -- 关闭 eruda 调试工具
    dark_answer = true, -- 关闭回答暗色模式
    md_copy = false, -- 关闭 Markdown 复制
  })

  views.webview.loadDataWithBaseURL(nil, content, "text/html", "UTF-8", nil)

  BottomDialog.show({
    title = "问题详情",
    contentView = scrollView,
    positiveText = "关闭",
    cancelable = true,
    onPositive = function()
      if webHelper then webHelper:destroy() end
    end
  })
end

function QuestionFragment:updateQuestionCard(data)
  if not self.headerViews then return end

  self.questionData = data

  if data.author and data.author.name then
    self.headerViews.author_name.text = data.author.name .. " 提问"
    self.headerViews.author_name.setVisibility(View.VISIBLE)
    if data.author.avatarUrl then
      self.headerViews.author_avatar.setVisibility(View.VISIBLE)
      Helpers.Image.load(self.headerViews.author_avatar, data.author.avatarUrl)
    end

    local authorId = data.author.id
    self.headerViews.author_avatar.onClick = function()
      Router.go("people", { id = authorId })
    end
    self.headerViews.author_name.onClick = function()
      Router.go("people", { id = authorId })
    end
   else
    self.headerViews.author_name.setVisibility(View.GONE)
    self.headerViews.author_avatar.setVisibility(View.GONE)
  end

  self.headerViews.question_title.text = data.title or ""
  self.headerViews.answer_count.text = string.format("%d个回答", data.answerCount or 0)
  self.headerViews.follower_count.text = string.format("%d人关注", data.followerCount or 0)

  if data.topics and #data.topics > 0 then
    self:updateTopics(data.topics)
  end

  if data.excerpt and data.excerpt ~= "" then
    self.headerViews.excerpt.text = "问题描述：" .. data.excerpt
    self.headerViews.excerpt.setVisibility(View.VISIBLE)
  end

  self.views.toolbar.setTitle(data.title or self.questionTitle or "问题详情")

  -- 更新关注菜单项文本
  self:updateFollowMenuItem()
end

-- 更新关注菜单项文本
function QuestionFragment:updateFollowMenuItem()
  if not self.followMenuItem or not self.questionData then return end
  local newTitle = self.questionData.isFollowing and "取消关注" or "关注问题"
  self.followMenuItem.setTitle(newTitle)
end

function QuestionFragment:loadQuestionDetail()
  self.model:addListener("detailChanged", function(data)
    self:updateQuestionCard(data)
  end)

  self.model:loadDetail(function(success, data)
    if not success then tip("加载失败") end
  end)
end

function QuestionFragment:refresh()
  self.model:refresh(0)
  self.views.swipe_refresh.setRefreshing(false)
end

-- 修改 toggleFollow，不需要参数
function QuestionFragment:toggleFollow()
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    Router.go("login")
    return
  end

  self.model:follow(function(success)
    if success then
      tip(self.questionData.isFollowing and "已关注" or "已取消关注")
      self:updateFollowMenuItem()
     else
      tip("操作失败")
    end
  end)
end

function QuestionFragment:changeSortOrder(sortBy)
  self.model:setSortBy(sortBy)
  tip(sortBy == "default" and "已切换为默认排序" or "已切换为时间排序")
end

function QuestionFragment:shareQuestion()
  local title = (self.questionData and self.questionData.title) or self.questionTitle or ""
  Helpers.UI.shareText(string.format("【问题】%s：https://www.zhihu.com/question/%s", title, self.questionId))
end

function QuestionFragment:copyQuestionLink()
  Helpers.UI.copyText("https://www.zhihu.com/question/" .. self.questionId)
end

function QuestionFragment:showQuestionLog()
  if not self.questionId then
    tip("无法获取问题ID")
    return
  end

  local logUrl = "https://www.zhihu.com/question/" .. self.questionId .. "/log"
  Router.go("browser", { url = logUrl })
end

function QuestionFragment:reportQuestion()
  Router.go("browser", { url = "https://www.zhihu.com/report?id=" .. self.questionId .. "&type=question&source=android" })
end

return QuestionFragment