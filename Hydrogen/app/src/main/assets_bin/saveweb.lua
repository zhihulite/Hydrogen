require "import"
import "mods.muk"
import "com.ua.*"

chrome = import "com.lua.LuaWebChrome";
client = import "com.lua.LuaWebViewclient";
callback = import "com.androlua.LuaWebView$LuaWebViewClient";


保存url,保存路径,写入内容=...

设置视图("layout/browser")
波纹({fh,_more},"圆主题")
edgeToedge(nil,nil,function() local layoutParams = topbar.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  topbar.setLayoutParams(layoutParams); end)

content.getSettings()
.setAllowFileAccess(true)

MyWebViewUtils=require "views/WebViewUtils"(content)

MyWebViewUtils
:initSettings()
:initNoImageMode()
:initDownloadListener()
:setZhiHuUA()

_title.text="加载中"
content.loadUrl(保存url)
content.setVisibility(8)
静态渐变(转0x(primaryc)-0x9f000000,转0x(primaryc),web_progressbar,"横")
提示("请在页面加载完毕后手动点击右上角保存页面")

local webview_loadurl=content.getUrl()
local mhtml2html=Uri.fromFile(File(this.getLuaDir().."/mhtml2html.html")).toString()

MyWebViewUtils:initWebViewClient{
  shouldOverrideUrlLoading=function(view,url)--回调参数，v控件，url网址
    view.stopLoading()
  end,
  onPageStarted=function(view,url,favicon)
    webview_loadurl=url
    content.setVisibility(0)
  end,
  onLoadResource=function(view,url)
  end,
  onPageFinished=function(view,url)
    屏蔽元素(view,{"SignFlowHomepage-footer"})
    屏蔽元素(view,{".AnswerReward",".AppViewRecommendedReading"})
end}

MyWebViewUtils:initChromeClient({
  onReceivedTitle=function(view, title)
    _title.text=title
  end,
  onShowFileChooser=function(v,fic,fileChooserParams)
  end,
  onConsoleMessage=function(consoleMessage)
    if consoleMessage.message():find("toast分割") then
      local text=tostring(consoleMessage.message()):match("toast分割(.+)")
      提示(text)
    end
  end,
})


--设置网页图片点击事件，
local z=JsInterface{
  execute=function(b)
    if b=="getmhtml" then
      return 读取文件(保存路径.."/mht.mht")
     elseif webview_loadurl~=mhtml2html then
      return 提示("本页不支持该操作 只支持保存文件")
     else
      删除文件(保存路径.."/mht.mht")
      写入文件(保存路径.."/html.html",b)
      savedialog.dismiss()
      提示("保存成功")
      关闭页面()
    end
  end
}

content.addJSInterface(z,"hydrogen")


pop={
  tittle="网页",
  list={
    {src=图标("refresh"),text="刷新",onClick=function()
        content.reload()
    end},
    {src=图标("get_app"),text="保存到本地",onClick=function()
        local 父文件夹路径=tostring(File(保存路径).getParentFile())
        if not(文件夹是否存在(父文件夹路径)) then
          创建文件夹(父文件夹路径)
        end
        savedialog=AlertDialog.Builder(this)
        .setTitle("提示")
        .setMessage("保存中 请耐心等待")
        .setCancelable(false)
        .show()
        创建文件夹(保存路径)
        local 详情文件夹=保存路径.."/detail.txt"
        创建文件(详情文件夹)
        写入文件(详情文件夹,写入内容)
        content.saveWebArchive(保存路径.."/mht.mht")
        提示("保存成功 请稍等写入完成［一般2S内完成］")
        taskUI(1000,function()
          content.loadUrl(mhtml2html)
          提示("转换中")
        end)
    end},

    {src=图标("share"),text="分享",onClick=function()
        分享文本(content.getUrl())
      end,
      onLongClick=function()
        分享文本(content.getUrl(),true)
    end},
  }
}

taskUI(function()
  a=MUKPopu(pop)
end)