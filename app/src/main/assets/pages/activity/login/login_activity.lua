-- pages/activity/login/login_activity.lua
-- 登录页面

require("init_app")

local BaseActivity = require("pages.base.base_activity")
local WebViewHelper = require("components.views.web_view_helper")

local LoginActivity = Extensions.Class(BaseActivity, {"login"})

function LoginActivity:onCreate(params)
  self.url = (params and params.url) or "https://www.zhihu.com/signin"
end

function LoginActivity:initLayout()
  self.root_view = loadlayout(Layouts.pages.login.main, self.views)
end

function LoginActivity:initViews()
  local views = self.views
  local toolbar = views.toolbar
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
    top = { views.main_container },
  })

  self.webViewHelper = WebViewHelper.new(views.webview)
  :initSettings()
  :initDownloadListener()
  :setWebViewClient({
    shouldOverrideUrlLoading = function(_, url)
      if url:find("utm_id") or url:match("zhihu%.com/?$") then
        return self:checkLogin()
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
      views.progress.visibility = View.GONE
      views.webview.visibility = View.VISIBLE
    end,
  })
  :setWebChromeClient({
    onProgressChanged = function(_, p)
      views.progress.visibility = p < 100 and View.VISIBLE or View.GONE
      views.webview.visibility = p < 100 and View.GONE or View.VISIBLE
    end,
  })
  :setMessageListener(function(action, data)
    if action == "login_success" then
      Extensions.Config.set(Constants.SharedDataKeys.SIGN_IN_DATA, data)
    end
  end)

  self:switchMode(false)
end

function LoginActivity:switchMode(isPC)
  if isPC then
    self.webViewHelper:setPCUA()
   else
    self.webViewHelper:setUA()
  end
  self.webViewHelper.webView.loadUrl(self.url)
end

-- 返回是否接管本次导航：cookie 里没有登录票据时交还 WebView 继续加载
function LoginActivity:checkLogin()
  local cookie = NetWork.getCookie("https://www.zhihu.com/")
  if not cookie or not (cookie:find("z_c0") or cookie:find("q_c1")) then
    return false
  end

  NetWork.get("https://www.zhihu.com/api/v4/me", { cookie = cookie }, self:runIfAlive(function(code, content)
    -- /me 可能返回 200 但 body 非 JSON，解码失败按校验失败处理
    local result = nil
    if code == 200 and content then
      local ok, decoded = pcall(json.decode, content)
      if ok then
        result = decoded
      end
    end
    if result and result.id then
      Extensions.Config.set(Constants.SharedDataKeys.USER_ID, result.id)
      CookieManager.instance.flush()
      tip("登录成功")
      Helpers.UI.runDelayed(500, self:runIfAlive(function()
        self:finish()
      end))
     else
      tip("登录状态校验失败，请重试")
    end
  end))
  return true
end

function LoginActivity:clearCookie()
  Helpers.BottomDialog.confirm("确定清除 Cookie 吗？", self:runIfAlive(function()
    CookieManager.instance.removeAllCookies(nil)
    CookieManager.instance.flush()
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