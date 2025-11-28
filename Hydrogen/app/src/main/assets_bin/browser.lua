require "import"
import "mods.muk"
import "com.ua.*"

url,urltitle=...

设置视图("layout/browser")
波纹({fh,_more},"圆主题")
edgeToedge(nil,nil,function() local layoutParams = topbar.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  topbar.setLayoutParams(layoutParams); end)


content.getSettings()
.setUseWideViewPort(true)
.setBuiltInZoomControls(true)
.setSupportZoom(true)

function onPause()
  content.setLayerType(View.LAYER_TYPE_SOFTWARE,nil)
end
function onResume()
  content.setLayerType(View.LAYER_TYPE_NONE,nil)
end

MyWebViewUtils=require "views/WebViewUtils"(content)

MyWebViewUtils
:initSettings()
:initNoImageMode()
:initDownloadListener()

if url:find("https://www.zhihu.com/messages") then
  MyWebViewUtils:setUA("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36")
 else
  MyWebViewUtils:setZhiHuUA()
end


--解决bing搜索白屏
local headers = HashMap()
headers.put("Referer", url)
content.loadUrl(url, headers)


_title.text="加载中"
content.setVisibility(8)
静态渐变(转0x(primaryc)-0x9f000000,转0x(primaryc),web_progressbar,"横")


MyWebViewUtils:initWebViewClient{
  shouldOverrideUrlLoading=function(view,url)--回调参数，v控件，url网址
    if url:find("zhihu.com") and url:find("https://www.zhihu.com/account/unhuman") then
      view.stopLoading()

      if url:find("zhihu.com/signin") then
        activity.newActivity("login")
        return true
      end

      if url:find("need_login=true") and not(url:find("https://www.zhihu.com/account/unhuman")) then
        AlertDialog.Builder(this)
        .setTitle("提示")
        .setMessage("登录可减少验证的出现 多次出现验证知乎可能会暂时封禁一些功能 如果长期使用推荐登录 如已验证通过请自行退出 如退出后多次出现请尝试登录")
        .setPositiveButton("我知道了", nil)
        .setNeutralButton("登录", {
          onClick = function() activity.newActivity("login") end
        })
        .setCancelable(false)
        .show()
        return true
      end

      return true
    end

    if url:sub(1,4) ~= "http" then
      if 检查意图(url, true) then
        检查意图(url)
        关闭页面()
        return true
       else
        if url:find("zhihu://search") then
          return true
        end
        双按钮对话框("提示","是否用第三方软件打开本链接？","是","否",
        function(an)
          xpcall(function()
            intent=Intent("android.intent.action.VIEW")
            intent.setData(Uri.parse(url))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP)
            this.startActivity(intent)
            an.dismiss()
          end,
          function()
            提示("尝试打开第三方app出错")
            an.dismiss()
          end)
        end,
        function(an)
          an.dismiss()
        end)
        return true
      end
    end

    if 检查链接(url, true) then
      if url:find("https://www.zhihu.com/answer/") then
        return true
      end
      检查链接(url)
      return true
    end

    if url == "https://www.zhihu.com"
      or url == "https://www.zhihu.com/"
      or url == "https://www.zhihu.com?utm" then
      return true
    end

    return false

  end,
  onPageStarted=function(view,url,favicon)
    if 全局主题值=="Night" then
      夜间模式主题(view)
    end

    local pop=table.clone(pop)
    if urltitle=="举报" then
      加载js内容=获取js("report")
     elseif urltitle=="提问" then
      加载js内容=获取js("ask")
     elseif urltitle=="新建专栏" then
      加载js内容=获取js("addcolumn")
     elseif url:find("https://www.zhihu.com/creator/hot%-question/hot") then
      加载js内容=获取js("hot_question")
     elseif url:find("https://www.zhihu.com/messages") then
      加载js内容=获取js("messages")
     elseif url:find("https://www.zhihu.com/notifications") then
      加载js内容=获取js("notification")
     elseif url:find("https://www.zhihu.com/settings/") then
      加载js内容=获取js("setting")
     else
      加载js内容=获取js("model")
    end

    --加载js(view,获取js("eruda"))

    a=MUKPopu(pop)

    if 加载js内容 then
      加载js(view,加载js内容)
    end
    content.setVisibility(0)
  end,
  onPageFinished=function(view,url)
    屏蔽元素(view,{"SignFlowHomepage-footer"})
  end
}

import "androidx.activity.result.ActivityResultCallback"
import "androidx.activity.result.contract.ActivityResultContracts"
mGetContent = thisFragment or this.registerForActivityResult(ActivityResultContracts.GetContent(),
ActivityResultCallback{
  onActivityResult=function(uri)
    if uri then
      local results = Uri[1];
      results[0]=uri
      mFilePathCallback.onReceiveValue(results);
     else
      mFilePathCallback.onReceiveValue(nil);
      mFilePathCallback = nil;
    end
end});

MyWebViewUtils:initChromeClient({
  onReceivedTitle=function(view, title)
    if urltitle then
      title=urltitle.." - 知乎"
    end
    _title.text=title
  end,

  onShowFileChooser=function(v,fic,fileChooserParams)
    mFilePathCallback = fic;
    mGetContent.launch("image/*;video/*");
    return true;
  end,

  onConsoleMessage=function(consoleMessage)
    --打印控制台信息
    if consoleMessage.message():find("加载完成") then
      content.setVisibility(0)
      progress.setVisibility(8)
     elseif consoleMessage.message():find("重新加载") then
      content.setVisibility(8)
      progress.setVisibility(0)
     elseif consoleMessage.message()=="显示评论" then
      newActivity("comment",{mresult,mmtype.."s"})
     elseif consoleMessage.message():find("toast分割") then
      local text=tostring(consoleMessage.message()):match("toast分割(.+)")
      提示(text)
    end
  end,
})



pop={
  tittle="网页",
  list={
    {src=图标("refresh"),text="刷新",onClick=function()
        content.reload()
    end},
    {src=图标("redo"),text="前进",onClick=function()
        content.goForward()
    end},
    {src=图标("undo"),text="后退",onClick=function()
        content.goBack()
    end},
    {src=图标("close"),text="停止",onClick=function()
        content.stopLoading()
    end},

    {src=图标("share"),text="分享",onClick=function()
        分享文本(content.getUrl())
      end,
      onLongClick=function()
        分享文本(content.getUrl(),true)
    end},
    {
      src=图标("search"),text="在网页查找内容",onClick=function()
        webview查找文字(content)
      end
    },

  }
}


task(1,function()
  a=MUKPopu(pop)
end)