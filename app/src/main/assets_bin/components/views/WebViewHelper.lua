-- components/views/WebViewHelper.lua
-- webview 助手

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
import "androidx.activity.result.ActivityResultCallback"
import "androidx.activity.result.contract.ActivityResultContracts"
import "android.webkit.ValueCallback"
import "android.webkit.WebChromeClient"

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

-- 辅助函数：自动判断 MIME 类型
local function getMimeType(acceptTypes)
  if not acceptTypes or #acceptTypes == 0 then
    return "*/*"
  end

  local mime = acceptTypes[0]

  if mime:find("image") or mime == "*/*" then
    return "image/*"
   elseif mime:find("video") then
    return "video/*"
   elseif mime:find("audio") then
    return "audio/*"
   elseif mime:find("pdf") then
    return "application/pdf"
  end

  return mime
end

function M.new(webView)
  if not luajava.instanceof(webView, LuaWebView) then
    error("仅支持 LuaWebView 使用")
  end

  local self = {
    webView = webView,
    settings = {},
    bridge = nil,
    isDestroyed = false,
    fileUploadEnabled = false,
    fileUploadOwner = nil,
    fileUploadLauncher = nil,
    filePathCallback = nil,
  }
  setmetatable(self, { __index = M })
  self.bridge = LuaWebViewBridge.addBridge(self.webView, self.settings)

  return self
end

-- 开启文件上传功能，传入 Activity 或 Fragment
function M:enableFileUpload(owner)
  if not self:isAlive() then return self end

  if not owner then
    error("enableFileUpload: 无法获取 Activity/Fragment")
    return self
  end

  self.fileUploadEnabled = true
  self.fileUploadOwner = owner

  -- 注册 Launcher
  self.fileUploadLauncher = self.fileUploadOwner.registerForActivityResult(
  ActivityResultContracts.OpenDocument(),
  luajava.createProxy("androidx.activity.result.ActivityResultCallback", {
    onActivityResult = function(uri)
      if self.filePathCallback then
        local UriArray = luajava.newArray(luajava.bindClass("android.net.Uri"), 1)
        UriArray[0] = uri
        self.filePathCallback.onReceiveValue(UriArray)
        self.filePathCallback = nil
      end
    end
  })
  )

  return self
end

-- 关闭文件上传功能
function M:disableFileUpload()
  self.fileUploadEnabled = false
  if self.filePathCallback then
    self.filePathCallback.onReceiveValue(nil)
    self.filePathCallback = nil
  end
  self.fileUploadLauncher = nil
  self.fileUploadOwner = nil
  return self
end

function M:isAlive()
  return not self.isDestroyed and self.webView ~= nil
end

function M:runIfAlive(callback)
  if not callback then
    error("WebViewHeleper:runIfAlive 必须为 function 类型")
  end

  return function(...)
    if self:isAlive() then
      return callback(...)
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

function M:initFindListener()
  if not self:isAlive() then return self end

  self.webView.setFindListener(luajava.createProxy("android.webkit.WebView$FindListener", {
    onFindResultReceived = self:runIfAlive(function(activeMatchOrdinal, numberOfMatches, isDoneCounting)
      if numberOfMatches == 0 then
        tip("未查找到该关键词")
        return
      end

      local status = isDoneCounting and "成功" or "失败"
      local current = activeMatchOrdinal + 1
      local remaining = numberOfMatches - current
      tip(string.format("查找%s 当前第%d个 还剩%d个", status, current, remaining))
    end)
  }))
end

local fontScale = activity.resources.configuration.fontScale
local textZoom = tointeger(fontScale * 100)
function M:initSettings()
  if not self:isAlive() then return self end
  local settings = self.webView.settings
  settings.appCacheEnabled = true
  settings.cacheMode = WebSettings.LOAD_DEFAULT
  settings.domStorageEnabled = true
  settings.databaseEnabled = true
  settings.javaScriptEnabled = true
  settings.mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
  -- 安卓15及以下兼容：WebView 字体大小适配
  -- 问题：低版本 createPackageContext 挂载资源时 fontScale 被重置为 1.0，导致系统字体设置不生效
  -- 方案：手动读取当前 Context 的 fontScale，换算为 textZoom 强制设置到 WebView
  -- 安卓15+ 已通过 register_resource_paths 修复，此方案兼容所有版本无副作用
  settings.textZoom = textZoom

  self.webView.backgroundColor = 0
  -- 开启debug模式
  self.webView.webContentsDebuggingEnabled = true
  -- 初始化查找监听
  self:initFindListener()
  return self
end

function M:initNoImageMode()
  if not self:isAlive() then return self end
  local noImage = Extensions.Config.getBool(Constants.SharedDataKeys.NO_IMAGE)
  self.webView.settings.blockNetworkImage = noImage
  return self
end

function M:initDownloadListener()
  if not self:isAlive() then return self end
  self.webView.setDownloadListener(luajava.createProxy("android.webkit.DownloadListener", {
    onDownloadStart = self:runIfAlive(function(url, userAgent, contentDisposition, mimeType, contentLength)
      downloadFile(url, userAgent, contentDisposition, mimeType, contentLength)
    end)
  }))
  return self
end

function M:setUA(ua)
  if not self:isAlive() then return self end
  self.webView.settings.userAgentString = ua
  return self
end

function M:setPCUA()
  if not self:isAlive() then return self end
  local ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
  self.webView.settings.userAgentString = ua
  return self
end

function M:setZhiHuUA()
  if not self:isAlive() then return self end
  local currentUA = self.webView.settings.userAgentString
  local ua = "ZhihuHybrid com.zhihu.android/Futureve/9.13.0 " .. currentUA
  self.webView.settings.userAgentString = ua
  return self
end


function M:setQQUA()
  if not self:isAlive() then return self end
  local ua = "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/120.0.0.0 Mobile MQQBrowser/6.2 TBS/123456 Safari/537.36 V1_AND_SQ_8.9.90_xxx QQ/8.9.90 NetType/WIFI WebP/0.3.0 Pixel/1440"
  self.webView.settings.userAgentString = ua
  return self
end

function M:setWebViewClient(callbacks)
  if not self:isAlive() then return self end
  callbacks = callbacks or {}

  local defaultCallbacks = {
    onPageStarted = function(view, url, favicon)
      if mergedModulesJS and mergedModulesJS ~= "" then
        self:evaluateJavascript(LuaWebViewBridge.getMergedModulesJS())
      end
    end,
    shouldInterceptRequest = function(view, url)
      return self:onInterceptRequest(view, url)
    end,
    onReceivedSslError = function(view, handler, error)
      handler.proceed()
    end,
    onRenderProcessGone = function(webView, renderProcessGoneDetail)
      -- WebView 渲染进程崩溃回调
      -- 返回 true 表示已处理，系统不会终止当前 Activity
      -- 返回 false 则系统会弹出"应用已停止"对话框并退出
      return true
    end,
  }

  local merged = {}

  -- 默认回调必须执行，用户回调可选（用户返回值优先）
  for k, defaultFunc in pairs(defaultCallbacks) do
    merged[k] = self:runIfAlive(function(...)
      local defaultResult = defaultFunc(...)
      if callbacks[k] then
        local userResult = callbacks[k](...)
        return userResult or defaultResult
      end
      return defaultResult
    end)
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

import "android.graphics.Bitmap"
local blankIcon = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
function M:setWebChromeClient(callbacks)
  if not self:isAlive() then return self end
  callbacks = callbacks or {}

  local protectedCallbacks = {
    onShowCustomView = true,
    onHideCustomView = true,
    onJsAlert = true,
    onJsConfirm = true,
    onJsPrompt = true,
    getDefaultVideoPoster = true,
  }

  -- 如果开启了文件上传，也要保护这些回调
  if self.fileUploadEnabled then
    protectedCallbacks.onShowFileChooser = true
  end

  for k in pairs(callbacks) do
    if protectedCallbacks[k] then
      error("禁止覆盖 WebChromeClient 的默认回调: " .. k)
    end
  end

  local rootView = activity.decorView
  local webVideoView = nil
  local savedScrollY = nil

  local defaultCallbacks = {
    onShowCustomView = function(view, callback)
      _G.webViewfullscreenMode = true
      webVideoView = view
      savedScrollY = self:getScrollY()
      self.webView.visibility = View.GONE
      rootView.addView(view)
    end,
    onHideCustomView = function()
      _G.webViewfullscreenMode = false
      self.webView.visibility = View.VISIBLE
      rootView.removeView(webVideoView)
      Helpers.UI.runDelayed(200, self:runIfAlive(function()
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
      editText.text = defaultValue
      MaterialAlertDialogBuilder(activity)
      .setTitle(url)
      .setView(editText)
      .setMessage(message)
      .setPositiveButton("确定", function()
        result.confirm(editText.text)
      end)
      .setNegativeButton("取消", function() result.cancel() end)
      .setCancelable(false)
      .show()
      return true
    end,
    getDefaultVideoPoster = function()
      return blankIcon
    end,
  }

  -- 如果开启了文件上传，添加上传回调
  if self.fileUploadEnabled then
    defaultCallbacks.onShowFileChooser = function(webView, filePathCallback, fileChooserParams)
      self.filePathCallback = filePathCallback
      local acceptTypes = fileChooserParams.getAcceptTypes()
      local mimeType = getMimeType(acceptTypes)
      if self.fileUploadLauncher then
        local mimeArray = luajava.newArray(luajava.bindClass("java.lang.String"), 1)
        mimeArray[0] = mimeType
        self.fileUploadLauncher.launch(mimeArray)
      end
      return true
    end
  end

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

function M:showSearchDialog()
  if not self:isAlive() then return end

  local dialogViews = {}
  local dialog = MaterialAlertDialogBuilder(activity)
  .setTitle("搜索")
  .setView(loadlayout({
    LinearLayoutCompat, orientation = "vertical", padding = "16dp",
    { MaterialTextView, text = "输入搜索内容", textIsSelectable = true, layout_marginBottom = "8dp" },
    { AppCompatEditText, id = "search_input", layout_width = "match_parent", hint = "请输入搜索内容", singleLine = true }
  }, dialogViews))
  .setPositiveButton("新搜索", nil)
  .setNegativeButton("查找", nil)
  .setNeutralButton("关闭", nil)
  .show()

  -- 新搜索按钮
  dialog.getButton(dialog.BUTTON_POSITIVE).onClick = function()
    local text = dialogViews.search_input and dialogViews.search_input.text or ""
    if text == "" then
      tip("请输入搜索内容")
      return
    end
    self:clearMatches()
    self:findAllAsync(text)
  end

  -- 查找按钮（弹出菜单）
  dialog.getButton(dialog.BUTTON_NEGATIVE).onClick = function(view)
    local popup = PopupMenu(activity, view)
    local menu = popup.Menu
    menu.add("上一个").onMenuItemClick = function() self:findNext(false); return true end
    menu.add("下一个").onMenuItemClick = function() self:findNext(true); return true end
    menu.add("取消").onMenuItemClick = function() self:clearMatches(); tip("取消成功"); return true end
    popup.show()
  end
end

function M:getUrl()
  if not self:isAlive() then return nil end
  return self.webView.url
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
  return self.webView.scrollY
end

function M:saveWebArchive(path)
  if not self:isAlive() then return end
  self.webView.saveWebArchive(path)
end

function M:clearCache()
  if not self:isAlive() then return end
  self.webView.clearCache(true)
  self.webView.clearFormData()
  self.webView.clearHistory()
end

function M:destroy()
  self.isDestroyed = true
  self.bridge = nil
  if self.webView then
    -- 清理缓存
    self:clearCache()
    self.webView.stopLoading()
    self.webView.destroy()
    self.webView = nil
  end
  -- 清理文件上传回调
  self:disableFileUpload()
end

return M