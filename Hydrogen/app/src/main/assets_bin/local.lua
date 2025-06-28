require "import"
import "mods.muk"
import "android.text.method.LinkMovementMethod"
import "android.text.Html"
import "java.net.URL"
import "android.webkit.WebChromeClient"
import "android.content.pm.ActivityInfo"
import "android.graphics.PathMeasure"


title,author=...


波纹({fh,_more,mark},"圆主题")
波纹({all_root},"方自适应")

local 保存路径=内置存储文件("Download/"..title.."/"..author)
filedir=保存路径.."/html.html"
xxx=读取文件(保存路径.."/detail.txt")

if 文件是否存在(filedir)==false then
  提示("当前保存内容需要重新保存 请手动点击右上角保存重新保存")
end

if xxx:match("article") or xxx:match("pin") then
  关闭页面()
  newActivity("column",{filedir,"本地"})
  return
end

task(1,function()
  local loaduri = Uri.fromFile(File(filedir)).toString();
  t.content.loadUrl(loaduri)
end)

--new 0.53 引入mhtml2html解析mhtml 去除大量mhtml替换逻辑

import "androidx.viewpager2.widget.ViewPager2"
设置视图("layout/local")
设置toolbar(toolbar)

edgeToedge(mainLay,底栏,function()
  pg.setPadding(
  pg.getPaddingLeft(),
  pg.getPaddingTop(),
  pg.getPaddingRight(),
  dp2px(56)+导航栏高度);
end)


local isDoubleTap=false
local timeOut=200

local detector=GestureDetector(this,{a=lambda _:_})

detector.setOnDoubleTapListener {
  onDoubleTap=function()
    t.content.scrollTo(0, 0)
    isDoubleTap=true
    task(timeOut,function()isDoubleTap=false end)
  end
}

all_root.onTouch=function(v,e)
  return detector.onTouchEvent(e)
end

all_root.onClick=function(v)
  if not isDoubleTap then
    task(timeOut,function()
      if not isDoubleTap then
        local questionid=xxx:match[[question_id="(.-)"]]
        activity.newActivity("question",{questionid})
      end
    end)
  end
end

--解决快速滑动出现的bug 点击停止滑动
local AppBarLayoutBehavior=luajava.bindClass "com.hydrogen.AppBarLayoutBehavior"
appbar.LayoutParams.behavior=AppBarLayoutBehavior(this,nil)

pg.setUserInputEnabled(false) --禁止滑动


波纹({all_root},"方自适应")

_title.text=title

--维持和answer.lua的统一性
t={}
local 加入view=loadlayout({
  LinearLayout,
  layout_width="fill";
  layout_height="fill";
  id="root";
  layoutTransition=LayoutTransition(),
  {
    NestedLuaWebView,
    id="content",
    layout_width="-1";
    layout_height="-1";
    Visibility=8;
  };
},t)

import "com.dingyi.adapter.BaseViewPage2Adapter"
pg.adapter=BaseViewPage2Adapter(this)
pg.adapter.add(加入view)

userinfo.onClick=function()
  提示("请点击右上角「使用网络打开」打开原回答页后查看")
end


username.text=xxx:match[[author="(.-)"]]
userheadline.text=xxx:match[[headline="(.-)"]]
if userheadline.text=="" then
  userheadline.text="Ta还没有签名哦~"
end

thanks_count.text=xxx:match[[thanks_count="(.-)"]]
favlists_count.text=xxx:match[[favlists_count="(.-)"]] or "未知"
vote_count.text=xxx:match[[vote_count="(.-)"]]

comment.onClick=function()
  local 保存路径=内置存储文件("Download/"..title:gsub("/","or").."/"..username.text)
  if getDirSize(保存路径.."/".."fold/")==0 then
    提示("你还没有收藏评论")
   else
    newActivity("comment",{nil,"local",保存路径})
  end
end;

function 网络打开提示()
  提示("请点击右上角「使用网络打开」打开原回答页后进行该操作")
end

mark.onClick=网络打开提示
thank.onClick=网络打开提示
voteup.onClick=网络打开提示

波纹({fh,_more,mark,comment,thank,voteup},"圆主题")

t.content.getSettings()
.setAllowFileAccess(true)

t.content.setDownloadListener({
  onDownloadStart=function(链接, UA, 相关信息, 类型, 大小)
    提示("本地暂不支持下载")
end})

WebViewUtils=require "views/WebViewUtils"
local MyWebViewUtils=WebViewUtils(t.content)
local function 设置滑动跟随(t)
  t.onGenericMotion=function(view,x,y,lx,ly)
    if t.getScrollY()<=0 then
      appbar.setExpanded(true);
     else
      appbar.setExpanded(false);
    end
  end
end

设置滑动跟随(t.content)
MyWebViewUtils:initSettings()
:initSettings()
:initNoImageMode()

MyWebViewUtils:initWebViewClient{
  shouldOverrideUrlLoading=function(view,url)
    检查链接(url)
    t.content.setVisibility(8)
    return true
  end,
  onPageStarted=function(view,url,favicon)
    view.setVisibility(8)
    加载js(view,获取js("mdcopy"))
  end,
  onPageFinished=function(view,l)
    if 全局主题值=="Night" then
      夜间模式回答页(view)
     else
      初始化背景(view)
    end
    view.setVisibility(0)
  end
}


import "androidx.activity.result.ActivityResultCallback"
import "androidx.activity.result.contract.ActivityResultContracts"
createDocumentLauncher = thisFragment.registerForActivityResult(ActivityResultContracts.CreateDocument("text/markdown"),
ActivityResultCallback{
  onActivityResult=function(uri)
    if uri then
      local outputStream = this.getContentResolver().openOutputStream(uri);
      local content = String(saf_writeText);
      outputStream.write(content.getBytes());
      outputStream.close();
      提示("保存md文件成功")
    end
end});

task(1,function()
  a=MUKPopu({
    tittle="回答",
    list={
      {
        src=图标("error"),text="相关",onClick=function()
          提示("如果有问题 可以点击主页右上角 在弹出菜单点击反馈进行反馈")
        end
      },

      {
        src=图标("cloud"),text="使用网络打开",onClick=function()
          local questionid=xxx:match[[question_id="(.-)"]]
          local answerid=xxx:match[[answer_id="(.-)"]]
          newActivity("answer",{questionid,answerid})
        end
      },

      {
        src=图标("cloud"),text="另存为pdf/md",onClick=function()

          local 单选列表={"另存pdf","另存为md"}
          local dofun={
            function()
              import "android.print.PrintAttributes"
              printManager = this.getOriginalContext().getSystemService(Context.PRINT_SERVICE);
              printAdapter = t.content.createPrintDocumentAdapter();
              printManager.print("文档", printAdapter,PrintAttributes.Builder().build());

            end,
            function()
              t.content.evaluateJavascript('getmd()',{onReceiveValue=function(b)
                  提示("请选择一个保存位置")
                  saf_writeText=b
                  createDocumentLauncher.launch(title.."_"..author..".md");
              end})
          end}
          dialog=AlertDialog.Builder(this)
          .setTitle("请选择")
          .setSingleChoiceItems(单选列表,-1,{onClick=function(v,p)
              dofun[p+1]()
              dialog.dismiss()
          end})
          .setPositiveButton("关闭",nil)
          .show()

        end
      },

      {
        src=图标("search"),text="在网页查找内容",onClick=function()
          local content=t.content
          webview查找文字(content)
        end
      },

    }
  })
end)

if this.getSharedData("显示虚拟滑动按键")=="true" then
  bottom_parent.Visibility=0
  up_button.onClick=function()
    t.content.scrollBy(0, -t.content.height);
    if t.content.getScrollY()<=0 then
      appbar.setExpanded(true,false);
    end
  end
  down_button.onClick=function()
    t.content.scrollBy(0, t.content.height);
    appbar.setExpanded(false,false);
  end
end