-- pages/fragment/browser/browser_fragment.lua
-- 浏览页面

import "android.view.View"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

local BaseFragment = require("pages.base.base_fragment")
local WebViewHelper = require("components.views.web_view_helper")

local BrowserFragment = Extensions.Class(BaseFragment, {"browser"})

function BrowserFragment:ctor()
  self.webView = nil
  self.webViewHelper = nil
  self.startUrl = nil
  self.externalUrl = nil
  self.dailyId = nil
  self.pageTitle = nil
  self.menuItems = {}
  self.uaMode = nil
  self.backCallback = nil
  self.sectionDialog = nil
end

function BrowserFragment:onCreate(params)
  self.startUrl = params.url
  self.externalUrl = params.url
  self.dailyId = params.dailyId
  self.pageTitle = params.title
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
      { id = "refresh", title = "刷新", click = function() self:reloadPage() end },
      { id = "stop", title = "停止", click = function() if self:getHelper() then self:getHelper():stopLoading() end end },
      { id = "find", title = "查找", click = function() if self:getHelper() then self:getHelper():showSearchDialog() end end },
      { id = "share", title = "分享", click = function() self:shareUrl() end },
      { id = "copy", title = "复制链接", click = function() self:copyUrl() end },
      { id = "open", title = "浏览器打开", click = function() self:openInBrowser() end },
    }
  })

  Helpers.UI.setupSwipeRefresh(views.swipe_refresh, function()
    self:reloadPage()
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

local DailySectionListModel = require("models.feed.daily_section_list_model")

-- 日报专栏列表对话框：实例方法以纳入页面生命周期管理
function BrowserFragment:showDailySectionListDialog(sectionId)
  local dialogViews = {}
  local layout = Layouts.pages.simple_list.main

  local dialogView = loadlayout(layout, dialogViews)
  local toolbar = dialogViews.toolbar
  toolbar.parent.removeView(toolbar)
  -- 背景透明
  dialogViews.main_container.backgroundColor = 0
  local dialog = MaterialAlertDialogBuilder(activity)
  .setTitle("日报栏目")
  .setView(dialogView)
  .setPositiveButton("关闭", nil)
  .show()
  self.sectionDialog = dialog

  local model = DailySectionListModel(sectionId)
  model:setupSingle(dialogViews.recycler_view, dialogViews.swipe_refresh)
  model:refresh()

  dialog.onDismiss = function()
    model:destroy()
    if self.sectionDialog == dialog then
      self.sectionDialog = nil
    end
  end
end

function BrowserFragment:initWebView()
  local views = self.views
  self.webView = views.webview
  self.webViewHelper = WebViewHelper.new(self.webView)
  :initSettings()
  :initNoImageMode()
  :initDownloadListener()
  :setSettings({
    pageType = self.pageType
  })
  -- 开启文件上传
  local thisFragment = self:getFragment()
  self.webViewHelper:enableFileUpload(thisFragment)

  local ua = self.ua
  if ua == "pc" then
    self.webViewHelper:setPCUA()
   elseif ua and ua ~= "zhihu" then
    -- 自定义 UA 字符串
    self.webViewHelper:setUA(ua)
   else
    self.webViewHelper:setZhiHuUA()
  end

  self.webViewHelper:setWebViewClient({
    shouldOverrideUrlLoading = function(view, url)
      -- 知乎日报特殊处理
      if url:find("^zhdaily://") then
        -- 处理 section 跳转
        local sectionId = url:match("section%?id=(%d+)")
        if sectionId then
          -- 跳转到专栏/专题页面
          self:showDailySectionListDialog(sectionId)
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
  if self.dailyId then
    self:loadDailyStory()
    return
  end
  if self:getHelper() then
    self:getHelper().webView.loadUrl(self.startUrl)
  end
end

local function buildDailyHtml(data)
  local escapeHtml = Helpers.ZhihuParser.escapeHtml
  local links = {}
  for _, cssUrl in ipairs(data.css or {}) do
    local safeUrl = tostring(cssUrl):gsub("^http://", "https://")
    table.insert(links, '<link rel="stylesheet" href="' .. escapeHtml(safeUrl) .. '">')
  end

  local body = data.body or "<p>日报正文为空</p>"
  local title = escapeHtml(data.title or "知乎日报")
  return table.concat({
    "<!doctype html><html><head><meta charset=\"utf-8\">",
    '<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">',
    "<title>", title, "</title>",
    table.concat(links),
    '<style>html,body{margin:0;padding:0}body{overflow-wrap:anywhere}',
    'img,video{max-width:100%;height:auto}.content-wrap{box-sizing:border-box}</style>',
    "</head><body>", body, "</body></html>",
  })
end

function BrowserFragment:showLoadError(message)
  local views = self.views
  views.swipe_refresh.refreshing = false
  views.webview.visibility = View.VISIBLE
  views.progress_bar.visibility = View.GONE
  local html = "<!doctype html><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\">" ..
  "<body style=\"font-family:sans-serif;padding:24px;line-height:1.7\"><h3>加载失败</h3><p>" ..
  Helpers.ZhihuParser.escapeHtml(message) .. "</p></body>"
  self.webView.loadDataWithBaseURL("https://daily.zhihu.com/", html, "text/html", "UTF-8", nil)
end

function BrowserFragment:loadDailyStory()
  local views = self.views
  views.swipe_refresh.refreshing = true
  views.webview.visibility = View.GONE
  views.progress_bar.visibility = View.VISIBLE
  views.progress_bar.progress = 10

  local url = string.format("https://news-at.zhihu.com/api/4/story/%s", self.dailyId)
  NetWork.get(url, {}, function(code, content)
    if not self.webViewHelper then return end
    if code < 200 or code >= 300 or not content then
      self:showLoadError(string.format("日报接口请求失败（%s）", tostring(code)))
      return
    end

    local ok, data = pcall(json.decode, content)
    if not ok or type(data) ~= "table" then
      self:showLoadError("日报内容解析失败")
      return
    end

    self.pageTitle = data.title or self.pageTitle
    self.externalUrl = data.share_url or self.externalUrl
    views.toolbar.title = self.pageTitle or "知乎日报"
    self.webView.loadDataWithBaseURL(
    "https://daily.zhihu.com/story/" .. tostring(self.dailyId),
    buildDailyHtml(data), "text/html", "UTF-8", nil)
  end, true)
end

function BrowserFragment:reloadPage()
  if self.dailyId then
    self:loadDailyStory()
   elseif self:getHelper() then
    self:getHelper():reload()
  end
end

function BrowserFragment:goForward()
  if self:getHelper() then self:getHelper():goForward() end
end

function BrowserFragment:goBack()
  if self:getHelper() then self:getHelper():goBack() end
end

function BrowserFragment:shareUrl()
  local url = self.externalUrl or (self:getHelper() and self:getHelper():getUrl())
  if url then Helpers.UI.shareText(url) end
end

function BrowserFragment:copyUrl()
  local url = self.externalUrl or (self:getHelper() and self:getHelper():getUrl())
  if url then Helpers.UI.copyText(url) end
end

function BrowserFragment:openInBrowser()
  local url = self.externalUrl or (self:getHelper() and self:getHelper():getUrl())
  if url then Helpers.UI.openUrl(url) end
end

function BrowserFragment:onPause()
  -- 页面切走时关闭悬在顶层的日报专栏对话框，避免其遮挡后续页面
  if self.sectionDialog and self.sectionDialog.isShowing() then
    self.sectionDialog.dismiss()
  end
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
  if self.sectionDialog and self.sectionDialog.isShowing() then
    self.sectionDialog.dismiss()
  end
  self.sectionDialog = nil
  if self.webViewHelper then
    self.webViewHelper:destroy()
    self.webViewHelper = nil
  end
end

return BrowserFragment
