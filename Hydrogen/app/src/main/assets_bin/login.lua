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

MyWebViewUtils:initWebViewClient{
  shouldOverrideUrlLoading=function(view,url)

    if url:sub(1,4)~="http" then
      return true
    end

    if not view.getUrl():find("https://www.zhihu.com/%?utm_id") and view.getUrl()~="https://www.zhihu.com/" then
      login_web.setVisibility(8)
      progress.setVisibility(0)
    end

    if url:find("qq.com") then
      view.stopLoading()
      view.getSettings().setUserAgentString("Mozilla/5.0 (Linux; Android 5.1; OPPO R9tm Build/LMY47I; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/53.0.2785.49 Mobile MQQBrowser/6.2 TBS/043128 Safari/537.36 V1_AND_SQ_7.0.0_676_YYB_D PA QQ/7.0.0.3135 NetType/4G WebP/0.3.0 Pixel/1080 Edg/125.0.0.0")
      view.loadUrl(url)
      return
    end

  end,
  onPageStarted=function(view,url)
    _info.onLongClick=function()
      view.stopLoading()
      view.getSettings().setUserAgentString("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36")
      view.loadUrl("https://www.zhihu.com/signin")
    end
    if url:find("https://www.zhihu.com/signin") then
      加载js(view,获取js("login"))
    end
    if 全局主题值=="Night" then
      夜间模式主题(view)
    end
  end,
  onPageFinished=function(view,url)
    if url:find("https://www.zhihu.com/%?utm_id") or url=="https://www.zhihu.com" or url=="https://www.zhihu.com/" then
      if isfirst==nil then
        isfirst=true
        --尝试解决登录无效的问题
        view.loadUrl("https://www.zhihu.com/")
        return
      end
      local myurl= 'https://www.zhihu.com/api/v4/me'
      --避免head刷新不及时
      local head = {
        ["cookie"] = 获取Cookie("https://www.zhihu.com/")
      }
      zHttp.get(myurl,head,function(code,content)
        if tostring(code)=="200" then
          local data=luajson.decode(content)
          local uid=data.id
          activity.setSharedData("idx",uid)
          --
          加载js(view,"document.cookie = document.cookie")
          activity.finish()
          --[=[AlertDialog.Builder(this)
          .setTitle("提示")
          .setMessage("登录后建议手动重启软件来保持数据一致性 不重启可能导致一些问题")
          .setPositiveButton("我知道了",{onClick=function() 
activity.recreate() --[[import "android.os.Process"
              local intent =activity.getBaseContext().getPackageManager().getLaunchIntentForPackage(activity.getBaseContext().getPackageName());
              intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
              activity.startActivity(intent);
              Process.killProcess(Process.myPid());]]end})
          .setCancelable(false)
          .show()]=]

         else
          view.loadUrl("https://www.zhihu.com/signin")
          加载js(view,"document.cookie = ''")
          提示("登录失败")
        end
      end)

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