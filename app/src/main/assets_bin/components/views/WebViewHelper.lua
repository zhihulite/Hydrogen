-- WebViewHelper.lua
import "android.app.DownloadManager"
import "android.webkit.WebSettings"
import "android.webkit.CookieManager"
import "android.webkit.URLUtil"
import "android.webkit.WebResourceResponse"
import "android.webkit.WebView"
import "android.net.Uri"
import "android.os.Environment"
import "android.os.Handler"
import "android.content.Context"
import "android.view.View"
import "androidx.appcompat.widget.AppCompatEditText"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"
import "java.io.File"
import "java.io.FileInputStream"
import "com.hydrogen.LuaWebViewClientCreator"
import "com.hydrogen.LuaWebChromeClientCreator"

local M = {}
local LuaWebView = luajava.bindClass("com.hydrogen.view.LuaWebView")
local LuaWebViewBridge = require("helpers.luawebview_bridge")
local mergedModulesJS = LuaWebViewBridge.getMergedModulesJS()

local function downloadFile(url, userAgent, contentDisposition, mimeType, contentLength)

  local fileName
  if contentDisposition and contentDisposition:match('filename="(.-)"') then
    fileName = NetWork.urlDecode(contentDisposition:match('filename="(.-)"'))
   else
    fileName = URLUtil.guessFileName(url, nil, nil)
  end

  local size = string.format("%.2f", (contentLength or 0) / 1024 / 1024) .. "MB"

  local views = {}
  MaterialAlertDialogBuilder(activity)
  .setTitle("下载文件")
  .setMessage("文件类型：" .. (mimeType or "未知") .. "\n文件大小：" .. size.. "\n请手动复制链接下载")
  .setPositiveButton("复制", function()
    Helpers.UI.copyText(url)
    tip("复制下载链接成功")
  end)
  .setNegativeButton("取消", nil)
  .show()
end

function M.new(webView)
  if not luajava.instanceof(webView,LuaWebView) then
    error("仅支持 LuaWebView 使用")
  end

  local self = {
    webView = webView,
    settings = {},
    bridge = nil,
    isDestroyed = false,
  }
  setmetatable(self, { __index = M })
  self.bridge = LuaWebViewBridge.addBridge(self.webView, self.settings)
  return self
end

function M:isAlive()
  return not self.isDestroyed and self.webView ~= nil
end

function M:runIfAlive(callback)
  if not callback then
    return function() end
  end

  return function(...)
    if self:isAlive() then
      callback(...)
    end
  end
end

-- 设置配置（已在 new 自动初始化 JS 桥接）
function M:setSettings(settings)
  if not self:isAlive() then return self end
  if type(settings) == "table" then
    table.clear(self.settings)
    for key, value in pairs(settings) do
      self.settings[key] = value
    end
  end
  return self
end

function M:setMessageListener(listener)
  if not self:isAlive() then return self end
  if type(listener) ~= "function" then
    error("setMessageListener 需要传入一个函数")
  end

  if self.bridge and self.bridge.setMessageListener then
    self.bridge.setMessageListener(self:runIfAlive(listener))
  end

  return self
end

function M:setPageType(pageType)
  if not self:isAlive() then return self end
  self.settings.pageType = pageType
  return self
end

function M:initSettings()
  if not self:isAlive() then return self end
  local settings = self.webView.getSettings()
  settings.setAppCacheEnabled(true)
  settings.setCacheMode(WebSettings.LOAD_DEFAULT)
  settings.setDomStorageEnabled(true)
  settings.setDatabaseEnabled(true)
  settings.setJavaScriptEnabled(true)
  settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW)
  self.webView.setBackgroundColor(0)
  self.webView.setWebContentsDebuggingEnabled(true)
  return self
end

function M:initNoImageMode()
  if not self:isAlive() then return self end
  local noImage = Extensions.Config.getBool(Constants.SharedDataKeys.NO_IMAGE)
  self.webView.getSettings().setBlockNetworkImage(noImage)
  return self
end

function M:initDownloadListener()
  if not self:isAlive() then return self end
  self.webView.setDownloadListener({
    onDownloadStart = self:runIfAlive(function(url, userAgent, contentDisposition, mimeType, contentLength)
      downloadFile(url, userAgent, contentDisposition, mimeType, contentLength)
    end)
  })
  return self
end

function M:setUA(ua)
  if not self:isAlive() then return self end
  self.webView.getSettings().setUserAgentString(ua)
  return self
end

function M:setPCUA()
  if not self:isAlive() then return self end
  local ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
  self.webView.getSettings().setUserAgentString(ua)
  return self
end

function M:setZhiHuUA()
  if not self:isAlive() then return self end
  local currentUA = self.webView.getSettings().getUserAgentString()
  local ua = "ZhihuHybrid com.zhihu.android/Futureve/9.13.0 " .. currentUA
  self.webView.getSettings().setUserAgentString(ua)
  return self
end


function M:setQQUA()
  if not self:isAlive() then return self end
  local ua = "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/120.0.0.0 Mobile MQQBrowser/6.2 TBS/123456 Safari/537.36 V1_AND_SQ_8.9.90_xxx QQ/8.9.90 NetType/WIFI WebP/0.3.0 Pixel/1440"
  self.webView.getSettings().setUserAgentString(ua)
  return self
end

function M:setWebViewClient(callbacks)
  if not self:isAlive() then return self end
  callbacks = callbacks or {}

  local self_ref = self
  local defaultCallbacks = {
    onPageStarted = function(view, url, favicon)
      if mergedModulesJS and mergedModulesJS ~= "" then
        self_ref:evaluateJavascript(LuaWebViewBridge.getMergedModulesJS())
      end
    end,
    shouldInterceptRequest = function(view, url)
      return self_ref:onInterceptRequest(view, url)
    end,
    onReceivedSslError = function(view, handler, error)
      handler.proceed()
    end,
  }

  local merged = {}

  -- 默认回调必须执行，用户回调可选（用户返回值优先）
  for k, defaultFunc in pairs(defaultCallbacks) do
    merged[k] = function(...)
      local defaultResult = self:runIfAlive(defaultFunc)(...)
      if callbacks[k] then
        local userResult = self:runIfAlive(callbacks[k])(...)
        return userResult or defaultResult
      end
      return defaultResult
    end
  end

  -- 用户独有的回调（默认回调中不存在的），直接安全包装
  for k, userFunc in pairs(callbacks) do
    if not defaultCallbacks[k] then
      merged[k] = self:runIfAlive(userFunc)
    end
  end

  self.webView.setWebViewClient(LuaWebViewClientCreator(luajava.createProxy(
  "com.hydrogen.LuaWebViewClientCreator$Creator", merged)))
  return self
end

function M:onInterceptRequest(view, url)
  if not self:isAlive() then return nil end
  local customFontPath = Extensions.Config.getString(Constants.SharedDataKeys.CUSTOM_WEB_FONT)
  if url and url:find("customappfont") and customFontPath then
    if customFontPath=="appfont" then
      customFontPath=Helpers.Static.fontPath("product");
    end
    local fontFile = File(customFontPath)
    if fontFile.exists() and fontFile.canRead() then
      local fis = FileInputStream(fontFile)
      return WebResourceResponse("application/x-font-ttf", "utf-8", fis)
     else
      Extensions.Config.delete(Constants.SharedDataKeys.CUSTOM_WEB_FONT)
      tip("自定义字体文件不可读，已清空")
    end
  end
  return nil
end

function M:setWebChromeClient(callbacks)
  if not self:isAlive() then return self end
  callbacks = callbacks or {}

  local protectedCallbacks = {
    onShowCustomView = true,
    onHideCustomView = true,
    onJsAlert = true,
    onJsConfirm = true,
    onJsPrompt = true,
  }

  for k in pairs(callbacks) do
    if protectedCallbacks[k] then
      error("禁止覆盖 WebChromeClient 的默认回调: " .. k)
    end
  end

  local rootView = activity.getDecorView()
  local webVideoView = nil
  local savedScrollY = nil

  local defaultCallbacks = {
    onShowCustomView = function(view, callback)
      _G.webViewfullscreenMode = true
      webVideoView = view
      savedScrollY = self.webView.getScrollY()
      self.webView.setVisibility(View.GONE)
      rootView.addView(view)
    end,
    onHideCustomView = function()
      _G.webViewfullscreenMode = false
      self.webView.setVisibility(View.VISIBLE)
      rootView.removeView(webVideoView)
      task(200, self:runIfAlive(function()
          self.webView.scrollTo(0, savedScrollY or 0)
        end))
    end,
    onJsAlert = function(view, url, message, result)
      MaterialAlertDialogBuilder(activity)
      .setTitle(url)
      .setMessage(message)
      .setPositiveButton("确定", function() result.confirm() end)
      .setCancelable(false)
      .show()
      return true
    end,
    onJsConfirm = function(view, url, message, result)
      MaterialAlertDialogBuilder(activity)
      .setTitle(url)
      .setMessage(message)
      .setPositiveButton("确定", function() result.confirm() end)
      .setNegativeButton("取消", function() result.cancel() end)
      .setCancelable(false)
      .show()
      return true
    end,
    onJsPrompt = function(view, url, message, defaultValue, result)
      local editText = AppCompatEditText(activity)
      editText.setText(defaultValue)
      MaterialAlertDialogBuilder(activity)
      .setTitle(url)
      .setView(editText)
      .setMessage(message)
      .setPositiveButton("确定", function()
        result.confirm(editText.getText().toString())
      end)
      .setNegativeButton("取消", function() result.cancel() end)
      .setCancelable(false)
      .show()
      return true
    end,
  }

  local merged = {}

  -- 先放入默认回调
  for key, defaultFunc in pairs(defaultCallbacks) do
    merged[key] = defaultFunc
  end

  -- 用户回调只允许覆盖非保护的回调
  for key, userFunc in pairs(callbacks) do
    if not protectedCallbacks[key] then
      merged[key] = self:runIfAlive(userFunc)
    end
  end

  self.webView.setWebChromeClient(LuaWebChromeClientCreator(luajava.createProxy(
  "com.hydrogen.LuaWebChromeClientCreator$Creator", merged)))
  return self
end

function M:evaluateJavascript(script, callback)
  if not self:isAlive() then return end
  self.webView.evaluateJavascript(script, {
    onReceiveValue = self:runIfAlive(function(value)
      if callback then callback(value) end
    end)
  })
end

function M:findAllAsync(text)
  if not self:isAlive() then return end
  self.webView.findAllAsync(text)
end

function M:clearMatches()
  if not self:isAlive() then return end
  self.webView.clearMatches()
end

function M:findNext(forward)
  if not self:isAlive() then return end
  self.webView.findNext(forward)
end

function M:setFindListener(callback)
  if not self:isAlive() then return end
  self.webView.setFindListener({
    onFindResultReceived = self:runIfAlive(function(activeMatchOrdinal, numberOfMatches, isDoneCounting)
      if callback then callback(activeMatchOrdinal, numberOfMatches, isDoneCounting) end
    end)
  })
end

function M:showSearchDialog()
  if not self:isAlive() then return end
  local dialogViews = {}
  MaterialAlertDialogBuilder(activity)
  .setTitle("页面查找")
  .setView(loadlayout({
    LinearLayoutCompat, orientation = "vertical", padding = "16dp",
    { AppCompatEditText, id = "search_input", layout_width = "match_parent", hint = "输入查找内容" }
  }, dialogViews))
  .setPositiveButton("查找", self:runIfAlive(function()
    local text = dialogViews.search_input and dialogViews.search_input.getText().toString() or ""
    if text ~= "" then
      self:findAllAsync(text)
      self:setFindListener(function(activeMatch, numberOfMatches, isDoneCounting)
        if isDoneCounting then
          tip(string.format("找到 %d 个匹配", numberOfMatches))
        end
      end)
    end
  end))
  .setNegativeButton("取消", self:runIfAlive(function()
    self:clearMatches()
  end))
  .show()
end

function M:getUrl()
  if not self:isAlive() then return nil end
  return self.webView.getUrl()
end

function M:reload()
  if not self:isAlive() then return end
  self.webView.reload()
end

function M:goForward()
  if not self:isAlive() then return end
  if self.webView.canGoForward() then
    self.webView.goForward()
  end
end

function M:goBack()
  if not self:isAlive() then return end
  if self.webView.canGoBack() then
    self.webView.goBack()
  end
end

function M:stopLoading()
  if not self:isAlive() then return end
  self.webView.stopLoading()
end

function M:canGoForward()
  if not self:isAlive() then return false end
  return self.webView.canGoForward()
end

function M:canGoBack()
  if not self:isAlive() then return false end
  return self.webView.canGoBack()
end

function M:scrollTo(x, y)
  if not self:isAlive() then return end
  self.webView.scrollTo(x, y)
end

function M:getScrollY()
  if not self:isAlive() then return 0 end
  return self.webView.getScrollY()
end

function M:saveWebArchive(path)
  if not self:isAlive() then return end
  self.webView.saveWebArchive(path)
end

function M:destroy()
  self.isDestroyed = true
  self.bridge = nil
  if self.webView then
    self.webView.stopLoading()
    self.webView.destroy()
    self.webView = nil
  end
end

return M