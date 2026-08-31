-- pages/fragment/local_content/local_content_fragment.lua
-- 本地网页保存与浏览页面（专门用于 answer）

import "android.webkit.WebView"
import "android.view.View"
import "android.print.PrintAttributes"
import "android.content.Context"
import "android.net.Uri"
import "java.io.File"

local BaseFragment = require("pages.base.base_fragment")
local WebViewHelper = require("components.views.web_view_helper")

local LocalContentFragment = Extensions.Class(BaseFragment, {"local_content"})

function LocalContentFragment:ctor()
  self.mode = nil
  self.url = nil
  self.title = nil
  self.contentId = nil
  self.questionId = nil
  self.saveDir = nil
  self.htmlPath = nil
  self.detailPath = nil
  self.webView = nil
  self.webViewHelper = nil
  self.isSaving = false
end

function LocalContentFragment:onCreate(params)
  self.pageTitle = params.title
  self.title = self.pageTitle or "未命名"
  self.author = params.author or "未知作者"
  self.contentId = params.id
  self.questionId = params.questionId

  -- detail.txt 按行存 key=value，字段解析限定单行
  local function parseDetailField(detail, key)
    return detail:match(key .. "=([^\r\n]+)")
  end

  local safeTitle = Extensions.File.sanitizeForFilename(self.title)
  local safeAuthor = Extensions.File.sanitizeForFilename(self.author)
  self.saveDir = Extensions.File.getAppDir("Download") .. "/" .. safeTitle .. "/" .. safeAuthor
  self.detailPath = self.saveDir .. "/detail.txt"
  self.htmlPath = self.saveDir .. "/html.html"
  self.mhtmlPath = self.saveDir .. "/mhtml.mhtml"

  if params.url then
    self.mode = "save"
    self.url = params.url
   elseif params.savePath then
    self.mode = "browse"
    self.saveDir = params.savePath
    self.detailPath = self.saveDir .. "/detail.txt"
    self.htmlPath = self.saveDir .. "/html.html"
    if Extensions.File.exists(self.detailPath) then
      local detail = Extensions.File.read(self.detailPath)
      if detail and detail ~= "" then
        local idPart = parseDetailField(detail, "answer_id")
        if idPart then
          self.contentId = idPart
        end
      end
    end
  end
end

function LocalContentFragment:onDestroy()
  if self._tempDir and Extensions.File.exists(self._tempDir) then
    Extensions.File.delete(self._tempDir)
  end

  if self.webViewHelper then
    self.webViewHelper:destroy()
    self.webViewHelper = nil
  end
  self.webView = nil
end

function LocalContentFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.local_content.main, self.views)
end

function LocalContentFragment:getHelper()
  if not self.webViewHelper then
    tip("无法获取当前页面")
    return nil
  end
  return self.webViewHelper
end

function LocalContentFragment:initViews()
  local views = self.views
  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = { views.webview },
  })

  self:setupToolbar()
  self:initWebView()

  if self.mode == "save" then
    self:loadUrl()
   else
    self:loadLocalFile()
  end
end

function LocalContentFragment:setupToolbar()
  local toolbar = self.views.toolbar
  if not toolbar then return end

  local menuItems = {
    { id = "find", title = "查找", click = function() if self:getHelper() then self:getHelper():showSearchDialog() end end },
  }

  if self.mode == "save" then
    table.insert(menuItems, { id = "save", title = "保存", click = function() self:savePage() end })
   else
    table.insert(menuItems, { id = "jump", title = "原内容", click = function() self:jumpToOriginal() end })
  end

  table.insert(menuItems, { id = "pdf", title = "另存为PDF", click = function() self:saveAsPdf() end })
  table.insert(menuItems, { id = "share", title = "分享", click = function() self:shareContent() end })
  table.insert(menuItems, { id = "refresh", title = "刷新", click = function() if self:getHelper() then self:getHelper():reload() end end })

  Helpers.UI.setupToolbar(toolbar, {
    title = self.title or "本地内容",
    menu = menuItems
  })
end

function LocalContentFragment:initWebView()
  local views = self.views
  self.webView = views.webview

  -- 首先设置允许文件访问
  self.webView.settings
  .setAllowFileAccess(true)

  self.webViewHelper = WebViewHelper.new(self.webView)
  :initSettings()
  :initNoImageMode()
  :initDownloadListener()
  :setZhiHuUA()
  :setMessageListener(function(action, data)
    return self:onBridgeMessage(action, data)
  end)

  if self.mode == "save" then
    self.webViewHelper:setSettings({
      pageType = "answer",
      debug = false, -- 关闭 eruda 调试工具
      image_viewer = false, -- 关闭图片查看器
      fade_animation = false, -- 关闭淡入淡出动画
      dark_mode = false, -- 关闭暗色模式
      custom_font = false, -- 关闭自定义字体
      md_copy = false, -- 关闭 Markdown 复制
      scroll_restore = false, -- 关闭滚动恢复
      background_color = false, -- 不修改背景色
      enable_mhtml_convert = true, -- 启用 MHTML 转换
    })
  end

  Helpers.UI.setupSwipeRefresh(views.swipe_refresh, function()
    if self:getHelper() then self:getHelper():reload() end
  end)

  self.webViewHelper:setWebViewClient({
    shouldOverrideUrlLoading = function(view, url)
      view.loadUrl(url)
      return true
    end,
    onPageStarted = function(view, url)
      views.swipe_refresh.refreshing = true
      views.webview.visibility = View.GONE
    end,
    onPageFinished = function(view, url)
      views.swipe_refresh.refreshing = false
      views.webview.visibility = View.VISIBLE
    end
  })

  self.webViewHelper:setWebChromeClient({
    onReceivedTitle = function(view, title)
      if not self.pageTitle and views.toolbar then
        views.toolbar.title = title
      end
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

function LocalContentFragment:onBridgeMessage(action, data)
  if action == "saveHTML" then
    self:doSaveHtml(data)
   elseif action == "fetchMHTML" then
    local mhtmlPath = self.mhtmlPath
    if Extensions.File.exists(mhtmlPath) then
      return Extensions.File.read(mhtmlPath) or ""
    end
    return ""
  end
end

function LocalContentFragment:loadUrl()
  if not self:getHelper() or not self.url then return end
  self.views.webview.visibility = View.GONE
  self.webView.loadUrl(self.url)
end

function LocalContentFragment:loadLocalFile()
  if self.htmlPath and Extensions.File.exists(self.htmlPath) then
    self.views.webview.visibility = View.GONE
    -- 路径可能含 # 等 URL 保留字符，经 Uri 转义后再加载
    self.webView.loadUrl(Uri.fromFile(File(self.htmlPath)).toString())
   else
    tip("文件不存在")
    Router.back()
  end
end

local LuaWebViewBridge = require("helpers.luawebview_bridge")

function LocalContentFragment:savePage()
  if self.isSaving then return end
  self.isSaving = true
  tip("正在保存...")
  Extensions.File.mkdir(self.saveDir)

  local mhtmlPath = self.mhtmlPath
  self.webView.saveWebArchive(mhtmlPath, false, function(success, path)
    if not success then
      tip("保存 MHTML 失败")
      self.isSaving = false
      return
    end

    if self:getHelper() then
      self:getHelper():evaluateJavascript("MhtmlConvert.convert();", nil)
    end
  end)

  -- JS 侧转换失败时不回 saveHTML 消息，超时复位保存闩，「保存」菜单仍可再次触发
  Helpers.UI.runDelayed(15000, self:runIfAlive(function()
    if self.isSaving then
      self.isSaving = false
      tip("保存超时")
    end
  end))
end

function LocalContentFragment:doSaveHtml(html)
  -- JS 桥回调运行在 WebView 的桥线程，Toast 与 FragmentManager 操作必须搬到主线程
  if not html or html == "" then
    activity.runOnUiThread(self:runIfAlive(function()
      tip("保存失败：无法获取页面内容")
      self.isSaving = false
    end))
    return
  end

  Extensions.File.write(self.htmlPath, html)

  local detailContent = ""
  if self.contentId then
    detailContent = "answer_id=" .. self.contentId
    if self.questionId then
      detailContent = detailContent .. "\nquestion_id=" .. tostring(self.questionId)
    end
  end
  Extensions.File.write(self.detailPath, detailContent)

  local mhtmlPath = self.mhtmlPath
  if Extensions.File.exists(mhtmlPath) then
    Extensions.File.delete(mhtmlPath)
  end

  activity.runOnUiThread(self:runIfAlive(function()
    tip("保存成功")
    Router.back()
    self.isSaving = false
  end))
end

function LocalContentFragment:jumpToOriginal()
  if not Extensions.File.exists(self.detailPath) then
    tip("无法获取原链接")
    return
  end

  local detailText = Extensions.File.read(self.detailPath)
  if not detailText or detailText == "" then
    tip("无法获取原链接")
    return
  end
  local idPart = detailText:match("answer_id=([^\r\n]+)")
  if idPart then
    local goParams = { id = idPart }
    -- 已存在的 detail.txt 可能没有 question_id 行，缺失时不传，保持仅凭 id 跳转的现状
    local questionId = detailText:match("question_id=([^\r\n]+)")
    if questionId then
      goParams.questionId = questionId
    end
    Helpers.ZhihuParser.go("answer", goParams)
   else
    tip("无法解析原内容类型")
  end
end

function LocalContentFragment:shareContent()
  if self.mode == "save" then
    Helpers.UI.shareText(self.url, self.title)
   else
    -- 复制到 FileProvider 已声明的外部缓存临时目录再分享
    local tempDir = Helpers.UI.prepareShareTempDir()
    self._tempDir = tempDir

    local tempPath = tempDir .. "/" .. (self.title or "local_content") .. ".html"
    Extensions.File.copy(self.htmlPath, tempPath)

    Helpers.UI.shareFile(tempPath, self.title)
  end
end

function LocalContentFragment:saveAsPdf()
  if not self.webView then
    tip("WebView 未初始化")
    return
  end

  local printManager = activity.originalContext.getSystemService(Context.PRINT_SERVICE)
  if not printManager then
    tip("打印服务不可用")
    return
  end

  local printAdapter = self.webView.createPrintDocumentAdapter()
  local attributes = PrintAttributes.Builder()
  .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
  .setResolution(PrintAttributes.Resolution("pdf", "pdf", 300, 300))
  .setMinMargins(PrintAttributes.Margins.NO_MARGINS)
  .build()

  printManager.print(self.title .. ".pdf", printAdapter, attributes)
end

function LocalContentFragment:onPause()
  if self.webView then
    self.webView.setLayerType(View.LAYER_TYPE_HARDWARE, nil)
  end
end

function LocalContentFragment:onResume()
  if self.webView then
    self.webView.setLayerType(View.LAYER_TYPE_NONE, nil)
  end
end

return LocalContentFragment