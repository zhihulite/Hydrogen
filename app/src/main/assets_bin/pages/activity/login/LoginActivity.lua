-- pages/activity/login/LoginActivity.lua
-- 登录页面

local BaseActivity = require("pages.base.BaseActivity")
local WebViewHelper = require("components.views.WebViewHelper")

local LoginActivity = Extensions.Class(BaseActivity, {"login"})
LoginActivity:chainUp("onDestroy")

function LoginActivity:onCreate(params)
  self.url = (params and params.url) or "https://www.zhihu.com/signin"
end

function LoginActivity:initLayout()
  self.root_view = loadlayout(Layouts.pages.login.main, self.views)
end

function LoginActivity:initViews()
  local toolbar = self.views.toolbar
  Helpers.UI.setupToolbar(toolbar, {
    title = "登录至 Hydrogen",
    menu = {
      { id = "pc_mode", title = "PC 模式", click = function() self:switchMode(true) end },
      { id = "mobile_mode", title = "移动模式", click = function() self:switchMode(false) end },
      { id = "refresh", title = "刷新", click = function() if self.webViewHelper then self.webViewHelper:reload() end end },
      { id = "clear_cookie", title = "清除 Cookie", click = function() self:clearCookie() end },
    }
  })

  self:setupEdgeToEdge({
    top = { self.views.main_container },
  })

  self.webViewHelper = WebViewHelper.new(self.views.webview)
  :initSettings()
  :initDownloadListener()
  :setWebViewNetWork({
    shouldOverrideUrlLoading = function(_, url)
      if url:find("utm_id") or url:match("zhihu.com/?$") then
        self:checkLogin()
        return true
      end
      if url:find("qq.com") then
        _.stopLoading()
        self.webViewHelper:setQQUA()
        _.loadUrl(url)
        return true
      end
      return false
    end,
    onPageFinished = function(_, url)
      self.views.progress.setVisibility(View.GONE)
      self.views.webview.setVisibility(View.VISIBLE)
    end,
  })
  :setWebChromeNetWork({
    onProgressChanged = function(_, p)
      self.views.progress.setVisibility(p < 100 and View.VISIBLE or View.GONE)
      self.views.webview.setVisibility(p < 100 and View.GONE or View.VISIBLE)
    end,
  })
  :setMessageListener(function(action, data)
    if action == "login_success" then
      Extensions.Config.set(Constants.SharedDataKeys.SIGN_IN_DATA, data)
    end
  end)

  self:switchMode(false)
  self.webViewHelper.webView.loadUrl(self.url)
end

function LoginActivity:switchMode(isPC)
  if isPC then
    self.webViewHelper:setPCUA()
   else
    self.webViewHelper:setUA()
  end
  self.webViewHelper.webView.loadUrl("https://www.zhihu.com/signin")
end

function LoginActivity:checkLogin()
  local cookie = NetWork.getCookie("https://www.zhihu.com/")
  if not cookie or not (cookie:find("z_c0") or cookie:find("q_c1")) then
    return
  end

  NetWork.get("https://www.zhihu.com/api/v4/me", { cookie = cookie }, self:runIfAlive(function(success, data)
    if success and data then
      local result = json.decode(data)
      if result and result.id then
        Extensions.Config.set(Constants.SharedDataKeys.USER_ID, result.id)
        CookieManager.getInstance().flush()
        tip("登录成功")
        task(500, self:runIfAlive(function()
          self:finish()
        end))
      end
    end
  end))
end

function LoginActivity:clearCookie()
  Helpers.BottomDialog.confirm("确定清除 Cookie 吗？", self:runIfAlive(function()
    CookieManager.getInstance().removeAllCookies(nil)
    CookieManager.getInstance().flush()
    if self.webViewHelper then self.webViewHelper:reload() end
    tip("已清除 Cookie")
  end))
end

function LoginActivity:onDestroy()
  if self.webViewHelper then
    self.webViewHelper:destroy()
    self.webViewHelper = nil
  end
  self.views = nil
end

return LoginActivity