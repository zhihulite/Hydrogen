-- pages/fragment/browser/BrowserFragment.lua
-- 浏览页面

local BaseFragment = require("pages.base.BaseFragment")
local WebViewHelper = require("components.views.WebViewHelper")

local BrowserFragment = Extensions.Class(BaseFragment, {"browser"})

function BrowserFragment:ctor()
  self.webView = nil
  self.webViewHelper = nil
  self.startUrl = nil
  self.pageTitle = nil
  self.menuItems = {}
  self.uaMode = nil
  self.backCallback = nil
end

function BrowserFragment:onCreate(params)
  self.startUrl = params.url
  self.pageType = params.type
  self.ua = params.ua
end

function BrowserFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.browser.main, self.views)
end

function BrowserFragment:getHelper()
  if not self.webViewHelper then
    tip("无法获取当前页面")
    return nil
  end
  return self.webViewHelper
end

function BrowserFragment:initViews()
  local views = self.views
  self:setupEdgeToEdge({
    top = { views.main_container },
  })

  Helpers.UI.setupToolbar(views.toolbar, {
    title = self.pageTitle or "加载中",
    menu = {
      { id = "back", title = "后退", click = function() self:goBack() end },
      { id = "forward", title = "前进", click = function() self:goForward() end },
      { id = "refresh", title = "刷新", click = function() if self:getHelper() then self:getHelper():reload() end end },
      { id = "stop", title = "停止", click = function() if self:getHelper() then self:getHelper():reload() end end },
      { id = "find", title = "查找", click = function() if self:getHelper() then self:getHelper():showSearchDialog() end end },
      { id = "share", title = "分享", click = function() self:shareUrl() end },
      { id = "copy", title = "复制链接", click = function() self:copyUrl() end },
      { id = "open", title = "浏览器打开", click = function() self:openInBrowser() end },
    }
  })

  Helpers.UI.setupSwipeRefresh(views.swipe_refresh, function()
    if self:getHelper() then self:getHelper():reload() end
  end)

  self:initWebView()
  self:loadUrl()
  self:registerBackHandler()
end

function BrowserFragment:registerBackHandler()
  local callback
  callback = self:addBackPressedCallback({
    enabled = false, -- 初始禁用
    handleOnBackPressed = function()
      self:goBack()
    end
  })
  self.backCallback = callback
  self:updateBackButtonState()
end

function BrowserFragment:updateBackButtonState()
  if self.backCallback and self:getHelper() then
    local canGoBack = self:getHelper():canGoBack()
    self.backCallback.enabled = canGoBack
  end
end

local DailySectionListModel = require("models.feed.DailySectionListModel")
local function showDailySectionListDialog(sectionId)
  import "androidx.appcompat.widget.LinearLayoutCompat"
  import "com.hydrogen.view.CustomSwipeRefresh"
  import "androidx.recyclerview.widget.RecyclerView"
  import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

  local dialogViews = {}
  local layout = Layouts.pages.simple_list.main

  local dialogView = loadlayout(layout, dialogViews)
  local toolbar = dialogViews.toolbar
  toolbar.parent.removeView(toolbar)
  -- 背景透明
  dialogViews.main_container.backgroundColor = 0
  local dialog = MaterialAlertDialogBuilder(activity)
  .setTitle("推荐收藏夹")
  .setView(dialogView)
  .setPositiveButton("关闭", nil)
  .show()

  local model = DailySectionListModel(sectionId)
  model:init(dialogViews.recycler_view, dialogViews.swipe_refresh)
  model:refresh()

  dialog.onDismiss = function()
    model:destroy()
  end
end

function BrowserFragment:initWebView()
  local views = self.views
  self.webView = views.webview
  self.webViewHelper = WebViewHelper.new(self.webView)
  :initSettings()
  :initNoImageMode()
  :initDownloadListener()
  :setZhiHuUA()
  :setSettings({
    pageType = self.pageType
  })
  -- 开启文件上传
  local thisFragment = self:getFragment()
  self.webViewHelper:enableFileUpload(thisFragment)

  local ua = self.ua
  if ua == "pc" then
    self.webViewHelper:setPCUA()
   elseif ua == "zhihu" then
    self.webViewHelper:setZhiHuUA()
   elseif ua then
    -- 自定义 UA 字符串
    self.webViewHelper:setUA(ua)
  end

  self.webViewHelper:setWebViewClient({
    shouldOverrideUrlLoading = function(view, url)
      -- 知乎日报特殊处理
      if url:find("^zhdaily://") then
        -- 处理 section 跳转
        local sectionId = url:match("section%?id=(%d+)")
        if sectionId then
          -- 跳转到专栏/专题页面
          showDailySectionListDialog(sectionId)
          return true
        end

        local realUrl = url:match("url=([^&]+)")
        if realUrl then
          Helpers.ZhihuParser.goUrl(realUrl)
         else
          tip("无法解析链接")
        end
        return true
      end

      -- 第三方 scheme
      if not url:find("^https?://") then
        Helpers.BottomDialog.confirm("即将打开第三方应用，是否继续?", function()
          Helpers.UI.openUrl(url)
        end)
        return true
      end
      local parsed = Helpers.ZhihuParser.parse(url)
      if parsed then
        Helpers.ZhihuParser.goFrom(parsed)
        return true
      end
      return false
    end,
    onPageStarted = function(view, url)
      views.swipe_refresh.refreshing = true
      views.webview.visibility = View.GONE
    end,
    onPageFinished = function(view, url)
      views.swipe_refresh.refreshing = false
      views.webview.visibility = View.VISIBLE
      self:updateBackButtonState()
    end,
    doUpdateVisitedHistory = function(view, url, isReload)
      self:updateBackButtonState()
    end
  })

  self.webViewHelper:setWebChromeClient({
    onReceivedTitle = function(view, title)
      views.toolbar.title = title
    end,
    onProgressChanged = function(view, progress)
      local bar = views.progress_bar
      if progress == 100 then
        bar.visibility = View.GONE
        bar.progress = 0
       else
        if bar.visibility ~= View.VISIBLE then bar.visibility = View.VISIBLE end
        bar.progress = progress
      end
    end
  })
end

function BrowserFragment:loadUrl()
  self.views.webview.visibility = View.GONE
  if self:getHelper() then
    self:getHelper().webView.loadUrl(self.startUrl)
  end
end

function BrowserFragment:goForward()
  if self:getHelper() then self:getHelper():goForward() end
end

function BrowserFragment:goBack()
  if self:getHelper() then self:getHelper():goBack() end
end

function BrowserFragment:shareUrl()
  if self:getHelper() then
    local url = self:getHelper():getUrl()
    if url then Helpers.UI.shareText(url) end
  end
end

function BrowserFragment:copyUrl()
  if self:getHelper() then
    local url = self:getHelper():getUrl()
    if url then Helpers.UI.copyText(url) end
  end
end

function BrowserFragment:openInBrowser()
  if self:getHelper() then
    local url = self:getHelper():getUrl()
    if url then Helpers.UI.openUrl(url) end
  end
end

import "android.view.View"
function BrowserFragment:onPause()
  if self.webView then
    self.webView.setLayerType(View.LAYER_TYPE_HARDWARE, nil)
  end
end

function BrowserFragment:onResume()
  if self.webView then
    self.webView.setLayerType(View.LAYER_TYPE_NONE, nil)
  end
end

function BrowserFragment:onDestroy()
  if self.webViewHelper then
    self.webViewHelper:destroy()
    self.webViewHelper = nil
  end
end

return BrowserFragment