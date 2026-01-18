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

问题id, 回答id = ...

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
all_root.alpha = 0
import "model.answer"

回答容器=answer:new(回答id)

local dtl_translation = 0
local currentWebView
local function getDtlMaxTranslation()
  local h = dtl.height
  if h == 0 then h = dp2px(56) end
  return h + dp2px(32)
end

local function setDtlTranslation(trans, animate)
  dtl_translation = trans
  if animate then
    dtl.animate().translationY(trans).setDuration(200).start()
   else
    dtl.setTranslationY(trans)
  end
end

local last_verticalOffset = 0
local is_dragging = false


function onPause()
  mainLay.setLayerType(View.LAYER_TYPE_SOFTWARE,nil)
end
function onResume()
  local current_pos = pg.getCurrentItem()
  local item = pg.adapter.getItem(current_pos)
  if item and 数据表[item.id] then
    数据表[item.id].ids.content.resumeTimers()
  end
  mainLay.setLayerType(View.LAYER_TYPE_NONE,nil)
end

local function 统一滑动跟随(view,x,y,lx,ly)
  if view ~= currentWebView then return end
  
  -- 1. 计算 Header 的滚动范围 (即 UserInfo 部分的高度)
  -- 注意：这里假设 all_root_expand 是我们需要隐藏的部分
  local header_height = all_root_expand.getHeight()
  if header_height == 0 then header_height = dp2px(100) end -- Fallback
  
  -- 2. 计算当前应该偏移的距离
  -- 我们希望 appbar 随 scrollY 向上移动，不再限制最大距离，使其随正文一直滚动
  local scroll_y = view.getScrollY()
  local translation = -scroll_y
  
  -- 3. 执行偏移
  -- appbar 整体上移
  appbar.setTranslationY(translation)
  -- toolbar 反向移动以保持固定 (Pin effect)
  root_card.setTranslationY(-translation)
  
  -- 4. 处理透明度渐变
  local progress = math.min(1, math.abs(translation) / header_height)
  all_root.setAlpha(progress) -- 标题栏渐显
  all_root_expand.setAlpha(1 - progress) -- 用户信息渐隐 (可选)
  
  -- 5. 底栏 (dtl) 逻辑 (保留原有逻辑)
  local dy = y - ly
  if math.abs(dy) > 300 then return end
  local max_dtl_trans = getDtlMaxTranslation()
  dtl_translation = math.max(0, math.min(max_dtl_trans, dtl_translation + dy))
  dtl.setTranslationY(dtl_translation)
end

comment.onClick=function()
  local pos=pg.getCurrentItem()
  local item = pg.adapter.getItem(pos)
  local mview = 数据表[item.id]
  local 回答id = mview and mview.data.id
  if 回答id==nil then
    return 提示("加载中")
  end
  local 保存路径=内置存储文件("Download/".._title.Text.."/"..username.Text)
  ViewCompat.setTransitionName(comment,"t")
  nTView=comment_card
  newActivity("comment",{回答id,"answers",保存路径})
end;

local function 执行加载JS(view)
  if 全局主题值=="Night" then
    夜间模式回答页(view)
   else
    初始化背景(view)
  end
  local js_list = {"answer_pages", "imgplus", "mdcopy", "snap"}
  for _, v in ipairs(js_list) do
    加载js(view, 获取js(v))
  end
end

local function 处理视频逻辑(t, b)
  local view = t.content
  if b.content:find("video%-box") then
    加载js(view,"document.cookie='"..获取Cookie("https://www.zhihu.com/")..'"')
    加载js(view,获取js("videoload"))
    if not(getLogin()) then
      提示("该回答含有视频 不登录可能无法显示视频 建议登录")
    end
   elseif b.attachment and b.attachment.video then
    local playlist = b.attachment.video.video_info.playlist
    local 视频链接 = playlist.sd and playlist.sd.url or playlist.ld and playlist.ld.url or playlist.hd and playlist.hd.url
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

local last_appbar_height = 0
appbar.getViewTreeObserver().addOnGlobalLayoutListener(ViewTreeObserver.OnGlobalLayoutListener{
  onGlobalLayout=function()
    local height_px = appbar.getHeight()
    if height_px > 0 and height_px ~= last_appbar_height and currentWebView then
      last_appbar_height = height_px
      local density = activity.getResources().getDisplayMetrics().density
      local height_dp = height_px / density
      -- Update padding with reduced gap (20dp) to match content
      currentWebView.evaluateJavascript("document.body.style.paddingTop = '"..(height_dp - 20).."px'", nil)
    end
  end
})

function 数据添加(t,回答id)
  t.content.onScrollChange = 统一滑动跟随

  local MyWebViewUtils=require("views/WebViewUtils")(t.content)
  MyWebViewUtils:initSettings():initNoImageMode():initDownloadListener():setZhiHuUA()

  MyWebViewUtils:initWebViewClient{
    shouldOverrideUrlLoading=function(view,url)
      if url~=("https://www.zhihu.com/appview/answer/"..回答id.."") then
        检查链接(url)
        return true
      end
    end,
    onPageStarted=function(view,url,favicon)
      t.content.setVisibility(8)
      userinfo.visibility=0
      -- 延迟显示加载动画，避免快速切换时的闪烁
      task(200, function()
        if t.progress and t.content.getVisibility() == 8 then
          t.progress.setVisibility(0)
        end
      end)
      执行加载JS(view)
    end,
    onPageFinished=function(view,url,favicon)
      t.content.setVisibility(0)
      if t.progress then
        t.progress.getParent().removeView(t.progress)
        t.progress=nil
      end
      
      -- 注入 Padding-Top 撑开网页
      view.post(function()
        local height_px = appbar.getHeight()
        if height_px > 0 then
          local density = activity.getResources().getDisplayMetrics().density
          local height_dp = height_px / density
          view.evaluateJavascript("document.body.style.paddingTop = '"..(height_dp - 20).."px'", nil)
        end
      end)

      if 全局主题值=="Night" then 夜间模式回答页(view) else 初始化背景(view) end
      if this.getSharedData("eruda") == "true" then 加载js(view,获取js("eruda")) end
      屏蔽元素(view,{'.AnswerReward','.AppViewRecommendedReading'})

      task(200,function()
        加载js(view,获取js("answer_code"))
        加载js(view,获取js("scrollRestorer"))
        -- 合并延时任务，减少嵌套层级
        task(100, function()
          view.evaluateJavascript("window.scrollRestorer.restoreScrollPosition()", {onReceiveValue=function(b)
            view.evaluateJavascript("window.scrollRestorerPos", {onReceiveValue=function(pos_val)
              local 保存滑动位置 = tonumber(pos_val) or 0
              if 保存滑动位置 > userinfo.height then
                setDtlTranslation(getDtlMaxTranslation())
                提示("已恢复到上次滑动位置")
              end
            end})
          end})
        end)
      end)

      if this.getSharedData("代码块自动换行")=="true" then
        加载js(t.content,'document.querySelectorAll(".ztext pre").forEach(p => { p.style.whiteSpace = "pre-wrap"; p.style.wordWrap = "break-word"; });')
      end

      -- 扁平化数据逻辑处理
      task(100, function()
        if t.data then 处理视频逻辑(t, t.data) end
      end)
    end,
  }

  MyWebViewUtils:initChromeClient({
    onConsoleMessage=function(consoleMessage)
      local msg = consoleMessage.message()
      if msg:find("滑动") and activity.getSharedData("回答单页模式")=="true" then return end
      if msg:find("开始滑动") then
        t.content.requestDisallowInterceptTouchEvent(true)
        pg.setUserInputEnabled(false)
       elseif msg:find("结束滑动") then
        t.content.requestDisallowInterceptTouchEvent(false)
        pg.setUserInputEnabled(true)
       elseif msg:find("打印") then
        print(msg)
       elseif msg:find("toast分割") then
        提示(msg:match("toast分割(.+)"))
      end
    end,
  })

  t.content.loadUrl("https://www.zhihu.com/appview/answer/"..回答id)
  t.content.setVisibility(0)
end

local function 更新底栏(data)
  local function 设置状态(status, iconview, textview, icon, count)
    if status then
      iconview.setImageBitmap(loadbitmap(图标(icon)))
      textview.setTextColor(转0x(primaryc))
     else
      iconview.setImageBitmap(loadbitmap(图标(icon.."_outline")))
      textview.setTextColor(转0x(stextc))
    end
    textview.Text = tostring(count)
  end

  设置状态(data.点赞状态, vote_icon, vote_count, "vote_up", data.voteup_count)
  设置状态(data.感谢状态, thanks_icon, thanks_count, "favorite", data.thanks_count)
  favlists_count.Text = tostring(data.favlists_count)
  comment_count.Text = tostring(data.comment_count)
end

function 初始化页(mviews)
  this.getLuaState().pushObjectValue(thisFragment)
  this.getLuaState().setGlobal("currentFragment")

  local data = mviews.data
  if mviews.load and data and data.author then
    username.Text = data.author.name
    userheadline.Text = (data.author.headline == "" and "Ta还没有签名哦~" or data.author.headline)
    loadglide(usericon, data.author.avatar_url)
    更新底栏(data)

    comment.onLongClick = function()
      提示(data.comment_count.."条评论")
      return true
    end
  end
end

function 加载页(data, isleftadd, pos)
  if data.load then return end
  data.load = "loading"

  local target_id = 回答容器:getOneData(function(cb)
    if cb == false then
      data.load = nil
      提示("已经没有更多数据了")
      if pos then
        pg.adapter.remove(pos)
        pg.setCurrentItem(pos - 1, false)
      end
      return
    end

    data.data = {
      voteup_count = cb.voteup_count,
      thanks_count = cb.thanks_count,
      favlists_count = cb.favlists_count,
      comment_count = cb.comment_count,
      id = tostring(cb.id),
      author = {
        avatar_url = cb.author.avatar_url,
        headline = cb.author.headline,
        name = cb.author.name,
        id = tostring(cb.author.id)
      },
      点赞状态 = (cb.relationship.voting == 1),
      感谢状态 = cb.relationship.is_thanked
    }
    data.ids.data = cb

    if not 已记录 then
      初始化历史记录数据(true)
      保存历史记录(cb.id, cb.question.title, cb.excerpt, "回答")
      已记录 = true
    end

    userinfo.onClick = function()
      local current_pos = pg.getCurrentItem()
      local item = pg.adapter.getItem(current_pos)
      local mview = 数据表[item.id]
      if mview and mview.data and mview.data.author then
        local author_id = mview.data.author.id
        if author_id ~= "0" then
          nTView = usericon
          newActivity("people", {author_id})
         else
          提示("回答作者已设置匿名")
        end
      end
    end

    data.load = true
    初始化页(data)
  end, isleftadd)

  数据添加(data.ids, tostring(target_id))
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
    pg.adapter.insert(加入view,pg.adapter.getItemCount())
  end
end

--首先先加入两个view 防止无法直接左滑
for i=1,2 do
  addAnswer()
end

pg.registerOnPageChangeCallback(OnPageChangeCallback{
  onPageSelected=function(pos)
    local item = pg.adapter.getItem(pos)
    local mviews = 数据表[item.id]
    if not mviews then return end
    
    currentWebView = mviews.ids.content
    setDtlTranslation(0, true)
    if 回答容器 then 回答容器:updateLR() end
    
    -- 同步 AppBar 状态与当前 WebView 的滚动位置
    local scroll_y = currentWebView.getScrollY()
    local translation = -scroll_y
    appbar.setTranslationY(translation)
    root_card.setTranslationY(-translation)
    
    local header_height = all_root_expand.getHeight()
    if header_height == 0 then header_height = dp2px(100) end
    local progress = math.min(1, math.abs(translation) / header_height)
    all_root.setAlpha(progress)
    all_root_expand.setAlpha(1 - progress)
    
    if pg.adapter.getItemCount()==pos+1 then
      if 回答容器 and not 回答容器.isright then
        addAnswer()
        加载页(mviews, false, pos)
      end
     elseif pos==0 then
      if 回答容器 and not 回答容器.isleft then
        addAnswer(0)
        加载页(mviews, true, pos)
      end
     else
      if mviews.load == true then
        if 回答容器 then 回答容器.getid = mviews.data.id end
        初始化页(mviews)
      end
    end
  end,
  onPageScrolled=function(pos,positionOffset,positionOffsetPixels)
    if positionOffsetPixels==0 then
      if 回答容器 then 回答容器:updateLR() end
      if pg.adapter.getItemCount()==pos+1 then
        if 回答容器 and 回答容器.isright then
          pg.setCurrentItem(pos-1,true)
          return 提示("前面没有内容啦")
        end
       elseif pos==0 then
        if 回答容器 and 回答容器.isleft then
          pg.setCurrentItem(1,true)
          return 提示("已经到最左了")
        end
      end
    end
  end
})

pg.setCurrentItem(1,false)
local item = pg.adapter.getItem(pg.getCurrentItem())
local current_mviews = 数据表[item.id]
if current_mviews then
  currentWebView = current_mviews.ids.content
  if not current_mviews.load then
    加载页(current_mviews, false, pg.getCurrentItem())
  end
end

answer:getinfo(回答id, function(tab)
  local info_text = "点击查看全部" .. tab.answer_count .. "个回答 >"
  all_answer.Text = info_text
  all_answer_expand.Text = info_text
  问题id = tab.id
  _title.Text = tab.title
  expand_title.Text = tab.title
  if tab.answer_count == 1 and 回答容器 then
    回答容器.isleft = true
  end
  
  local function openQuestion()
    if 问题id==nil or 问题id=="null" then
      return 提示("加载中")
    end
    newActivity("question",{问题id})
  end
  
  all_root.onClick = openQuestion
  all_root_expand.onClick = openQuestion
  all_answer_expand.onClick = openQuestion
end)



function onDestroy()
  for k,v in pairs(数据表) do
    v.ids.content.destroy()
    System.gc()
  end
end

voteup.onClick=function()
  local pos=pg.getCurrentItem()
  local item = pg.adapter.getItem(pos)
  local mview = 数据表[item.id]
  local data = mview and mview.data
  if not data or not data.id then
    return 提示("加载中")
  end
  local 回答id=data.id
  if not data.点赞状态 then
    zHttp.post("https://api.zhihu.com/answers/"..回答id.."/voters",'{"type":"up"}',posthead,function(code,content)
      if code==200 then
        提示("点赞成功")
        data.点赞状态=true
        data.voteup_count = data.voteup_count + 1
        更新底栏(data)
       elseif code==401 then
        提示("请登录后使用本功能")
      end
    end)
   else
    zHttp.post("https://api.zhihu.com/answers/"..回答id.."/voters",'{"type":"neutral"}',posthead,function(code,content)
      if code==200 then
        提示("取消点赞成功")
        data.点赞状态=false
        data.voteup_count = data.voteup_count - 1
        更新底栏(data)
       elseif code==401 then
        提示("请登录后使用本功能")
      end
    end)
  end
end

thank.onClick=function()
  local pos=pg.getCurrentItem()
  local item = pg.adapter.getItem(pos)
  local mview = 数据表[item.id]
  local data = mview and mview.data
  if not data or not data.id then
    return 提示("加载中")
  end
  local 回答id=data.id
  if not data.感谢状态 then
    zHttp.post("https://www.zhihu.com/api/v4/zreaction",'{"content_type":"answers","content_id":"'..回答id..'","action_type":"emojis","action_value":"red_heart"}',posthead,function(code,content)
      if code==200 then
        提示("表达感谢成功")
        data.感谢状态=true
        data.thanks_count = data.thanks_count + 1
        更新底栏(data)
       elseif code==401 then
        提示("请登录后使用本功能")
      end
    end)
   else
    zHttp.delete("https://www.zhihu.com/api/v4/zreaction?content_type=answers&content_id="..回答id.."&action_type=emojis&action_value=",posthead,function(code,content)
      if code==200 then
        提示("取消感谢成功")
        data.感谢状态=false
        data.thanks_count = data.thanks_count - 1
        更新底栏(data)
       elseif code==401 then
        提示("请登录后使用本功能")
      end
    end)
  end
end


mark.onClick=function()
  local item = pg.adapter.getItem(pg.getCurrentItem())
  local url = 数据表[item.id].ids.content.getUrl()
  加入收藏夹(url:match("answer/(.+)"),"answer")
end

mark.onLongClick=function()
  local item = pg.adapter.getItem(pg.getCurrentItem())
  local url = 数据表[item.id].ids.content.getUrl()
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
  local function 获取当前WebView()
    local item = pg.adapter.getItem(pg.getCurrentItem())
    return 数据表[item.id].ids.content
  end

  local function 获取当前回答URL()
    local content = 获取当前WebView()
    local url = content.getUrl()
    if url == nil then 提示("加载中") return nil end
    return url
  end

  local function 获取分享文本(url)
    local format = "【回答】【%s】%s: %s"
    local answer_id = url:match("answer/(.+)")
    return string.format(format, _title.Text, username.Text, "https://www.zhihu.com/question/"..问题id.."/answer/"..answer_id)
  end

  a=MUKPopu({
    tittle="回答",
    list={
      {
        src=图标("refresh"),text="刷新",onClick=function()
          获取当前WebView().reload()
          提示("刷新中")
        end
      },
      {
        src=图标("share"),text="分享",onClick=function()
          local url = 获取当前回答URL()
          if url then 分享文本(获取分享文本(url)) end
        end,
        onLongClick=function()
          local url = 获取当前回答URL()
          if url then 分享文本(获取分享文本(url), true) end
        end
      },
      {
        src=图标("share"),text="以图片形式保存",onClick=function()
          local url = 获取当前回答URL()
          if not url then return end
          local webView = 获取当前WebView()
          import "android.graphics.Bitmap"
          import "android.graphics.Canvas"
          import "android.graphics.Paint"
          import "com.nwdxlgzs.view.photoview.PhotoView"

          function webviewToBitmap(webView, func)
            webView.evaluateJavascript("captureScreenshot()", {onReceiveValue=function(b)
                local process
                process=function()
                  webView.evaluateJavascript("getScreenshot()", {onReceiveValue=function(b)
                      if b:find("process") then
                        task(200, process)
                       else
                        func(base64ToBitmap(b))
                      end
                  end})
                end
                task(300, process)
            end})
          end

          webviewToBitmap(webView, function(bitmap)
            local ids={}
            AlertDialog.Builder(this)
            .setTitle("预览")
            .setView(loadlayout({
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
              import "android.os.Environment"
              import "java.io.File"
              import "java.io.FileOutputStream"
              import "androidx.core.content.FileProvider"
              local dir = this.getExternalFilesDir(Environment.DIRECTORY_PICTURES).toString()
              local file = File(dir, "知乎回答-".._title.Text.."-来自-"..username.Text..".jpg")
              local fos = FileOutputStream(file)
              bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fos)
              fos.flush()
              fos.close()
              local uri = FileProvider.getUriForFile(this, this.getPackageName()..".FileProvider", file)
              local sendIntent = Intent()
              .setAction(Intent.ACTION_SEND)
              .putExtra(Intent.EXTRA_STREAM, uri)
              .setData(uri)
              .setFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
              .putExtra(Intent.EXTRA_TEXT, 获取分享文本(url))
              .setType("image/*")
              this.startActivity(Intent.createChooser(sendIntent, nil))
            end)
            .setNegativeButton("取消", nil)
            .setOnDismissListener({onDismiss=function() webView.scrollBy(0, 1) end})
            .show()
            loadglide(ids.iv, bitmap)
          end)
        end,
      },
      {
        src=图标("chat_bubble"),text="查看评论",onClick=function()
          local pos = pg.getCurrentItem()
          local item = pg.adapter.getItem(pos)
          local mview = 数据表[item.id]
          local 回答id = mview and mview.data.id
          if not 回答id then return 提示("加载中") end
          local 保存路径 = 内置存储文件("Download/".._title.Text.."/"..username.Text)
          newActivity("comment", {回答id, "answers", 保存路径})
        end
      },
      {
        src=图标("get_app"),text="保存到本地",onClick=function()
          if not get_write_permissions() then return end
          local item = pg.adapter.getItem(pg.getCurrentItem())
          local pgids = 数据表[item.id].ids
          local 保存路径 = 内置存储文件("Download/".._title.Text.."/"..username.Text)
          local detail = string.format('question_id="%s"\nanswer_id="%s"\nthanks_count="%s"\nvote_count="%s"\nfavlists_count="%s"\ncomment_count="%s"\nauthor="%s"\nheadline="%s"\n', 
            问题id, 回答id, thanks_count.Text, vote_count.Text, favlists_count.Text, comment_count.Text, username.Text, userheadline.Text)
          写入文件(保存路径.."/detail.txt", detail)
          newActivity("saveweb", {pgids.content.getUrl(), 保存路径, detail})
        end,
        onLongClick=function()
          local content = 获取当前WebView()
          content.evaluateJavascript('getmd()', {onReceiveValue=function(b)
              提示("请选择一个保存位置")
              saf_writeText = b
              createDocumentLauncher.launch(_title.Text.."_"..username.Text..".md")
          end})
        end
      },
      {
        src=图标("book"),text="加入收藏夹",onClick=function()
          local url = 获取当前回答URL()
          if url then 加入收藏夹(url:match("answer/(.+)"), "answer") end
        end,
        onLongClick=function()
          local url = 获取当前回答URL()
          if url then 加入默认收藏夹(url:match("answer/(.+)"), "answer") end
        end
      },
      {
        src=图标("book"),text="举报",onClick=function()
          local pos = pg.getCurrentItem()
          local item = pg.adapter.getItem(pos)
          local mview = 数据表[item.id]
          local 回答id = mview and mview.data.id
          if not 回答id then return 提示("加载中") end
          local url = "https://www.zhihu.com/report?id="..回答id.."&type=answer"
          newActivity("browser", {url.."&source=android&ab_signature=", "举报"})
        end
      },
      {
        src=图标("search"),text="在网页查找内容",onClick=function()
          webview查找文字(获取当前WebView())
        end
      },
    }
  })
end)

if activity.getSharedData("回答提示0.04")==nil then
  AlertDialog.Builder(this)
  .setTitle("小提示")
  .setCancelable(false)
  .setMessage("你可双击标题回到顶部")
  .setPositiveButton("我知道了", {onClick=function() activity.setSharedData("回答提示0.04","true") end})
  .show()
end

if this.getSharedData("显示虚拟滑动按键")=="true" then
  bottom_parent.Visibility=0
  local function 滑动(direction)
    local item = pg.adapter.getItem(pg.getCurrentItem())
    local mview = 数据表[item.id]
    local content = mview.ids.content
    local offset = (direction == "up" and -1 or 1) * (content.height - dp2px(40))
    content.scrollBy(0, offset)
  end
  up_button.onClick = function() 滑动("up") end
  down_button.onClick = function() 滑动("down") end
end
