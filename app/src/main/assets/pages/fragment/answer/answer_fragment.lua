-- pages/fragment/answer/answer_fragment.lua
-- 回答页面 Fragment

import "androidx.viewpager2.widget.ViewPager2"
import "android.content.Intent"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"
import "android.view.View"
import "android.view.GestureDetector"
import "androidx.core.view.GestureDetectorCompat"
import "androidx.recyclerview.widget.RecyclerView"

local LuaPager2Adapter = luajava.bindClass("org.luajvm.android.widget.LuaPager2Adapter")

local BaseFragment = require("pages.base.base_fragment")
local AnswerModel = require("models.content.answer_model")
local WebViewHelper = require("components.views.web_view_helper")

local AnswerFragment = Extensions.Class(BaseFragment, {"answer"})

function AnswerFragment:ctor()
  self.model = nil
  self.pagerAdapter = nil
  self.pageData = {}
  self.pageOrder = {}
  self.currentAnswerId = nil
  self.currentPageIds = nil
  self.currentHelper = nil
  self.isFirstLoad = true
  self.isAdding = false
end

function AnswerFragment:onCreate(params)
  self.questionId = params.questionId
  self.answerId = tostring(params.id)
  self.currentAnswerId = self.answerId
  self.model = AnswerModel(self.answerId)
end

function AnswerFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.answer.main, self.views)
end

function AnswerFragment:setupToolbar()
  local toolbar = self.views.toolbar

  Helpers.UI.setupToolbar(toolbar, {
    title = self.title,
    menu = {
      { id = "refresh", title = "刷新", click = function()
          if self.currentHelper then
            self.currentHelper:reload()
          end
      end },
      { id = "find", title = "查找", click = function()
          local helper = self:getCurrentHelper()
          if not helper then return end
          helper:showSearchDialog()
      end },
      { id = "share", title = "分享", click = function()
          Helpers.UI.shareText("https://www.zhihu.com/answer/" .. (self.currentAnswerId or self.answerId))
      end },
      { id = "report", title = "举报", click = function()
          Router.go("report", { id = (self.currentAnswerId or self.answerId), type="answer" })
      end },
      { id = "saveAsPic", title = "以图片形式保存", click = function()
          local helper = self:getCurrentHelper()
          if not helper then return end
          helper:evaluateJavascript("captureScreen()", nil)
          tip("正在截图...")
      end },
      { id = "copyMd", title = "复制Markdown", click = function()
          local helper = self:getCurrentHelper()
          if not helper then return end
          helper:evaluateJavascript("MarkdownCopy.copy()", nil)
          tip("正在复制...")
      end },
      { id = "saveLocal", title = "保存到本地", click = function() self:saveToLocal() end },
    }
  })

  -- 使用 GestureDetectorCompat 检测双击返回顶部
  local detector = GestureDetectorCompat(activity, luajava.createProxy(GestureDetector.OnGestureListener,{
    onDown = function(e) return true end
  }))

  detector.onDoubleTap = function(e)
    if self.currentPageIds and self.currentPageIds.webview then
      local js = "var scroller = document.scrollingElement || document.documentElement || document.body; scroller.scrollTop = 0;"
      self.currentPageIds.webview.evaluateJavascript(js, nil)
      self.views.appbar.setExpanded(true, true)
    end
    return true
  end

  toolbar.onTouch = function(v, event)
    return detector.onTouchEvent(event)
  end

  local collapsingToolbar = self.views.collapsing_toolbar
  collapsingToolbar.onClick = function()
    if self.questionId then
      Router.go("question", { id = self.questionId })
    end
  end
end

function AnswerFragment:onBridgeMessage(action, data)
  -- 桥回调跑在 WebView 的 JavaBridge 线程，写 ViewPager2 会连带改无障碍 action 列表，必须切主线程
  if action == "disableParentScroll" then
    activity.runOnUiThread(self:runIfAlive(function()
      self.views.view_pager.userInputEnabled = false
    end))
   elseif action == "enableParentScroll" then
    activity.runOnUiThread(self:runIfAlive(function()
      self.views.view_pager.userInputEnabled = true
    end))
   elseif action == "screenshotResult" then
    activity.runOnUiThread(self:runIfAlive(function()
      self:showScreenshotPreview(data)
    end))
  end
end

function AnswerFragment:showScreenshotPreview(base64)
  -- 解码在 IO 线程进行，期间用户可能翻页，据此固定截图所属的回答
  local answerId = self.currentAnswerId
  local pageIds = self.currentPageIds

  Helpers.Screenshot.decodeBase64(base64, self:runIfAlive(function(bmp)
    -- 解码期间翻了页，位图属于旧回答，与当前页的卡片高度和作者信息不匹配
    if answerId ~= self.currentAnswerId then
      bmp.recycle()
      return
    end

    -- 截图回调与页面销毁存在竞态，视图表已清空时放弃本次合成
    if not pageIds or not pageIds.user_card_wrapper then
      bmp.recycle()
      return
    end

    -- 裁剪高度取自 user_card_wrapper，须先把卡片高度同步成网页 paddingTop
    self:updateWebViewPadding(pageIds)

    Helpers.Screenshot.composeAndPreview(bmp, {
      cropTop = pageIds.user_card_wrapper.height,
      title = self.views.toolbar.title,
      author = pageIds.user_name.text,
      avatar = pageIds.user_avatar.drawable,
      shareUrl = "https://www.zhihu.com/answer/" .. (answerId or ""),
      fileName = "zhihu_answer_" .. os.time() .. ".jpg",
      onDismiss = self:runIfAlive(function()
        local webview = pageIds.webview
        if webview then webview.scrollBy(0, 1) end
      end),
    })
  end))
end

-- 保存到本地
function AnswerFragment:saveToLocal()
  local webView = self.currentPageIds and self.currentPageIds.webview
  if not webView then
    tip("无法获取当前页面")
    return
  end

  local url = webView.url
  if not url or url == "" then
    tip("无法获取当前页面URL")
    return
  end

  local toolbar = self.views.toolbar
  local title = toolbar.title
  local id = self.currentAnswerId
  local authorText = "未知作者"
  authorText = self.currentPageIds.user_name.text

  Router.go("local_content", {
    mode = "save",
    url = url,
    title = title,
    id = id,
    author = authorText,
    -- 同一页内所有回答共享同一 questionId；为 nil（问题信息未回填）时本地不落该字段
    questionId = self.questionId
  })
end

function AnswerFragment:getCurrentHelper()
  if not self.currentHelper then
    tip("无法获取当前页面")
    return nil
  end
  return self.currentHelper
end

function AnswerFragment:updateToolbar(title, answerCount)
  local toolbar = self.views.toolbar
  toolbar.title = title or ""
  toolbar.subtitle = answerCount and ("共" .. answerCount .. "个回答") or ""
end

function AnswerFragment:loadQuestionInfo()
  self.model:loadQuestionInfo(function(question)
    if question then
      self.questionId = question.id
      self:updateToolbar(question.title, question.answer_count)
    end
  end)
end

-- 底部栏
function AnswerFragment:setupBottomBar()
  local views = self.views
  views.vote_btn.onClick = function() self:onVote() end
  views.thank_btn.onClick = function() self:onThank() end
  views.comment_btn.onClick = function() self:onComment() end
  -- 收藏按钮：点击弹出选择对话框，长按自动切换默认收藏夹
  views.collect_btn.onClick = function() self:onCollect(false) end
  views.collect_btn.onLongClick = function() self:onCollect(true) return true end
end

function AnswerFragment:updateBottomBar(data)
  local views = self.views
  if not data then error("updateBottomBar 传入 data 为空。") return end

  views.vote_count.text = tostring(data.voteupCount or 0)
  views.thank_count.text = tostring(data.thanksCount or 0)
  views.comment_count.text = tostring(data.commentCount or 0)
  views.collect_count.text = tostring(data.favlistsCount or 0)
  views.vote_icon.imageBitmap = Helpers.Static.materialIcon(data.isLiked and "twotone_thumb_up" or "outline_thumb_up")
  views.thank_icon.imageBitmap = Helpers.Static.materialIcon(data.isThanked and "twotone_favorite" or "outline_favorite_border")
  views.collect_icon.imageBitmap = Helpers.Static.materialIcon(data.isFavorited and "twotone_bookmark" or "outline_bookmark_border")
end

-- 滚动联动
function AnswerFragment:onWebViewScroll(pageIds, scrollX, scrollY, oldScrollX, oldScrollY)
  if pageIds ~= self.currentPageIds then return end

  local answerId = self.currentAnswerId
  local cardHeight = 0
  if answerId and self.pageData[answerId] then
    cardHeight = self.pageData[answerId].cardHeight or 0
  end

  if cardHeight == 0 and pageIds.user_card_wrapper then
    cardHeight = pageIds.user_card_wrapper.height
    if answerId and self.pageData[answerId] then
      self.pageData[answerId].cardHeight = cardHeight
    end
  end

  local translation = math.min(scrollY, cardHeight)
  if pageIds and pageIds.user_card_wrapper then
    pageIds.user_card_wrapper.translationY = -translation
  end
end

function AnswerFragment:updateWebViewPadding(pageIds)
  if not pageIds or not pageIds.webview or not pageIds.user_card_wrapper then return end

  local answerId = self.currentAnswerId
  local cardHeight = 0
  if answerId and self.pageData[answerId] then
    cardHeight = self.pageData[answerId].cardHeight or 0
  end
  if cardHeight == 0 then
    cardHeight = pageIds.user_card_wrapper.height
  end

  if cardHeight > 0 then
    local dp = cardHeight / activity.resources.displayMetrics.density
    pageIds.webview.evaluateJavascript("document.body.style.paddingTop='" .. dp .. "px'", nil)
  end
end

function AnswerFragment:setupWebView(webview, answerId, pageIds)
  webview.onScrollChange = function(view, sx, sy, osx, osy)
    self:onWebViewScroll(pageIds, sx, sy, osx, osy)
  end

  local helper = WebViewHelper.new(webview)
  helper:initSettings():setZhiHuUA():initNoImageMode():initDownloadListener()
  -- 设置回答页配置
  helper:setSettings({
    pageType = "answer",
    -- 开始记录历史记录
    enable_scroll_tracking = self.isFirstLoad,
    answer_code_no_scroll = Extensions.Config.getBool(Constants.SharedDataKeys.ANSWER_SINGLE_PAGE),
    enable_screenshot = true
  })
  helper:setMessageListener(function(action, data)
    self:onBridgeMessage(action, data)
  end)

  helper:setWebViewClient({
    shouldOverrideUrlLoading = function(view, url)
      if url ~= ("https://www.zhihu.com/appview/answer/" .. answerId) then
        Router.go("browser", { url = url })
        return true
      end
      return false
    end,
    onPageFinished = function(view, url)
      self:updateWebViewPadding(pageIds)
      pageIds.progress.visibility = View.GONE
      pageIds.webview.visibility = View.VISIBLE
      -- 加载完成才置 loaded：loadWebView 的 guard 靠这两个标志判重，
      -- 不复位会让该回答页在同一进程内永远无法再次加载。
      local page = self.pageData[answerId]
      if page then
        page.loaded = true
        page.loading = false
        -- 视频附件注入必须等页面真实加载完：WebView 尚在 about:blank 时
        -- evaluateJavascript 跑在 window.VideoAnswer 出现之前，静默 no-op
        if page.data and page.data.attachmentUrl then
          self:handleVideoAttachment(pageIds, page.data)
        end
      end
    end,
    onReceivedError = function(view, errorCode, description, failingUrl)
      -- 失败只复位 loading、不置 loaded：使重试可行，同时不把失败当成已加载。
      local page = self.pageData[answerId]
      if page then page.loading = false end
      if pageIds.progress then pageIds.progress.visibility = View.GONE end
    end
  })
  helper:setWebChromeClient({
    onProgressChanged = function(view, newProgress)
      if newProgress < 100 then
        pageIds.progress.progress = newProgress
        if pageIds.progress.visibility ~= View.VISIBLE then
          pageIds.progress.visibility = View.VISIBLE
        end
       else
        pageIds.progress.visibility = View.GONE
      end
    end,
  })
  -- 存入 pageData
  if self.pageData[answerId] then
    self.pageData[answerId].helper = helper
  end
end

-- ViewPager2
function AnswerFragment:setupViewPager2()
  local viewPager = self.views.view_pager

  -- 检查是否启用回答单页模式
  if Extensions.Config.getBool(Constants.SharedDataKeys.ANSWER_SINGLE_PAGE) then
    viewPager.userInputEnabled = false
  end

  -- 调整滑动灵敏度
  local scrollSense = Extensions.Config.getNumber(Constants.SharedDataKeys.SCROLL_SENSE)

  -- 反射修改 viewpager2 滑动灵敏度
  local recyclerViewField = ViewPager2.getDeclaredField("mRecyclerView")
  recyclerViewField.accessible = true
  local recyclerView = recyclerViewField.get(viewPager)

  local touchSlopField = RecyclerView.getDeclaredField("mTouchSlop")
  touchSlopField.accessible = true
  local touchSlop = touchSlopField.get(recyclerView)
  -- 必须使用 int
  touchSlopField.setInt(recyclerView, int(touchSlop * scrollSense))

  viewPager.offscreenPageLimit = 2

  self.pagerAdapter = LuaPager2Adapter()
  viewPager.adapter = self.pagerAdapter

  viewPager.registerOnPageChangeCallback(luajava.override(ViewPager2.OnPageChangeCallback, {
    onPageSelected = function(super, pos) self:onPageSelected(pos) end
  }))

  self:addPage(self.answerId)
end

function AnswerFragment:addPage(answerId)
  local id = tostring(answerId)
  if self.pageData[id] then return end
  self.pageData[id] = { loaded = false, loading = false, data = nil, ids = nil, cardHeight = 0 }
  table.insert(self.pageOrder, id)
  self.pagerAdapter.add(self:createPageView(id))
end

function AnswerFragment:insertPageAt(position, answerId)
  local id = tostring(answerId)
  if self.pageData[id] then return end
  self.pageData[id] = { loaded = false, loading = false, data = nil, ids = nil, cardHeight = 0 }
  table.insert(self.pageOrder, position, id)
  self.pagerAdapter.add(position - 1, self:createPageView(id))
end

-- 创建页面：加载作者信息 → 测量卡片高度 → 加载WebView
function AnswerFragment:createPageView(answerId)
  local pageIds = {}
  local view = loadlayout(Layouts.pages.answer.page_item, pageIds)
  self.pageData[answerId].ids = pageIds

  self:setupWebView(pageIds.webview, answerId, pageIds)

  -- 加载作者信息
  self.model:loadAnswer(answerId, function(success, answerData)
    if not self.views or not self.pageData[answerId] then return end

    if success then
      self.pageData[answerId].data = answerData
      self:updatePageCard(pageIds, answerData)

      -- 如果是当前页，更新底部栏
      if answerId == self.currentAnswerId then
        self:updateBottomBar(answerData)
      end
    end

    -- 测量卡片高度后加载WebView
    pageIds.user_card_wrapper.post({
      run = self:runIfAlive(function()
        local cardHeight = pageIds.user_card_wrapper.height
        self.pageData[answerId].cardHeight = cardHeight
        self:loadWebView(answerId, pageIds)
      end)
    })

    -- 超时保护：1秒后还没加载就直接加载
    Helpers.UI.runDelayed(1000, self:runIfAlive(function()
      if self.pageData[answerId] and not self.pageData[answerId].loading then
        self:loadWebView(answerId, pageIds)
      end
    end))
  end)

  return view
end

-- 统一的加载WebView方法
function AnswerFragment:loadWebView(answerId, pageIds)
  local page = self.pageData[answerId]
  if not page or page.loaded or page.loading then return end

  page.loading = true

  if pageIds.progress then
    pageIds.progress.visibility = View.VISIBLE
  end

  pageIds.webview.loadUrl("https://www.zhihu.com/appview/answer/" .. answerId)

  -- 预加载相邻回答（仅首次）
  if self.isFirstLoad and answerId == self.answerId then
    self.isFirstLoad = false
    local prevId = self.model:getPrevAnswerId(answerId)
    local nextId = self.model:getNextAnswerId(answerId)

    if prevId and not self.pageData[tostring(prevId)] then
      self:insertPageAt(1, prevId)
      self.views.view_pager.setCurrentItem(1, false)
    end
    if nextId and not self.pageData[tostring(nextId)] then
      self:addPage(nextId)
    end
  end
end

function AnswerFragment:updatePageCard(pageIds, data)
  if not pageIds or not data then return end

  if pageIds.user_card then
    pageIds.user_card.onClick = function()
      local author = data.author
      if author and author.id then
        Router.go("people", { id = author.id, data = author })
      end
    end
  end

  if pageIds.user_name then
    pageIds.user_name.text = data.author and data.author.name or "未知用户"
  end
  if pageIds.user_headline then
    local headline = (data.author and data.author.headline) or ""
    if headline == "" then headline = "Ta还没有签名哦~" end
    pageIds.user_headline.text = headline
  end
  if pageIds.user_avatar and data.author then
    Helpers.Image.load(pageIds.user_avatar, data.author.avatarUrl)
  end
end

-- 处理视频回答
function AnswerFragment:handleVideoAttachment(pageIds, data)
  -- onPageFinished 触发时数据可能仍在飞行中（超时兜底先 loadWebView 的场景），静默跳过：
  -- 后续 loadAnswer 回调到达时 data 已存 page，但页面已加载完不会再触发注入，
  -- 该场景由 onBridgeMessage 之外无恢复点，接受此竞态（视频回答占比低且超时是兜底路径）
  if not data then return end

  local attachmentUrl = data.attachmentUrl
  if not attachmentUrl then return end

  local js = string.format(
  "if(window.VideoAnswer){window.VideoAnswer.setVideoUrl('%s');window.VideoAnswer.init();}",
  attachmentUrl
  )
  pageIds.webview.evaluateJavascript(js, nil)
end

function AnswerFragment:tryAddAdjacent(answerId)
  if self.isAdding then return end
  local idx = nil
  for i, id in ipairs(self.pageOrder) do
    if id == answerId then idx = i break end
  end
  if not idx then return end

  self.isAdding = true

  if idx == 1 then
    local prevId = self.model:getPrevAnswerId(answerId)
    if prevId and not self.pageData[tostring(prevId)] then
      self:insertPageAt(1, prevId)
    end
  end

  if idx == #self.pageOrder then
    local nextId = self.model:getNextAnswerId(answerId)
    if nextId and not self.pageData[tostring(nextId)] then
      self:addPage(nextId)
    end
  end

  self.isAdding = false
end

function AnswerFragment:onPageSelected(pos)
  local answerId = self.pageOrder[pos + 1]
  if not answerId then return end
  self.currentAnswerId = answerId
  local page = self.pageData[answerId]
  if page then
    self.currentPageIds = page.ids
    self.currentHelper = page.helper
    if page.data then
      self:updateBottomBar(page.data)
    end
  end
  self:tryAddAdjacent(answerId)
end

function AnswerFragment:getCurrentData()
  local page = self.pageData[self.currentAnswerId]
  return page and page.data
end

function AnswerFragment:onVote()
  local data = self:getCurrentData()
  if not data then return end

  self.model:like(self.currentAnswerId, data.isLiked, function(success, isUp)
    if success then
      data.isLiked = isUp
      data.voteupCount = data.voteupCount + (isUp and 1 or -1)
      self:updateBottomBar(data)
      tip(isUp and "点赞成功" or "取消点赞")
    end
  end)
end

function AnswerFragment:onThank()
  local data = self:getCurrentData()
  if not data then return end

  self.model:thank(self.currentAnswerId, data.isThanked, function(success, isThank)
    if success then
      data.isThanked = isThank
      data.thanksCount = data.thanksCount + (isThank and 1 or -1)
      self:updateBottomBar(data)
      tip(isThank and "感谢成功" or "取消感谢")
    end
  end)
end

function AnswerFragment:onComment()
  if self.currentAnswerId then
    local CommentSheet = require("components.dialog.comment_sheet")
    CommentSheet.show({ contentId = self.currentAnswerId, contentType = "answer" })
  end
end

function AnswerFragment:onCollect(autoToggle)
  local data = self:getCurrentData()
  if not data then
    tip("无法获取回答信息")
    return
  end

  local CollectionMoveSheet = require("components.dialog.collection_move_sheet")
  CollectionMoveSheet.show({
    contentId = self.currentAnswerId,
    contentType = "answer",
    autoToggle = autoToggle or false,
    onSuccess = self:runIfAlive(function(stillInAnyCollection, addCount)
      if stillInAnyCollection then
        data.favlistsCount = (data.favlistsCount or 0) + 1
        data.isFavorited = true
       else
        data.favlistsCount = (data.favlistsCount or 0) - 1
        data.isFavorited = false
      end
      self:updateBottomBar(data)

      local msg = addCount > 0
      and (autoToggle and "已收藏到默认收藏夹" or "已添加到收藏夹")
      or (autoToggle and "已从默认收藏夹取消收藏" or "已从收藏夹移除")
      tip(msg)
    end),
    onError = self:runIfAlive(function(err)
      tip(err or "操作失败")
    end)
  })
end

function AnswerFragment:setupFloatButtons()
  local views = self.views

  -- 根据配置显示/隐藏
  if Extensions.Config.getBool(Constants.SharedDataKeys.SHOW_VIRTUAL_SCROLL) then
    views.float_scroll_container.visibility = View.VISIBLE
   else
    return
  end

  local function scrollWebView(direction)
    if not self.currentPageIds or not self.currentPageIds.webview then return end

    local webview = self.currentPageIds.webview

    if direction == "up" then
      -- 向上：获取当前滚动位置
      webview.evaluateJavascript("window.scrollY", {
        onReceiveValue = function(scrollY)
          local currentScroll = tonumber(scrollY) or 0
          if currentScroll <= 0 then
            -- 在顶部：展开 AppBar
            self.views.appbar.setExpanded(true, true)
           else
            -- 不在顶部：向上滚动一屏
            webview.evaluateJavascript("window.scrollBy(0, -window.innerHeight)", nil)
          end
        end
      })
     else -- direction == "down"
      -- 向下：滚动一屏 + 收缩 AppBar
      webview.evaluateJavascript("window.scrollBy(0, window.innerHeight)", nil)
      self.views.appbar.setExpanded(false, true)
    end
  end

  views.scroll_up.onClick = function() scrollWebView("up") end
  views.scroll_down.onClick = function() scrollWebView("down") end
end

function AnswerFragment:initViews()
  local views = self.views
  self:setupEdgeToEdge({
    top = {views.appbar},
    bottom = {
      -- 浮动滚动按钮避让导航栏
      { view = views.float_scroll_container, useMargin = true }
      -- 浮动工具栏 floating_toolbar 是 FloatingToolbarLayout，会自动处理 EdgeToEdge ，无需设置 bottomMargin。
      -- ViewPager2 底部暂不留出导航栏间距
    },
  })

  self:setupToolbar()
  self:setupBottomBar()
  self:setupViewPager2()
  self:setupFloatButtons()
  views.floating_toolbar.onGenericMotion = function()
    return false
  end
  views.float_scroll_container.onGenericMotion = function()
    return false
  end

  self:loadQuestionInfo()
end

function AnswerFragment:onVolumeUp()
  -- 检查是否开启音量键切换
  if not Extensions.Config.getBool(Constants.SharedDataKeys.VOLUME_SWITCH_TAB) then
    return false
  end

  local viewPager = self.views.view_pager
  local current = viewPager.currentItem
  if current > 0 then
    viewPager.setCurrentItem(current - 1, true)
    return true
  end
  return false
end

function AnswerFragment:onVolumeDown()
  -- 检查是否开启音量键切换
  if not Extensions.Config.getBool(Constants.SharedDataKeys.VOLUME_SWITCH_TAB) then
    return false
  end

  local viewPager = self.views.view_pager
  local current = viewPager.currentItem
  local adapter = viewPager.adapter
  if adapter and current < adapter.itemCount - 1 then
    viewPager.setCurrentItem(current + 1, true)
    return true
  end
  return false
end

function AnswerFragment:onResume()
  if _G.VolumeController and _G.VolumeController.setActive then
    _G.VolumeController.setActive(self)
  end
  if self.currentPageIds and self.currentPageIds.webview then
    self.currentPageIds.webview.setLayerType(View.LAYER_TYPE_NONE, nil)
  end
end

function AnswerFragment:onPause()
  if _G.VolumeController and _G.VolumeController.activeFragment == self then
    _G.VolumeController.setActive(nil)
  end
  if self.currentPageIds and self.currentPageIds.webview then
    self.currentPageIds.webview.setLayerType(View.LAYER_TYPE_HARDWARE, nil)
  end
end

function AnswerFragment:onDestroy()
  for _, page in pairs(self.pageData) do
    if page.helper then
      page.helper:destroy()
    end
  end
  self.pageData = {}
  if self.model then
    self.model:destroy()
  end
end

return AnswerFragment