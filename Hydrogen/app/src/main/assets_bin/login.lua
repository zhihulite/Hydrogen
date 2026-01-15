require "import"
import "mods.muk"
import "com.ua.*"
import "com.lua.LuaWebChrome"

url=... or "https://www.zhihu.com/signin"


local window = activity.getWindow()
window.addFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
if Build.VERSION.SDK_INT >= 30 then--Android R+
  window.setDecorFitsSystemWindows(false);
  window.setNavigationBarContrastEnforced(false);
  window.setStatusBarContrastEnforced(false);
end


设置视图("layout/login")

edgeToedge(nil,nil,function() local layoutParams = appbar.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  appbar.setLayoutParams(layoutParams); end)


波纹({_back,_info},"圆主题")

MyWebViewUtils=require "views/WebViewUtils"(login_web)

MyWebViewUtils
:initSettings()

local function checkLoginStatus(view)
  local cookie = 获取Cookie("https://www.zhihu.com/")
  if not cookie or not (cookie:find("z_c0") or cookie:find("q_c1")) then
    return false
  end

  local head = { ["cookie"] = cookie }
  zHttp.get('https://www.zhihu.com/api/v4/me', head, function(code, content)
    if code == 200 then
      local data = luajson.decode(content)
      activity.setSharedData("idx", data.id)
      提示("登录成功")
      activity.finish()
     else
      -- 允许继续尝试，不立即判死刑
      progress.setVisibility(8)
      login_web.setVisibility(0)
    end
  end)
  return true
end

MyWebViewUtils:initWebViewClient{
  shouldOverrideUrlLoading=function(view,url)
    if url:sub(1,4) ~= "http" then return true end

    -- 如果进入了主页相关的 URL，说明可能登录成功了
    if url:find("zhihu.com/?utm_id") or url:match("zhihu.com/?$") or url:find("zhihu.com/hot") then
      login_web.setVisibility(8)
      progress.setVisibility(0)
      if checkLoginStatus(view) then return true end
    end

    if url:find("qq.com") then
      view.stopLoading()
      view.getSettings().setUserAgentString("Mozilla/5.0 (Linux; Android 5.1; OPPO R9tm Build/LMY47I; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/53.0.2785.49 Mobile MQQBrowser/6.2 TBS/043128 Safari/537.36 V1_AND_SQ_7.0.0_676_YYB_D PA QQ/7.0.0.3135 NetType/4G WebP/0.3.0 Pixel/1080 Edg/125.0.0.0")
      view.loadUrl(url)
      return true
    end
  end,
  onPageStarted=function(view,url)
    _info.onLongClick=function()
      view.stopLoading()
      view.getSettings().setUserAgentString("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36")
      view.loadUrl("https://www.zhihu.com/signin")
    end
    if url:find("/signin") then
      加载js(view,获取js("login"))
    end
    if 全局主题值=="Night" then
      夜间模式主题(view)
    end
  end,
  onPageFinished=function(view,url)
    -- 增加更多的成功标志判断
    local isSuccessUrl = url:find("utm_id") or url:match("zhihu.com/?$") or url:find("zhihu.com/hot")
    
    if isSuccessUrl then
      if not checkLoginStatus(view) then
        progress.setVisibility(8)
        login_web.setVisibility(0)
      end
     else
      progress.setVisibility(8)
      login_web.setVisibility(0)
    end
  end,
}

MyWebViewUtils:initChromeClient({
  onConsoleMessage=function(consoleMessage)
    if consoleMessage.message():find("sign_data=")
      提示("登录成功")
      activity.setSharedData("signdata",consoleMessage.message():match("sign_data=(.+)"))
    end
  end
})

login_web.setDownloadListener({
  onDownloadStart=function(链接, UA, 相关信息, 类型, 大小)
    提示("本页不支持下载文件")
end})


login_web.loadUrl(url)


function onDestroy()
  login_web.destroy()
end