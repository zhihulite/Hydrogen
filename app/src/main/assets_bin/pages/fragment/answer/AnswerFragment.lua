-- pages/fragment/answer/AnswerFragment.lua

import "android.view.MenuItem"
import "androidx.viewpager2.widget.ViewPager2"
import "android.util.Base64"
import "android.graphics.Bitmap"
import "android.graphics.BitmapFactory"
import "android.graphics.Canvas"
import "android.graphics.Paint"
import "android.graphics.BitmapShader"
import "android.graphics.Matrix"
import "android.graphics.Shader"
import "java.io.ByteArrayInputStream"
import "android.content.Intent"
import "androidx.core.content.FileProvider"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"
import "android.view.View"

local BaseFragment = require("pages.base.BaseFragment")
local AnswerModel = require("models.content.AnswerModel")
local WebViewHelper = require("components.views.WebViewHelper")

local AnswerFragment = Extensions.Class(BaseFragment, {"AnswerFragment"})

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
  self.answerId = tostring(params.answerId)
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
          Router.go("browser", { url = "https://www.zhihu.com/report?id=" .. (self.currentAnswerId or self.answerId) .. "&type=answer&source=android" })
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
  import "androidx.core.view.GestureDetectorCompat"
  local detector = GestureDetectorCompat(activity, luajava.createProxy("android.view.GestureDetector$OnGestureListener",{
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
  if action == "disableParentScroll" then
    self.views.view_pager.userInputEnabled = false
   elseif action == "enableParentScroll" then
    self.views.view_pager.userInputEnabled = true
   elseif action == "screenshotResult" then
    activity.runOnUiThread(function()
      self:showScreenshotPreview(data)
    end)
  end
end

function AnswerFragment:showScreenshotPreview(base64)
  -- 解码 base64
  if not base64 or #base64 < 30 then
    tip("截图失败：数据为空")
    return
  end

  local bmp = BitmapFactory.decodeStream(ByteArrayInputStream(Base64.decode(base64, Base64.DEFAULT)))
  if not bmp then
    tip("截图解码失败")
    return
  end

  -- 强制同步网页 paddingTop（确保 user_card_wrapper 高度已应用到 WebView）
  self:updateWebViewPadding(self.currentPageIds)

  -- 获取需要裁剪的顶部高度（user_card_wrapper 的高度，单位 px）
  local cropHeight = 0
  cropHeight = self.currentPageIds.user_card_wrapper.height

  if cropHeight > 0 and cropHeight < bmp.height then
    local cropped = Bitmap.createBitmap(bmp, 0, cropHeight, bmp.width, bmp.height - cropHeight)
    bmp.recycle()
    bmp = cropped
  end

  local width = bmp.width

  -- 标题栏布局
  local headerIds = {}
  local colors = AppTheme.colors
  local headerLayout = loadlayout(Layouts.pages.answer.screenshot_header, headerIds)

  -- 获取标题和作者
  local titleText = ""
  titleText = self.views.toolbar.title
  local authorText = self.currentPageIds.user_name.text

  headerIds.title.text = titleText
  headerIds.author.text = authorText

  -- 圆形转换函数（输入 Bitmap，输出正方形圆形 Bitmap）
  local function toCircleBitmap(original)
    if original == nil then
      return nil
    end
    local size = math.min(original.width, original.height)
    local output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    local canvas = Canvas(output)
    local paint = Paint(Paint.ANTI_ALIAS_FLAG)
    local shader = BitmapShader(original, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
    local matrix = Matrix()
    local scale = size / math.max(original.width, original.height)
    matrix.setScale(scale, scale)
    if original.width > original.height then
      matrix.postTranslate((size - original.width * scale) / 2, 0)
     else
      matrix.postTranslate(0, (size - original.height * scale) / 2)
    end
    shader.localMatrix = matrix
    paint.shader = shader
    canvas.drawCircle(size / 2, size / 2, size / 2, paint)
    return output
  end

  -- 设置头像（圆形）
  local avatarDrawable = self.currentPageIds.user_avatar.drawable
  if avatarDrawable then
    local w = avatarDrawable.intrinsicWidth
    local h = avatarDrawable.intrinsicHeight
    if w > 0 and h > 0 then
      local src = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
      local canvas = Canvas(src)
      avatarDrawable.setBounds(0, 0, w, h)
      avatarDrawable.draw(canvas)
      local circle = toCircleBitmap(src)
      if circle then
        headerIds.avatar.imageBitmap = circle
      end
      src.recycle()
    end
  end

  -- 测量标题栏实际高度
  local widthSpec = View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY)
  local heightSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
  headerLayout.measure(widthSpec, heightSpec)
  local headerHeight = headerLayout.measuredHeight

  -- 合成最终图片
  local result = Bitmap.createBitmap(width, bmp.height + headerHeight, Bitmap.Config.ARGB_8888)
  local canvas = Canvas(result)

  -- 绘制标题栏
  headerLayout.layout(0, 0, width, headerHeight)
  headerLayout.draw(canvas)

  -- 绘制原截图（标题栏下方）
  canvas.drawBitmap(bmp, 0, headerHeight, nil)
  bmp.recycle()

  -- 预览对话框
  local previewIds = {}
  local previewLayout = loadlayout(Layouts.pages.answer.screenshot_preview, previewIds)
  Helpers.Image.load(previewIds.iv, result)

  MaterialAlertDialogBuilder(activity)
  .setTitle("预览")
  .setView(previewLayout)
  .setPositiveButton("确认并分享", function()
    Helpers.UI.shareBitmap(result, "zhihu_answer_" .. os.time() .. ".jpg",
    "https://www.zhihu.com/answer/" .. (self.currentAnswerId or ""))
  end)
  .setNegativeButton("取消", function()
    result.recycle()
  end)
  .setOnDismissListener({
    onDismiss = function()
      self.currentPageIds.webview.scrollBy(0, 1)
    end,
  })
  .show()
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
    author = authorText
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
  toolbar.subtitle = answerCount and ("共" .. answerCount .. "个回答" or "")
end

function AnswerFragment:loadQuestionInfo()
  self.model:getQuestionInfo(function(question)
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
    enableScrollTracking = self.isFirstLoad,
    codeScrollDisabled = Constants.SharedDataKeys.ANSWER_SINGLE_PAGE
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
  pcall(function()
    local ViewPager2 = luajava.bindClass("androidx.viewpager2.widget.ViewPager2")
    local RecyclerView = luajava.bindClass("androidx.recyclerview.widget.RecyclerView")

    local recyclerViewField = ViewPager2.getDeclaredField("mRecyclerView")
    recyclerViewField.accessible = true
    local recyclerView = recyclerViewField.get(viewPager)

    local touchSlopField = RecyclerView.getDeclaredField("mTouchSlop")
    touchSlopField.accessible = true
    local touchSlop = touchSlopField.get(recyclerView)
    touchSlopField.set(recyclerView, touchSlop * scrollSense)
  end)

  viewPager.offscreenPageLimit = 2

  local LuaPager2Adapter = luajava.bindClass("com.hydrogen.adapter.LuaPager2Adapter")
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
      self:handleVideoAttachment(pageIds, answerData)

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
    self.pagerAdapter.notifyDataSetChanged()
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
  if not data then error("handleVideoAttachment 传入data不存在") return end

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
    local CommentSheet = require("components/dialog/CommentSheet")
    CommentSheet.show({ contentId = self.currentAnswerId, contentType = "answer" })
  end
end

function AnswerFragment:onCollect(autoToggle)
  local data = self:getCurrentData()
  if not data then
    tip("无法获取回答信息")
    return
  end

  local CollectionMoveSheet = require("components.dialog.CollectionMoveSheet")
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
    views.float_scroll_container.Visibility = 0
   else
    return
  end

  local function scrollWebView(direction)
    if not self.currentPageIds or not self.currentPageIds.webview then return end
    local js = direction == "up"
    and "window.scrollBy(0, -window.innerHeight)"
    or "window.scrollBy(0, window.innerHeight)"
    self.currentPageIds.webview.evaluateJavascript(js, nil)
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
  viewPager.setCurrentItem(current + 1, true)
  local current = viewPager.currentItem
  local adapter = viewPager.adapter
  if adapter and current < adapter.itemCount - 1 then
    return true
  end
  return false
end

import "android.view.View"
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
    self.currentPageIds.webview.setLayerType(View.LAYER_TYPE_SOFTWARE, nil)
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