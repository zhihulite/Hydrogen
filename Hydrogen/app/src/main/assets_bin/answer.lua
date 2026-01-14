require "import"
import "mods.muk"
import "com.lua.*"
import "android.text.method.LinkMovementMethod"
import "android.text.Html"
import "java.net.URL"
import "com.bumptech.glide.Glide"
import "androidx.viewpager2.widget.ViewPager2"
import "com.dingyi.adapter.BaseViewPage2Adapter"
import "android.view.*"
import "androidx.viewpager2.widget.ViewPager2$OnPageChangeCallback"
import "android.webkit.WebChromeClient"
import "android.content.pm.ActivityInfo"
import "android.graphics.PathMeasure"
import "android.webkit.ValueCallback"
import "com.google.android.material.progressindicator.LinearProgressIndicator"
import "androidx.core.view.ViewCompat"
import "com.google.android.material.appbar.AppBarLayout"
问题id,回答id=...

--new 0.46 删除滑动监听

local MaterialContainerTransform = luajava.bindClass "com.google.android.material.transition.MaterialContainerTransform"
--[=[if inSekai then
  --[[if fn[#fn][1]=="answer" then
activity.getSupportFragmentManager().popBackStack()
    table.remove(fn,#fn)
end]]
  local t = activity.getSupportFragmentManager().beginTransaction()
  t.setCustomAnimations(
  android.R.anim.slide_in_left,
  android.R.anim.slide_out_right,
  android.R.anim.slide_in_left,
  android.R.anim.slide_out_right)
  --t.remove(activity.getSupportFragmentManager().findFragmentByTag("answer"))
  t.add(f2.getId(),LuaFragment(loadlayout("layout/answer")),"answer")
  t.addToBackStack(nil)
  t.commit()
  table.insert(fn,{"answer",2})
 else
  activity.setContentView(loadlayout("layout/answer"))
end
]=]


设置视图("layout/answer")
--设置toolbar(toolbar)

edgeToedge(nil,nil,function()
  --[[task(10,function()pg.setPadding(
  pg.getPaddingLeft(),
  pg.getPaddingTop(),
  pg.getPaddingRight(),
  dtl.height);
print(dtl.height)]]
  --root_card.layoutParams= root_card.layoutParams.setMargins(0,状态栏高度,0,0)
  root_card.setPadding(0,状态栏高度,0,0)
  title_bar_expand.layoutParams= title_bar_expand.layoutParams.setMargins(0,状态栏高度+dp2px(64,true),0,0)
  local safeStatus=safeStatusView.layoutParams
  safeStatus.height=状态栏高度
  safeStatusView.setLayoutParams(safeStatus)
  静态渐变(转0x(backgroundc),0x00000000,safeStatusView,"竖")

end)

local recyclerViewField = ViewPager2.getDeclaredField("mRecyclerView");
recyclerViewField.setAccessible(true);
local recyclerView = recyclerViewField.get(pg);
local touchSlopField = RecyclerView.getDeclaredField("mTouchSlop");
touchSlopField.setAccessible(true);
local touchSlop = touchSlopField.get(recyclerView);
touchSlopField.set(recyclerView, int(touchSlop*tonumber(activity.getSharedData("scroll_sense"))));--通过获取原有的最小滑动距离 *n来增加此值

--解决快速滑动出现的bug 点击停止滑动
local AppBarLayoutBehavior=luajava.bindClass "com.hydrogen.AppBarLayoutBehavior"
--appbar.LayoutParams.behavior=AppBarLayoutBehavior(this,nil)
IArgbEvaluator=ArgbEvaluator.newInstance()
波纹({fh,_more,mark,comment,thank,voteup},"圆主题")
波纹({all_root},"方自适应")
设置toolbar(root_card)
import "model.answer"

appbar.addOnOffsetChangedListener(AppBarLayout.OnOffsetChangedListener{
  onOffsetChanged = function(appBarLayout, verticalOffset)
    local progress = (-verticalOffset)/(all_root_expand.height)
    if progress==1
      isAppBarLaunch=true
      --mainLay.backgroundColor=res.color.attr.colorSurfaceContainer

     else
      --_title.setPadding(0,dp2px(60)*(1-progress),0,0)
      all_root.alpha=progress
    end
  end
})

function onPause()
  mainLay.setLayerType(View.LAYER_TYPE_SOFTWARE,nil)
end
function onResume()
  数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content.resumeTimers()
  mainLay.setLayerType(View.LAYER_TYPE_NONE,nil)
end
local function 设置滑动跟随(t)
  t.onGenericMotion=function(view,x,y,lx,ly)
    if t.getScrollY()<=0 then
      appbar.setExpanded(true);
     else
      appbar.setExpanded(false);
    end
  end
end

comment.onClick=function()
  local pos=pg.getCurrentItem()
  local mview=数据表[pg.adapter.getItem(pos).id]
  local 回答id=mview.data.id
  if 回答id==nil then
    return 提示("加载中")
  end
  local 保存路径=内置存储文件("Download/".._title.Text.."/"..username.Text)
  ViewCompat.setTransitionName(comment,"t")
  nTView=comment_card
  newActivity("comment",{回答id,"answers",保存路径})
end;


回答容器=answer:new(回答id)

if activity.getSharedData("回答单页模式")=="true" then
  pg.setUserInputEnabled(false);
end

local detector=GestureDetector(this,{a=lambda _:_})
local isDoubleTap=false
local timeOut=500
detector.setOnDoubleTapListener {
  onDoubleTap=function()
    local pos=pg.getCurrentItem()
    local mview=数据表[pg.adapter.getItem(pos).id]
    mview.ids.content.scrollTo(0, 0)
    isDoubleTap=true
    task(timeOut,function()isDoubleTap=false end)
  end
}

all_root.onClick=function(v)
  if not isDoubleTap then
    task(timeOut,function()
      if not isDoubleTap then
        if 问题id==nil or 问题id=="null" then
          return 提示("加载中")
        end
        newActivity("question",{问题id})
      end
    end)
  end
end

all_root_expand.onClick=function()
  if 问题id==nil or 问题id=="null" then
    return 提示("加载中")
  end
  newActivity("question",{问题id})
end

all_root.onLongClick=function(view)

  local url=数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content.getUrl()
  if url==nil then
    提示("加载中")
    return
  end
  local format="【回答】【%s】%s: %s"
  local text=(string.format(format,_title.Text,username.Text,"https://www.zhihu.com/question/"..问题id.."/answer/"..url:match("answer/(.+)")))
  --local uri=activity.getUriForPath(activity.getLuaDir().."/ic_launcher-playstore.png")
  --选择一个幸运的视图作为阴影
  local shadowBuilder=View.DragShadowBuilder(view)
  local clipData=ClipData.newPlainText("知乎回答",text)
  --local clipData=ClipData.newUri(activity.getContentResolver(), "URI", Uri.parse("https://www.zhihu.com/question/"..问题id.."/answer/"..url:match("answer/(.+)")))
  --启动拖放
  --startDragAndDrop是api24加入的，所以要进行版本号的判断。虽然startDrag也能做到相同的效果，但是startDrag已经废弃
  if Build.VERSION.SDK_INT >= 24 then
    view.startDragAndDrop(clipData,shadowBuilder,nil,View.DRAG_FLAG_OPAQUE|View.DRAG_FLAG_GLOBAL|View.DRAG_FLAG_GLOBAL_URI_READ|View.DRAG_FLAG_GLOBAL_URI_WRITE)
   else
    view.startDrag(clipData,shadowBuilder,nil,View.DRAG_FLAG_OPAQUE|View.DRAG_FLAG_GLOBAL|View.DRAG_FLAG_GLOBAL_URI_READ|View.DRAG_FLAG_GLOBAL_URI_WRITE)
  end
  return true
end

all_root.onTouch=function(v,e)
  return detector.onTouchEvent(e)
end

WebViewUtils=require "views/WebViewUtils"
function 数据添加(t,回答id)

  设置滑动跟随(t.content)

  local MyWebViewUtils=WebViewUtils(t.content)
  MyWebViewUtils:initSettings()
  :initSettings()
  :initNoImageMode()
  :initDownloadListener()
  :setZhiHuUA()

  MyWebViewUtils:initWebViewClient{
    shouldOverrideUrlLoading=function(view,url)
      if url~=("https://www.zhihu.com/appview/answer/"..回答id.."") then
        检查链接(url)
        return true
      end
    end,
    onPageStarted=function(view,url,favicon)
      t.content.setVisibility(8)
      if t.progress~=nil then
        t.progress.setVisibility(0)
        userinfo.visibility=0
      end

      if 全局主题值=="Night" then
        夜间模式回答页(view)
       else
        初始化背景(view)
      end
      加载js(view,获取js("answer_pages"))
      加载js(view,获取js("imgplus"))
      加载js(view,获取js("mdcopy"))
      加载js(view,获取js("snap"))
    end,
    onPageFinished=function(view,url,favicon)
      t.content.setVisibility(0)
      if t.progress~=nil then
        t.progress.getParent().removeView(t.progress)
        t.progress=nil
      end
      if 全局主题值=="Night" then
        夜间模式回答页(view)
       else
        初始化背景(view)
      end

      if this.getSharedData("eruda") == "true" then
        加载js(view,获取js("eruda"))
      end
      屏蔽元素(view,{".AnswerReward",".AppViewRecommendedReading"})

      task(200,function()
        加载js(view,获取js("answer_code"))
        加载js(view,获取js("scrollRestorer"))
        --添加延迟 防止scrollRestorer未初始化
        task(50,function()
          view.evaluateJavascript("window.scrollRestorer.restoreScrollPosition()",
          {onReceiveValue=function(b)
              task(50,function()
                view.evaluateJavascript(
                "window.scrollRestorerPos",
                {onReceiveValue=function(b)
                    local 保存滑动位置 = tonumber(b) or 0
                    if 保存滑动位置>userinfo.height then
                      appbar.setExpanded(false);
                      dtl.layoutParams.getBehavior().slideDown(dtl);
                      提示("已恢复到上次滑动位置")
                    end
                end})
              end)
          end});
        end)
      end)

      if this.getSharedData("代码块自动换行")=="true" then
        加载js(t.content,'document.querySelectorAll(".ztext pre").forEach(p => { p.style.whiteSpace = "pre-wrap"; p.style.wordWrap = "break-word"; });')
      end

      local function 处理数据逻辑()
        local b = t.data
        if not b then
          task(100, 处理数据逻辑)
          return
        end

        if b.content:find("video%-box") then
          加载js(view,"document.cookie='"..获取Cookie("https://www.zhihu.com/").."'")
          加载js(view,获取js("videoload"))
          if not(getLogin()) then
            提示("该回答含有视频 不登录可能无法显示视频 建议登录")
          end

         elseif b.attachment then
          local 视频链接
          xpcall(function()
            视频链接=b.attachment.video.video_info.playlist.sd.url
            end,function()
            视频链接=b.attachment.video.video_info.playlist.ld.url
            end,function()
            视频链接=b.attachment.video.video_info.playlist.hd.url
          end)
          if 视频链接 then
            加载js(view,'var myvideourl="'..视频链接..'"')
            加载js(view,获取js('videoanswer'))
           else
            AlertDialog.Builder(this)
            .setTitle("提示")
            .setMessage("该回答为视频回答 不登录无法显示视频 如想查看本视频回答中的视频请登录")
            .setCancelable(false)
            .setPositiveButton("我知道了",nil)
            .show()
          end
        end
      end
      处理数据逻辑()

    end,
  }

  MyWebViewUtils:initChromeClient({
    onConsoleMessage=function(consoleMessage)
      --打印控制台信息
      if consoleMessage.message():find("滑动") and activity.getSharedData("回答单页模式")=="true" then return end
      if consoleMessage.message():find("开始滑动") then
        t.content.requestDisallowInterceptTouchEvent(true)
        pg.setUserInputEnabled(false);
       elseif consoleMessage.message():find("结束滑动") then
        t.content.requestDisallowInterceptTouchEvent(false)
        pg.setUserInputEnabled(true);
       elseif consoleMessage.message():find("打印") then
        print(consoleMessage.message())
       elseif consoleMessage.message():find("toast分割") then
        local text=tostring(consoleMessage.message()):match("toast分割(.+)")
        提示(text)
      end
    end,
  })


  t.content.loadUrl("https://www.zhihu.com/appview/answer/"..回答id)
  t.content.setVisibility(0)

end

local function 设置底栏内容(status,iconview,textview,icon)
  if status then
    iconview.setImageBitmap(loadbitmap(图标(icon)))
    textview.setTextColor(转0x(primaryc))
   else
    iconview.setImageBitmap(loadbitmap(图标(icon.."_outline")))
    textview.setTextColor(转0x(stextc))
  end
end

function 初始化页(mviews)

  this.getLuaState().pushObjectValue(thisFragment);
  this.getLuaState().setGlobal("currentFragment");

  if mviews.load==true and mviews.data.author then
    vote_count.Text=(mviews.data.voteup_count)..""
    thanks_count.Text=(mviews.data.thanks_count)..""
    favlists_count.Text=(mviews.data.favlists_count)..""
    comment_count.Text=(mviews.data.comment_count)..""
    comment.onLongClick=function()
      提示(mviews.data.comment_count.."条评论")
      return true
    end
    if mviews.data.author.headline=="" then
      userheadline.Text="Ta还没有签名哦~"
     else
      userheadline.Text=mviews.data.author.headline
    end
    username.Text=mviews.data.author.name
    loadglide(usericon,mviews.data.author.avatar_url)
    local 回答id=mviews.data.id

    设置底栏内容(mviews.data.点赞状态,vote_icon,vote_count,"vote_up")
    设置底栏内容(mviews.data.感谢状态,thanks_icon,thanks_count,"favorite")

  end
end

function 加载页(data,isleftadd)

  if not(data.load) then --判断是否加载过没有
    data.load=true
    local next_id = 回答容器:getNextId(isleftadd)
    数据添加(data.ids, next_id)

    回答容器:getOneData(function(cb,r)--获取1条数据
      if cb==false then
        data.load=nil
        提示("已经没有更多数据了")
        pg.adapter.remove(pos)
        pg.setCurrentItem(pos-1,false)
       else

        data.data={
          voteup_count=cb.voteup_count,
          thanks_count=cb.thanks_count,
          favlists_count=cb.favlists_count,
          comment_count=cb.comment_count,
          id=cb.id,
          author={
            avatar_url=cb.author.avatar_url,
            headline=cb.author.headline,
            name=cb.author.name,
            id=cb.author.id
          },
          点赞状态=cb.relationship.voting==1,
          感谢状态=cb.relationship.is_thanked
        }
        data.ids.data = cb -- 给onPageFinished使用

        if not(已记录) then
          初始化历史记录数据(true)
          保存历史记录(cb.id,cb.question.title,cb.excerpt,"回答")
          已记录=true
        end

        userinfo.onClick=function()
          local pos=pg.getCurrentItem()
          local mview=数据表[pg.adapter.getItem(pos).id]
          local id=mview.data.author.id
          if id~="0" then
            nTView=usericon
            newActivity("people",{id})
           else
            提示("回答作者已设置匿名")
          end
        end

        if cb.author.headline=="" then
          userheadline.Text="Ta还没有签名哦~"
         else
          userheadline.Text=cb.author.headline
        end
        username.Text=cb.author.name
        loadglide(usericon,cb.author.avatar_url)
        初始化页(data)

      end
    end,isleftadd)
  end
end

function 首次设置()
  defer local question_base=answer
  :getinfo(回答id,function(tab)
    all_answer.Text="点击查看全部"..(tab.answer_count).."个回答 >"
    问题id=tab.id
    if tab.answer_count==1 then
      回答容器.isleft=true
    end
    _title.Text=tab.title

  end)
  for i=1,3 do
    pg.setCurrentItem(1,false)--设置正确的列
  end
end

数据表={}

pg.adapter=BaseViewPage2Adapter(this)

function addAnswer(index)
  local ids={}
  local 加入view=loadlayout("layout/answer_list",ids)
  数据表[加入view.id]={
    data={},
    ids=ids
  }
  if index then
    pg.adapter.insert(加入view,index)
   else
    pg.adapter.add(加入view)
  end
end

--首先先加入两个view 防止无法直接左滑
for i=1,2 do
  addAnswer()
end

pg.setCurrentItem(1,false)--设置正确的列

pg.registerOnPageChangeCallback(OnPageChangeCallback{--除了名字变，其他和PageView差不多
  onPageScrolled=function(pos,positionOffset,positionOffsetPixels)
    if positionOffsetPixels==0 then

      dtl.layoutParams.getBehavior().slideUp(dtl)
      --获取当前mviews
      local index=pg.getCurrentItem()
      local mviews=数据表[pg.adapter.getItem(pos).id]

      回答容器:updateLR()
      --判断页面是否在开头or结尾 是否需要添加
      if pg.adapter.getItemCount()==pos+1 then
        if 回答容器.isright then
          pg.setCurrentItem(pos-1,true)
          return 提示("前面没有内容啦")
        end
        --在最右添加 防止无法右滑
        addAnswer()
        加载页(mviews)
        appbar.setExpanded(true);
       elseif pos==0 and pg.adapter.getItemCount()>=0
        if 回答容器.isleft then
          pg.setCurrentItem(1,true)
          return 提示("已经到最左了")
        end
        --在最前面添加fragment 防止无法左滑
        addAnswer(0)
        加载页(mviews,true)
        appbar.setExpanded(true);
        --判断是否加载过
       elseif pg.adapter.getItemCount()>=0 then
        if mviews.load==true then
          回答容器.getid=mviews.data.id
          初始化页(mviews)

        end
      end
    end
  end
})

defer local question_base=answer
:getinfo(回答id,function(tab)
  all_answer.Text="点击查看全部"..(tab.answer_count).."个回答 >"
  问题id=tab.id
  if tab.answer_count==1 then
    回答容器.isleft=true
  end
  _title.Text=tab.title
  all_answer_expand.Text="点击查看全部"..(tab.answer_count).."个回答 >"
  expand_title.text=tab.title
end)



function onDestroy()
  for k,v pairs(数据表) do
    v.ids.content.destroy()
    System.gc()
  end
end

voteup.onClick=function()
  local pos=pg.getCurrentItem()
  local mview=数据表[pg.adapter.getItem(pos).id]
  local 回答id=mview.data.id
  if 回答id==nil then
    return 提示("加载中")
  end
  if not mview.data.点赞状态 then
    zHttp.post("https://api.zhihu.com/answers/"..回答id.."/voters",'{"type":"up"}',posthead,function(code,content)
      if code==200 then
        提示("点赞成功")
        mview.data.点赞状态=true
        local data=luajson.decode(content)
        vote_count.text=tostring(mview.data.voteup_count+1)
        vote_icon.setImageBitmap(loadbitmap(图标("vote_up")))
        vote_count.setTextColor(转0x(primaryc))
       elseif code==401 then
        提示("请登录后使用本功能")
      end
    end)
   else
    zHttp.post("https://api.zhihu.com/answers/"..回答id.."/voters",'{"type":"neutral"}',posthead,function(code,content)
      if code==200 then
        提示("取消点赞成功")
        mview.data.点赞状态=false
        local data=luajson.decode(content)
        vote_count.text=tostring(mview.data.voteup_count)
        vote_icon.setImageBitmap(loadbitmap(图标("vote_up_outline")))
        vote_count.setTextColor(转0x(stextc))
       elseif code==401 then
        提示("请登录后使用本功能")
      end
    end)
  end
end

thank.onClick=function()
  local pos=pg.getCurrentItem()
  local mview=数据表[pg.adapter.getItem(pos).id]
  local 回答id=mview.data.id
  if 回答id==nil then
    return 提示("加载中")
  end
  if not mview.data.感谢状态 then
    zHttp.post("https://www.zhihu.com/api/v4/zreaction",'{"content_type":"answers","content_id":"'..回答id..'","action_type":"emojis","action_value":"red_heart"}',posthead,function(code,content)
      if code==200 then
        提示("表达感谢成功")
        mview.data.感谢状态=true
        local data=luajson.decode(content)
        thanks_count.text=tostring(mview.data.thanks_count+1)
        thanks_icon.setImageBitmap(loadbitmap(图标("favorite")))
        thanks_count.setTextColor(转0x(primaryc))
       elseif code==401 then
        提示("请登录后使用本功能")
      end
    end)
   else
    zHttp.delete("https://www.zhihu.com/api/v4/zreaction?content_type=answers&content_id="..回答id.."&action_type=emojis&action_value=",posthead,function(code,content)
      if code==200 then
        提示("取消感谢成功")
        mview.data.感谢状态=false
        local data=luajson.decode(content)
        thanks_count.text=tostring(mview.data.thanks_count)
        thanks_icon.setImageBitmap(loadbitmap(图标("favorite_outline")))
        thanks_count.setTextColor(转0x(stextc))
       elseif code==401 then
        提示("请登录后使用本功能")
      end
    end)
  end
end


mark.onClick=function()
  local url=数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content.getUrl()
  加入收藏夹(url:match("answer/(.+)"),"answer")
end

mark.onLongClick=function()
  local url=数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content.getUrl()
  加入默认收藏夹(url:match("answer/(.+)"),"answer")
  return true
end

function onKeyDown(code,event)
  if this.getSharedData("音量键选择tab")~="true" or 全屏模式==true then
    return false
  end
  if code==KeyEvent.KEYCODE_VOLUME_UP then
    return true;
   elseif code== KeyEvent.KEYCODE_VOLUME_DOWN then
    return true;
  end

end

function onKeyUp(code,event)
  if this.getSharedData("音量键选择tab")~="true" or 全屏模式==true then
    return false
  end
  --上键上一页 下键下一页
  if code==KeyEvent.KEYCODE_VOLUME_UP then
    pg.setCurrentItem(pg.getCurrentItem()-1)
    return true;
   elseif code== KeyEvent.KEYCODE_VOLUME_DOWN then
    pg.setCurrentItem(pg.getCurrentItem()+1)
    return true;
  end
end

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
        src=图标("refresh"),text="刷新",onClick=function()

          数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content.reload()

          提示("刷新中")
        end
      },

      {
        src=图标("share"),text="分享",onClick=function()
          local url=数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content.getUrl()
          if url==nil then
            提示("加载中")
            return
          end
          local format="【回答】【%s】%s: %s"
          分享文本(string.format(format,_title.Text,username.Text,"https://www.zhihu.com/question/"..问题id.."/answer/"..url:match("answer/(.+)")))
        end,
        onLongClick=function()
          local url=数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content.getUrl()
          if url==nil then
            提示("加载中")
            return
          end
          local format="【回答】【%s】%s: %s"
          分享文本(string.format(format,_title.Text,username.Text,"https://www.zhihu.com/question/"..问题id.."/answer/"..url:match("answer/(.+)")),true)
        end
      },

      {
        src=图标("share"),text="以图片形式保存",onClick=function()
          local url=数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content.getUrl()
          local webView=数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content
          if url==nil then
            提示("加载中")
            return
          end
          local format="【回答】【%s】%s: %s"
          --分享文本(string.format(format,_title.Text,username.Text,"https://www.zhihu.com/question/"..问题id.."/answer/"..url:match("answer/(.+)")))
          import "android.graphics.Bitmap"
          import "android.graphics.Canvas"
          import "android.graphics.Paint"
          import "com.nwdxlgzs.view.photoview.PhotoView"


          function webviewToBitmap(webView, func) --由于存在延迟，后续操作使用function(bitmap)传入
            webView.evaluateJavascript("captureScreenshot()",
            {onReceiveValue=function(b)
                --偷懒 因为onReceiveValue回调不能直接处理异步
                --应该使用js接口的 不过1秒似乎应该可以处理吧(
                local process
                process=function()
                  webView.evaluateJavascript(
                  "getScreenshot()",
                  {onReceiveValue=function(b)
                      if string.find(b,"process")~=nil
                        task(200,process)

                       else
                        func(base64ToBitmap(b))
                      end
                  end})
                end
                task(300,process)
            end});
          end
          webviewToBitmap(webView, function(bitmap)
            local ids={}
            AlertDialog.Builder(this)
            .setTitle("预览")
            .setView(loadlayout(
            {
              LinearLayout;
              layout_width="-1";
              layout_height="-1";
              {
                PhotoView;
                id="iv";
                layout_width="fill";
                layout_height="wrap";
                adjustViewBounds="true";
              }
            },ids))
            .setPositiveButton("确认并分享", function()
              import "android.graphics.Bitmap"
              import "android.os.Environment"
              import "java.io.File"
              import "java.io.FileOutputStream"
              import "java.lang.System"
              import "android.content.FileProvider"
              local dir=this.getExternalFilesDir(Environment.DIRECTORY_PICTURES).toString()..""
              local file=File(dir,"知乎回答-".._title.Text.."-来自-"..username.Text..".jpg")
              fos = FileOutputStream(file);
              bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fos);
              fos.flush();
              fos.close();
              local sendIntent = Intent()
              .setAction(Intent.ACTION_SEND)
              .putExtra(Intent.EXTRA_STREAM, FileProvider.getUriForFile(this, this.getPackageName()..".FileProvider", file))
              .setData(FileProvider.getUriForFile(this, this.getPackageName()..".FileProvider", file))
              .setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
              --.putExtra(Intent.EXTRA_STREAM, file.toURI())
              .putExtra(Intent.EXTRA_TEXT, string.format(format,_title.Text,username.Text,"https://www.zhihu.com/question/"..问题id.."/answer/"..url:match("answer/(.+)")))
              .setType("image/*");

              shareIntent = Intent.createChooser(sendIntent, nil);
              this.startActivity(shareIntent);
            end)
            .setNegativeButton("取消", nil)
            .setOnDismissListener({
              onDismiss = function()
                webView.scrollBy(0, 1) --弹出窗口后返回可能导致webview无法滑动，这样可以重置一下
            end})
            .show()

            loadglide(ids.iv,bitmap)

          end)



        end,
      },

      {
        src=图标("chat_bubble"),text="查看评论",onClick=function()

          local pos=pg.getCurrentItem()
          local mview=数据表[pg.adapter.getItem(pos).id]
          local 回答id=mview.data.id
          if 回答id==nil then
            return 提示("加载中")
          end

          local 保存路径=内置存储文件("Download/".._title.Text.."/"..username.Text)
          newActivity("comment",{回答id,"answers",保存路径})

        end
      },
      {
        src=图标("get_app"),text="保存到本地",onClick=function()

          local result=get_write_permissions()
          if result~=true then
            return false
          end

          local pgnum=pg.adapter.getItem(pg.getCurrentItem()).id
          local pgids=数据表[pgnum].ids

          local 保存路径=内置存储文件("Download/".._title.Text.."/"..username.Text)
          写入内容='question_id="'..问题id..'"\n'
          写入内容=写入内容..'answer_id="'..回答id..'"\n'
          写入内容=写入内容..'thanks_count="'..thanks_count.Text..'"\n'
          写入内容=写入内容..'vote_count="'..vote_count.Text..'"\n'
          写入内容=写入内容..'favlists_count="'..favlists_count.Text..'"\n'
          写入内容=写入内容..'comment_count="'..comment_count.Text..'"\n'
          写入内容=写入内容..'author="'..username.Text..'"\n'
          写入内容=写入内容..'headline="'..userheadline.Text..'"\n'
          写入文件(保存路径.."/detail.txt",写入内容)
          newActivity("saveweb",{pgids.content.getUrl(),保存路径,写入内容})
        end,


        onLongClick=function()
          local pgnum=pg.adapter.getItem(pg.getCurrentItem()).id
          local pgids=数据表[pgnum].ids
          local content=pgids.content

          content.evaluateJavascript('getmd()',{onReceiveValue=function(b)
              提示("请选择一个保存位置")
              saf_writeText=b
              createDocumentLauncher.launch(_title.Text.."_"..username.Text..".md");
          end})



        end
      },

      {
        src=图标("book"),text="加入收藏夹",onClick=function()
          local url=数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content.getUrl()
          加入收藏夹(url:match("answer/(.+)"),"answer")
        end,
        onLongClick=function()
          local url=数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content.getUrl()
          加入默认收藏夹(url:match("answer/(.+)"),"answer")
        end
      },

      {
        src=图标("book"),text="举报",onClick=function()

          local pos=pg.getCurrentItem()
          local mview=数据表[pg.adapter.getItem(pos).id]
          local 回答id=mview.data.id
          if 回答id==nil then
            return 提示("加载中")
          end

          local url="https://www.zhihu.com/report?id="..回答id.."&type=answer"
          newActivity("browser",{url.."&source=android&ab_signature=","举报"})
        end
      },

      {
        src=图标("search"),text="在网页查找内容",onClick=function()
          local content=数据表[pg.adapter.getItem(pg.getCurrentItem()).id].ids.content
          webview查找文字(content)
        end
      },

    }
  })
end)

if activity.getSharedData("回答提示0.04")==nil
  AlertDialog.Builder(this)
  .setTitle("小提示")
  .setCancelable(false)
  .setMessage("你可双击标题回到顶部")
  .setPositiveButton("我知道了",{onClick=function() activity.setSharedData("回答提示0.04","true") end})
  .show()
end


if this.getSharedData("显示虚拟滑动按键")=="true" then
  bottom_parent.Visibility=0
  up_button.onClick=function()
    local pos=pg.getCurrentItem()
    local mview=数据表[pg.adapter.getItem(pos).id]
    local id表=mview.ids
    local content=id表.content
    content.scrollBy(0, -content.height+dp2px(40));
    if content.getScrollY()<=0 then
      appbar.setExpanded(true,false);
    end
  end
  down_button.onClick=function()
    local pos=pg.getCurrentItem()
    local mview=数据表[pg.adapter.getItem(pos).id]
    local id表=mview.ids
    local content=id表.content
    content.scrollBy(0, (content.height-dp2px(40)));
    appbar.setExpanded(false,false);
  end
end
