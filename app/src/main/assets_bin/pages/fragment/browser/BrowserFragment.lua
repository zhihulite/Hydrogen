-- pages/fragment/browser/BrowserFragment.lua

local BaseFragment = require("pages.base.BaseFragment")
local WebViewHelper = require("components.views.WebViewHelper")
local MenuItem = luajava.bindClass("android.view.MenuItem")

local BrowserFragment = Extensions.Class(BaseFragment, {"browser"})
BrowserFragment:chainUp("onDestroy")

function BrowserFragment:ctor()
  self.webView = nil
  self.webViewHelper = nil
  self.startUrl = nil
  self.pageTitle = nil
  self.menuItems = {}
  self.uaMode = nil
end

function BrowserFragment:onCreate(params)
  self.startUrl = params.url
  self.pageType = params.type
  self.ua = params.ua
end

function BrowserFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.browser.main, self.views)
end

function BrowserFragment:initViews()
  local views = self.views
  self:setupEdgeToEdge({
    top = { self.views.main_container },
  })

  Helpers.UI.setupToolbar(views.toolbar, {
    title = self.pageTitle or "加载中",
    menu = {
      { id = "back", title = "后退", click = function() self:goBack() end },
      { id = "forward", title = "前进", click = function() self:goForward() end },
      { id = "refresh", title = "刷新", click = function() self.webView.reload() end },
      { id = "stop", title = "停止", click = function() self.webView.stopLoading() end },
      { id = "share", title = "分享", click = function() self:shareUrl() end },
      { id = "copy", title = "复制链接", click = function() self:copyUrl() end },
      { id = "open", title = "浏览器打开", click = function() self:openInBrowser() end },
    }
  })

  Helpers.UI.setupSwipeRefresh(views.swipe_refresh, function()
    if self.webView then self.webView.reload() end
  end)

  self:initWebView()
  self:loadUrl()
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
      if url:find("^zhdaiy://") then
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

      Helpers.ZhihuParser.goUrl(url)
      return true
    end,
    onPageStarted = function(view, url)
      self.views.swipe_refresh.setRefreshing(true)
      self.views.webview.setVisibility(View.GONE)
    end,
    onPageFinished = function(view, url)
      self.views.swipe_refresh.setRefreshing(false)
      self.views.webview.setVisibility(View.VISIBLE)
    end
  })

  self.webViewHelper:setWebChromeClient({
    onReceivedTitle = function(view, title)
      self.views.toolbar.setTitle(title)
    end,
    onProgressChanged = function(view, progress)
      local bar = self.views.progress_bar
      if progress == 100 then
        task(300, function()
          bar.setVisibility(View.GONE) bar.setProgress(0)
        end)
       else
        if bar.getVisibility() ~= View.VISIBLE then bar.setVisibility(View.VISIBLE) end
        bar.setProgress(progress)
      end
    end
  })
end

function BrowserFragment:loadUrl()
  self.views.webview.setVisibility(View.GONE)
  self.webView.loadUrl(self.startUrl)
end

function BrowserFragment:goForward()
  if self.webView.canGoForward() then self.webView.goForward() end
end

function BrowserFragment:goBack()
  if self.webView.canGoBack() then self.webView.goBack() end
end

function BrowserFragment:shareUrl()
  local url = self.webView.getUrl()
  if url then Helpers.UI.shareText(url) end
end

function BrowserFragment:copyUrl()
  local url = self.webView.getUrl()
  if url then Helpers.UI.copyText(url) end
end

function BrowserFragment:openInBrowser()
  local url = self.webView.getUrl()
  if url then Helpers.UI.openUrl(url) end
end

import "android.view.View"
function BrowserFragment:onPause()
  if self.webView then
    self.webView.setLayerType(View.LAYER_TYPE_SOFTWARE, nil)
  end
end

function BrowserFragment:onResume()
  if self.webView then
    self.webView.setLayerType(View.LAYER_TYPE_NONE, nil)
  end
end

function BrowserFragment:onDestroy()
  if self.webView then
    self.webView.destroy()
    self.webView = nil
  end
end

return BrowserFragment