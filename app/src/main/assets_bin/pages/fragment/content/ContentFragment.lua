-- pages/fragment/content/ContentFragment.lua

local BaseFragment = require("pages.base.BaseFragment")
local ContentModel = require("models.content.ContentModel")
local WebViewHelper = require("components.views.WebViewHelper")
local CollectionMoveSheet = require("components.dialog.CollectionMoveSheet")

local ContentFragment = Extensions.Class(BaseFragment, {"content"})

function ContentFragment:ctor()
  self.contentId = nil
  self.contentType = nil
  self.model = nil
  self.webViewHelper = nil
  self.menuItems = {}
  self.backCallback = nil
end

function ContentFragment:onCreate(params)
  self.contentId = tostring(params.id)
  self.contentType = params.type or "article"
  self.model = ContentModel(self.contentId, self.contentType)
end

function ContentFragment:onDestroy()
  if self.webViewHelper then
    self.webViewHelper:destroy()
    self.webViewHelper = nil
  end
  if self.model then
    self.model:destroy()
    self.model = nil
  end
end

function ContentFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.content.main, self.views)
end

function ContentFragment:getHelper()
  if not self.webViewHelper then
    tip("无法获取当前页面")
    return nil
  end
  return self.webViewHelper
end

function ContentFragment:initViews()
  local views = self.views
  -- TODO paddingbottom 注入应该可以 https://developer.chrome.com/docs/css-ui/edge-to-edge?hl=zh-cn
  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = { views.main_container },
  })
  self:setupToolbar()
  self:initWebView()
  self:loadContent()
end

-- Toolbar
function ContentFragment:setupToolbar()
  local toolbar = self.views.toolbar
  if not toolbar then return end

  -- 构建菜单项
  local menuItems = {
    { id = "find", title = "查找", click = function() if self:getHelper() then self:getHelper():showSearchDialog() end end },
    { id = "share", title = "分享", click = function() self:shareContent() end },
    { id = "copy", title = "复制链接", click = function() self:copyContent() end },
    { id = "open", title = "浏览器打开", click = function() self:openInBrowser() end },
    { id = "refresh", title = "刷新", click = function() if self:getHelper() then self:getHelper():reload() end end },
  }

  -- 如果允许收藏，添加收藏菜单项
  if self.model:canFavorite() then
    table.insert(menuItems, 2, {
      id = "favorite",
      title = "加入收藏",
      click = function() self:showFavoriteMoveSheet() end
    })
  end

  Helpers.UI.setupToolbar(toolbar, {
    title = "加载中...",
    menu = menuItems
  })
end

function ContentFragment:onBridgeMessage(action, data)
  if action == "showCollection" then
    local contentType = self.contentType
    local contentId = self.contentId
    local callbackId = data
    activity.runOnUiThread(function()
      CollectionMoveSheet.show({
        contentId = contentId,
        contentType = contentType,
        onSuccess = function(stillInAnyCollection, addCount)
          local collected = tostring(stillInAnyCollection)
          local sendobj = '{"id":"'..callbackId..'","type":"success","params":{"contentType":"'..contentType..'","contentId":"'..contentId..'","collected":'..collected..'}}'
          if self:getHelper() then
            self:getHelper():evaluateJavascript('window.zhihuWebApp && window.zhihuWebApp.callback('..sendobj..')')
          end
        end,
        onError = function(err)
          tip(err or "操作失败")
        end
      })
    end)
  end
end

-- WebView
function ContentFragment:initWebView()
  local views = self.views
  self.webViewHelper = WebViewHelper.new(views.webview)
  :initSettings()
  :initNoImageMode()
  :initDownloadListener()
  :setZhiHuUA()
  :setSettings({
    enableScrollTracking = true
  })
  :setMessageListener(function(action, data)
    self:onBridgeMessage(action, data)
  end)

  self.webViewHelper:setWebViewClient({
    shouldOverrideUrlLoading = function(view, url)
      -- 评论
      local commentType, id = url:match("comment/list/([^/]+)/(%d+)$")
      if commentType and id then
        local CommentSheet = require("components.dialog/CommentSheet")
        CommentSheet.show({ contentId = id, contentType = commentType })
        return true
      end
      -- 专栏
      local contentId, contentType = url:match("column/republish_apply%?id=(%d+)&type=(%w+)")
      if contentId and contentType then
        local ColumnMoveSheet = require("components.dialog.ColumnMoveSheet")
        ColumnMoveSheet.show({
          contentId = contentId,
          contentType = contentType
        })
        return true
      end
      Helpers.UI.copyText(url)
      Helpers.ZhihuParser.goUrl(url)
      return true
    end,
    onPageStarted = function(view, url)
      views.swipe_refresh.refreshing = true
    end,
    onPageFinished = function(view, url)
      views.progress_bar.visibility = View.GONE
      views.swipe_refresh.refreshing = false
    end,
  })

  self.webViewHelper:setWebChromeClient({
    onProgressChanged = function(view, progress)
      views.progress_bar.visibility = progress < 100 and View.VISIBLE or View.GONE
      views.progress_bar.progress = progress
    end
  })

  Helpers.UI.setupSwipeRefresh(views.swipe_refresh, self:runIfAlive(function()
    if self:getHelper() then self:getHelper():reload() end
  end))
end

function ContentFragment:loadContent()
  self.model:load(nil, self:runIfAlive(function(success, data)
    if success and data and data.webUrl then
      if self:getHelper() then
        self:getHelper().webView.loadUrl(data.webUrl)
      end
      self.views.toolbar.title = data.title
    end
  end))
end

-- 菜单动作
function ContentFragment:shareContent()
  local data = self.model and self.model:getData()
  local url = data and (data.shareUrl or data.webUrl)
  if url then Helpers.UI.shareText(url) end
end

function ContentFragment:copyContent()
  local data = self.model and self.model:getData()
  local url = data and data.webUrl
  if url then Helpers.UI.copyText(url) end
end

function ContentFragment:openInBrowser()
  local data = self.model and self.model:getData()
  local url = data and data.webUrl
  if url then Helpers.UI.openUrl(url) end
end

function ContentFragment:showFavoriteMoveSheet()
  CollectionMoveSheet.show({
    contentId = self.contentId,
    contentType = self.contentType,
    onSuccess = function()
      tip("操作完成")
    end,
    onError = function(err)
      tip(err or "操作失败")
    end
  })
end

import "android.view.View"
function ContentFragment:onPause()
  if self.webView then
    self.webView.setLayerType(View.LAYER_TYPE_HARDWARE, nil)
  end
end

function ContentFragment:onResume()
  if self.webView then
    self.webView.setLayerType(View.LAYER_TYPE_NONE, nil)
  end
end

return ContentFragment