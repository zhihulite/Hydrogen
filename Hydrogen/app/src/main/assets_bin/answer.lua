require "import"
import "mods.muk"
import "com.lua.*"
import "android.view.*"
import "androidx.viewpager2.widget.ViewPager2"
import "com.google.android.material.appbar.AppBarLayout"
import "com.dingyi.adapter.BaseViewPage2Adapter"
import "com.bumptech.glide.Glide"
import "androidx.core.view.ViewCompat"
import "androidx.activity.result.ActivityResultCallback"
import "androidx.activity.result.contract.ActivityResultContracts"

-- 常用JNI类缓存
local LinkMovementMethod = luajava.bindClass "android.text.method.LinkMovementMethod"
local Html = luajava.bindClass "android.text.Html"
local OnPageChangeCallback = luajava.bindClass "androidx.viewpager2.widget.ViewPager2$OnPageChangeCallback"
local ColorDrawable = luajava.bindClass "android.graphics.drawable.ColorDrawable"
local Paint = luajava.bindClass "android.graphics.Paint"
local Path = luajava.bindClass "android.graphics.Path"
local ArgbEvaluator = luajava.bindClass "android.animation.ArgbEvaluator"
local AppBarLayoutBehavior = luajava.bindClass "com.hydrogen.AppBarLayoutBehavior"

local last_toast_time = 0

-- 初始化参数
问题id, 回答id, pre_data = ...

-- 核心优化：在布局渲染前立即设置窗口背景色，防止 Activity 启动瞬间白屏
activity.getWindow().setBackgroundDrawable(ColorDrawable(backgroundc_int))

设置视图("layout/answer")

-- 优化：ViewPager2 容器也需要背景色
pg.setBackgroundColor(backgroundc_int)

-- 性能优化：全局缓存反射字段，避免重复反射
if not _G.cached_viewpager2_fields then
  _G.cached_viewpager2_fields = {
    recyclerViewField = ViewPager2.getDeclaredField("mRecyclerView"),
    touchSlopField = luajava.bindClass("androidx.recyclerview.widget.RecyclerView").getDeclaredField("mTouchSlop")
  }
  _G.cached_viewpager2_fields.recyclerViewField.setAccessible(true)
  _G.cached_viewpager2_fields.touchSlopField.setAccessible(true)
end

local pg_recyclerView = _G.cached_viewpager2_fields.recyclerViewField.get(pg)
local touchSlop = _G.cached_viewpager2_fields.touchSlopField.get(pg_recyclerView)
_G.cached_viewpager2_fields.touchSlopField.set(pg_recyclerView, int(touchSlop * tonumber(activity.getSharedData("scroll_sense"))))

-- 改革 1：增加离屏预加载数量，确保前后至少有两页在内存中备战
pg.setOffscreenPageLimit(2)

-- 优化：将预加载逻辑移到设置视图之后，取消 task(1) 延迟，实现瞬间渲染
if type(pre_data) == "table" then
  -- 更新底栏计数
  vote_count.Text = tostring(pre_data.voteup_count or vote_count.Text)
  comment_count.Text = tostring(pre_data.comment_count or comment_count.Text)
end

edgeToedge(nil,nil,function()
  root_card.setPadding(0,状态栏高度,0,0)
  title_bar_expand.layoutParams= title_bar_expand.layoutParams.setMargins(0,状态栏高度+dp2px(64,true),0,0)
  local safeStatus=safeStatusView.layoutParams
  safeStatus.height=状态栏高度
  safeStatusView.setLayoutParams(safeStatus)
  safeStatusView.setBackgroundColor(backgroundc_int)
end)

-- 解决标题闪烁：确保 toolbar 初始背景色和透明度正确
root_card.setBackgroundColor(backgroundc_int)
all_root.setAlpha(0) 

IArgbEvaluator=ArgbEvaluator.newInstance()
波纹({fh,_more,mark,comment,thank,voteup},"圆主题")
波纹({all_root},"方自适应")
设置toolbar(root_card)

import "model.answer"
回答容器=answer:new(回答id)
数据表={} -- 全局视图数据表

-- 辅助函数：获取当前页面的 mviews 数据
local function getCurrentMView()
  local adapter = pg.getAdapter()
  if not adapter then return nil end
  local pos = pg.getCurrentItem()
  local item = adapter.getItem(pos)
  if not item then return nil end
  return 数据表[item.id]
end

-- 简化获取当前页面信息的辅助函数
local function get_current_info()
  local mview = getCurrentMView()
  local data = mview and mview.data
  local author = data and data.author
  return mview, data, author, author and author.name or "未知作者", data and data.id
end

local function set_question_info(tab)
  local answer_count = tab.answer_count or tab.answerCount or 0
  local info_text = "点击查看全部" .. answer_count .. "个回答 >"
  all_answer.Text = info_text
  all_answer_expand.Text = info_text
  问题id = tab.id
  _title.Text = tab.title
  expand_title.Text = tab.title
  -- 强制应用一次背景色
  root_card.setBackgroundColor(backgroundc_int)
  title_bar_expand.setBackgroundColor(backgroundc_int)
  -- 强制重置标题状态为展开
  all_root.setAlpha(0)
  all_root_expand.setAlpha(1)
  
  if answer_count == 1 and 回答容器 then
    回答容器.isleft = true
    回答容器.isright = true
  end
    
  local function openQuestion()
    local target_id = 问题id or 回答容器.id内容:match("(.+)分割")
    if target_id == nil or target_id == "null" then
      return 提示("加载中")
    end
    newActivity("question", {target_id, _title.Text})
  end
    
  all_root.onClick = openQuestion
  all_root_expand.onClick = openQuestion
  all_answer_expand.onClick = openQuestion
end

-- 优化：如果 pre_data 中已经包含问题信息，则直接设置，避免多余的 API 请求
if type(pre_data) == "table" and pre_data.question then
  set_question_info(pre_data.question)
else
  -- 优化：直接获取信息，避免多余的 1ms 延迟
  answer:getinfo(回答id, function(tab)
    set_question_info(tab)
  end)
end

local dtl_translation = 0
local currentWebView
local cached_header_height = 0

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

function onPause()
  mainLay.setLayerType(View.LAYER_TYPE_SOFTWARE,nil)
end

function onResume()
  local mview = getCurrentMView()
  if mview and mview.ids.content then
    mview.ids.content.resumeTimers()
  end
  mainLay.setLayerType(View.LAYER_TYPE_NONE,nil)
end

local function 更新WebViewPadding(mview)
  if not mview or not mview.ids.content then return end
  local userinfo_h = mview.ids.userinfo.getHeight()
  if userinfo_h > 0 then
    local density = activity.getResources().getDisplayMetrics().density
    -- 核心：paddingTop = 总高度 - 负偏移量 (12px)
    local total_h_dp = userinfo_h / density - 12
    mview.ids.content.evaluateJavascript("document.body.style.paddingTop = '"..total_h_dp.."px'", nil)
  end
end

local function 统一滑动跟随(view,x,y,lx,ly)
  if view ~= currentWebView then return end
  
  -- 1. 缓存 Header 高度，避免重复测量
  if cached_header_height == 0 then
    cached_header_height = all_root_expand.getHeight()
    if cached_header_height == 0 then cached_header_height = dp2px(100) end
  end
  
  local translation = -y -- 直接使用 y 坐标避免 getScrollY() 调用
  
  -- 3. 执行偏移
  appbar.setTranslationY(translation)
  root_card.setTranslationY(-translation)
  
  -- 优化：使用局部变量缓存当前页面的 ids，避免在滚动中执行复杂的查找函数
  if not currentMViewIds then
    local mview = getCurrentMView()
    currentMViewIds = mview and mview.ids
  end

  if currentMViewIds and currentMViewIds.userinfo then
    currentMViewIds.userinfo.setTranslationY(translation)
  end

  -- 4. 处理透明度渐变
  local progress = math.min(1, math.abs(translation) / cached_header_height)
  all_root.setAlpha(progress)
  all_root_expand.setAlpha(1 - progress)
  
  -- 5. 底栏 (dtl) 逻辑
  local dy = y - ly
  if math.abs(dy) > 300 then return end
  local max_dtl_trans = getDtlMaxTranslation()
  dtl_translation = math.max(0, math.min(max_dtl_trans, dtl_translation + dy))
  dtl.setTranslationY(dtl_translation)
end

comment.onClick=function()
  local mview, data, author, name, 回答id = get_current_info()
  if not 回答id then return 提示("加载中") end
  local 保存路径=内置存储文件("Download/".._title.Text.."/"..name)
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
  local js_list = {"answer_pages", "imgplus", "mdcopy", "snap", "fade_in"}
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
    if height_px > 0 and height_px ~= last_appbar_height then
      last_appbar_height = height_px
      cached_header_height = 0 -- 重置缓存
      
      -- 更新所有已加载页面的 userinfo padding
      for k, v in pairs(数据表 or {}) do
        if v.ids and v.ids.userinfo then
          v.ids.userinfo.setPadding(dp2px(16), height_px, dp2px(16), 0)
          v.ids.userinfo.post(function() 更新WebViewPadding(v) end)
        end
      end
    end
  end
})

function 数据添加(t,回答id,viewId)
  -- 暴露视频处理接口，供数据加载完成后调用
  t.processVideo = function()
    if t.data then 处理视频逻辑(t, t.data) end
  end

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
      if t.userinfo then t.userinfo.visibility=0 end
      -- 延迟显示加载动画，避免快速切换时的闪烁
      view.postDelayed(function()
        if t.progress and t.content.getVisibility() == 8 then
          t.progress.setVisibility(0)
        end
      end, 200)
      执行加载JS(view)
    end,
    onPageFinished=function(view,url,favicon)
      view.setVisibility(0)
      view.animate().alpha(1).setDuration(200).start()
      if t.progress then t.progress.setVisibility(8) end
      
      -- 注入 Padding-Top
      local mview = 数据表[viewId] or {ids=t}
      view.post(function() 更新WebViewPadding(mview) end)

      if 全局主题值=="Night" then 夜间模式回答页(view) else 初始化背景(view) end
      if this.getSharedData("eruda") == "true" then 加载js(view,获取js("eruda")) end
      屏蔽元素(view,{'.AnswerReward','.AppViewRecommendedReading'})

      view.postDelayed(function()
        加载js(view,获取js("answer_code"))
        加载js(view,获取js("scrollRestorer"))
        -- 恢复滑动位置
        view.postDelayed(function()
          view.evaluateJavascript("window.scrollRestorer.restoreScrollPosition()", {onReceiveValue=function(b)
            view.evaluateJavascript("window.scrollRestorerPos", {onReceiveValue=function(pos_val)
              local 保存滑动位置 = tonumber(pos_val) or 0
              if t.userinfo and 保存滑动位置 > t.userinfo.height then
                setDtlTranslation(getDtlMaxTranslation())
                
                local currentPos = pg.getCurrentItem()
                local adapter = pg.getAdapter()
                local currentItem = adapter and adapter.getItem(currentPos)
                -- 仅当当前显示的是该页面时提示
                if currentItem and currentItem.id == viewId then
                   提示("已恢复到上次滑动位置")
                end
              end
            end})
          end})
        end, 100)
      end, 200)

      if this.getSharedData("代码块自动换行")=="true" then
        加载js(t.content,'document.querySelectorAll(".ztext pre").forEach(p => { p.style.whiteSpace = "pre-wrap"; p.style.wordWrap = "break-word"; });')
      end

      -- 扁平化数据逻辑处理
      view.postDelayed(function()
        t.processVideo()
      end, 100)
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

  t.content.setBackgroundColor(0)
  if t.root then t.root.setBackgroundColor(backgroundc_int) end
  if appbar.getHeight() > 0 then
    t.userinfo.setPadding(dp2px(16), appbar.getHeight(), dp2px(16), 0)
  end
  t.content.loadUrl("https://www.zhihu.com/appview/answer/"..回答id)
end

local function 更新底栏(data)
  local function 设置状态(status, iconview, textview, icon, count)
    if status then
      iconview.setImageBitmap(loadbitmap(图标(icon)))
      textview.setTextColor(primaryc_int)
     else
      iconview.setImageBitmap(loadbitmap(图标(icon.."_outline")))
      textview.setTextColor(stextc_int)
    end
    textview.Text = tostring(count)
  end

  设置状态(data.点赞状态, vote_icon, vote_count, "vote_up", data.voteup_count)
  设置状态(data.感谢状态, thanks_icon, thanks_count, "favorite", data.thanks_count)
  favlists_count.Text = tostring(data.favlists_count)
  comment_count.Text = tostring(data.comment_count)
end

function 初始化页(mviews)
  local adapter = pg.getAdapter()
  if not adapter then return end
  local current_pos = pg.getCurrentItem()
  local item = adapter.getItem(current_pos)
  -- 校验当前页面是否匹配，防止错乱
  if not item or item.id ~= mviews.id then return end

  this.getLuaState().pushObjectValue(thisFragment)
  this.getLuaState().setGlobal("currentFragment")

  local data = mviews.data
  local ids = mviews.ids
  if (mviews.load == true or mviews.load == "preview" or mviews.load == "loading") and data and data.author then
    ids.username.Text = data.author.name
    ids.userheadline.Text = (data.author.headline == "" and "Ta还没有签名哦~") or data.author.headline
    loadglide(ids.usericon, data.author.avatar_url)
    更新底栏(data)

    ids.userinfo.onClick = function()
      nTView = ids.usericon
      newActivity("people", {data.author.id, data.author})
    end

    comment.onLongClick = function()
      提示(data.comment_count.."条评论")
      return true
    end
  elseif mviews.load == "loading" then
    ids.username.Text = "内容加载中..."
    ids.userheadline.Text = "请稍等片刻~"
  end
end

pg.adapter=BaseViewPage2Adapter(this)

function addAnswer(index)
  local ids={}
  local 加入view=loadlayout("layout/answer_list",ids)
  加入view.setBackgroundColor(backgroundc_int)
  数据表[加入view.id]={
    data={},
    ids=ids,
    id=加入view.id -- 关键：存储 View ID 以便校验
  }
  if index then
    pg.adapter.insert(加入view,index)
   else
    pg.adapter.insert(加入view,pg.adapter.getItemCount())
  end
end

-- 预先添加三个页面，支持预加载
for i=1,3 do addAnswer() end

-- 优化：使用 pre_data 实现首屏秒开
if type(pre_data) == "table" and pre_data.author then
  local first_view = pg.adapter.getItem(0)
  if first_view then
    local mviews = 数据表[first_view.id]
    if mviews then
      mviews.load = "preview" -- 标记为预览状态，允许后续覆盖加载
      mviews.data = {
         id = tostring(pre_data.id),
         voteup_count = pre_data.voteup_count,
         comment_count = pre_data.comment_count,
         thanks_count = pre_data.thanks_count or 0,
         favlists_count = 0,
         点赞状态 = false,
         感谢状态 = false,
         author = {
           name = pre_data.author.name,
           headline = pre_data.author.headline,
           avatar_url = pre_data.author.avatar_url,
           id = tostring(pre_data.author.id)
         }
      }
      初始化页(mviews)
    end
  end
end

function 加载页(mviews, isleftadd, pos, target_id, silent)
  if not target_id or (mviews.load and mviews.load ~= "preview") then return end
  mviews.load = "loading"
  mviews.target_id = target_id
  
  -- 标记占用并立即加载网页
  回答容器.used_ids[tostring(target_id)] = true
  数据添加(mviews.ids, tostring(target_id), mviews.id)
  
  -- 异步获取详细信息
  回答容器:getAnswer(target_id, function(cb)
    if cb == false then
      mviews.load = nil
      return
    end

    mviews.data = {
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
    mviews.ids.data = cb
    mviews.load = true
    
    -- 填充后续 ID 信息
    local mypageinfo = cb.pagination_info
    if mypageinfo then
      回答容器.pageinfo[tostring(cb.id)] = {
        prev_ids = mypageinfo.prev_answer_ids,
        next_ids = mypageinfo.next_answer_ids
      }
    end

    初始化页(mviews)
    
    -- 如果当前页面就是正在显示的页面，立即记录历史
    if pos == pg.getCurrentItem() then
      初始化历史记录数据()
      保存历史记录(cb.id, cb.question.title, cb.excerpt, "回答")
    end
    
    -- 数据就绪后，尝试处理视频逻辑 (修复竞态条件)
    if mviews.ids.processVideo then mviews.ids.processVideo() end
    
    -- 尝试链式预加载物理下一页
    local next_pos = pos + (isleftadd and -1 or 1)
    local adapter = pg.getAdapter()
    if adapter and next_pos >= 0 and next_pos < adapter.getItemCount() then
      local next_item = adapter.getItem(next_pos)
      if 数据表 then
        local next_mviews = 数据表[next_item.id]
        if next_mviews and not next_mviews.load then
          local next_id = 回答容器:getNextId(isleftadd, target_id)
          if next_id then 加载页(next_mviews, isleftadd, next_pos, next_id, true) end
        end
      end
    end
  end, silent)
end

-- 辅助函数：确保指定位置的页面正在加载
local function ensureLoading(p, from_id)
  if not 数据表 then return end
  if p < 0 or not pg.adapter then return end
  if p >= pg.adapter.getItemCount() then addAnswer() end
  local item = pg.adapter.getItem(p)
  if not item then return end
  local mv = 数据表[item.id]
  if mv and not mv.load then
    local nid = 回答容器:getNextId(false, from_id)
    if nid then 加载页(mv, false, p, nid, true) end
  end
end

pg.registerOnPageChangeCallback(OnPageChangeCallback{
  onPageSelected=function(pos)
    local adapter = pg.getAdapter()
    if not adapter or not 数据表 then return end
    local item = adapter.getItem(pos)
    local mviews = 数据表[item.id]
    if not mviews then return end
    
    currentWebView = mviews.ids.content
    currentMViewIds = mviews.ids -- 切换页面时更新缓存的 ids
    setDtlTranslation(0, true)
    
    -- 1. 刷新当前页
    if mviews.load == true then
      回答容器.getid = mviews.data.id
      初始化页(mviews)
      初始化历史记录数据()
      保存历史记录(mviews.data.id, mviews.ids.data.question.title, mviews.ids.data.excerpt, "回答")
    elseif mviews.load == "loading" then
      初始化页(mviews)
    else
      -- 现场补救：可能是跳滑导致的未加载
      加载页(mviews, false, pos, 回答容器.getid)
    end

    -- 2. 预测加载 (延时执行，避免阻塞 UI 或引发刷新闪烁)
    pg.post(function()
      local base_id = (mviews.load == true) and mviews.data.id or mviews.target_id
      ensureLoading(pos + 1, base_id)
    end)

    -- 同步 AppBar 状态
    local scroll_y = currentWebView.getScrollY()
    local translation = -scroll_y
    appbar.setTranslationY(translation)
    root_card.setTranslationY(-translation)
    
    if cached_header_height == 0 then cached_header_height = all_root_expand.getHeight() or dp2px(100) end
    local progress = math.min(1, math.abs(translation) / cached_header_height)
    all_root.setAlpha(progress)
    all_root_expand.setAlpha(1 - progress)
  end,
  onPageScrolled=function(pos,positionOffset,positionOffsetPixels)
    if positionOffsetPixels==0 then
      if 回答容器 then 回答容器:updateLR() end
    elseif positionOffset > 0 and 回答容器 and 回答容器.isright then
      local item = pg.adapter.getItem(pos)
      local mviews = item and 数据表[item.id]
      if mviews and mviews.load == true then
        pg.setCurrentItem(pos, false)
        if last_toast_time + 2000 < os.time() * 1000 then
          提示("已经没有更多内容啦")
          last_toast_time = os.time() * 1000
        end
      end
    end
  end
})

-- 优化：首屏加载
taskUI(function()
  local mview = getCurrentMView()
  if mview then
    currentWebView = mview.ids.content
    if not mview.load then
      加载页(mview, false, pg.getCurrentItem(), 回答容器.getid)
    end
    -- 强制同步初始状态
    if currentWebView then
      local scroll_y = currentWebView.getScrollY()
      local translation = -scroll_y
      appbar.setTranslationY(translation)
      root_card.setTranslationY(-translation)
      if scroll_y == 0 then
        all_root.setAlpha(0)
        all_root_expand.setAlpha(1)
      end
    end
    -- 补救首页记录
    if mview.load == true then
      初始化历史记录数据()
      保存历史记录(mview.data.id, mview.ids.data.question.title, mview.ids.data.excerpt, "回答")
    end
  end
end)

function onDestroy()
  for k,v in pairs(数据表) do
    if v.ids and v.ids.content then
      v.ids.content.destroy()
    end
  end
  数据表 = nil
end

voteup.onClick=function()
  local _, data, _, _, 回答id = get_current_info()
  if not 回答id then return 提示("加载中") end
  local is_up = not data.点赞状态
  local type_str = is_up and "up" or "neutral"
  
  zHttp.post("https://api.zhihu.com/answers/"..回答id.."/voters", '{"type":"'..type_str..'"}', posthead, function(code,content)
    if code==200 then
      提示(is_up and "点赞成功" or "取消点赞成功")
      data.点赞状态 = is_up
      data.voteup_count = data.voteup_count + (is_up and 1 or -1)
      更新底栏(data)
    elseif code==401 then
      提示("请登录后使用本功能")
    end
  end)
end

thank.onClick=function()
  local _, data, _, _, 回答id = get_current_info()
  if not 回答id then return 提示("加载中") end
  local is_thank = not data.感谢状态
  
  local url = "https://www.zhihu.com/api/v4/zreaction"
  local method = is_thank and zHttp.post or zHttp.delete
  local params = is_thank 
      and '{"content_type":"answers","content_id":"'..回答id..'","action_type":"emojis","action_value":"red_heart"}'
      or "?content_type=answers&content_id="..回答id.."&action_type=emojis&action_value="
  
  method(url.. (is_thank and "" or params), is_thank and params or posthead, is_thank and posthead or function(code,content)
      if code==200 then
        提示("取消感谢成功")
        data.感谢状态 = false
        data.thanks_count = data.thanks_count - 1
        更新底栏(data)
      elseif code==401 then
        提示("请登录后使用本功能")
      end
  end, is_thank and function(code,content) 
      if code==200 then
        提示("表达感谢成功")
        data.感谢状态 = true
        data.thanks_count = data.thanks_count + 1
        更新底栏(data)
      elseif code==401 then
        提示("请登录后使用本功能")
      end
  end or nil)
end

mark.onClick=function()
  local mview = getCurrentMView()
  if mview then
    local url = mview.ids.content.getUrl()
    if url then 加入收藏夹(url:match("answer/(.+)"),"answer") end
  end
end

mark.onLongClick=function()
  local mview = getCurrentMView()
  if mview then
    local url = mview.ids.content.getUrl()
    if url then 加入默认收藏夹(url:match("answer/(.+)"),"answer") end
  end
  return true
end

function onKeyDown(code,event)
  if this.getSharedData("音量键选择tab")~="true" or 全屏模式==true then return false end
  if code==KeyEvent.KEYCODE_VOLUME_UP or code==KeyEvent.KEYCODE_VOLUME_DOWN then return true end
end

function onKeyUp(code,event)
  if this.getSharedData("音量键选择tab")~="true" or 全屏模式==true then return false end
  local current = pg.getCurrentItem()
  if code==KeyEvent.KEYCODE_VOLUME_UP then
    pg.setCurrentItem(current-1)
    return true
  elseif code== KeyEvent.KEYCODE_VOLUME_DOWN then
    pg.setCurrentItem(current+1)
    return true
  end
end

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

taskUI(function()
  local function 获取当前WebView()
    local mview = getCurrentMView()
    return mview and mview.ids.content
  end

  local function 获取当前回答URL()
    local content = 获取当前WebView()
    if not content then return nil end
    local url = content.getUrl()
    if url == nil then 提示("加载中") return nil end
    return url
  end

  local function 获取分享文本(url)
    local format = "【回答】【%s】%s: %s"
    local answer_id = url:match("answer/(.+)")
    local _, _, _, name = get_current_info()
    return string.format(format, _title.Text, name, "https://www.zhihu.com/question/"..问题id.."/answer/"..answer_id)
  end

  a=MUKPopu({
    tittle="回答",
    list={
      {
        src=图标("refresh"),text="刷新",onClick=function()
          local v = 获取当前WebView()
          if v then v.reload() 提示("刷新中") end
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
          import "com.nwdxlgzs.view.photoview.PhotoView"

          function webviewToBitmap(webView, func)
            webView.evaluateJavascript("captureScreenshot()", {onReceiveValue=function(b)
                local process
                process=function()
                  webView.evaluateJavascript("getScreenshot()", {onReceiveValue=function(b)
                      if b:find("process") then
                        taskUI(200, process)
                       else
                        func(base64ToBitmap(b))
                      end
                  end})
                end
                taskUI(300, process)
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
              local _, _, _, name = get_current_info()
              local dir = this.getExternalFilesDir(Environment.DIRECTORY_PICTURES).toString()
              local file = File(dir, "知乎回答-".._title.Text.."-来自-"..name..".jpg")
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
          local _, data, _, name, 回答id = get_current_info()
          if not 回答id then return 提示("加载中") end
          local 保存路径 = 内置存储文件("Download/".._title.Text.."/"..name)
          newActivity("comment", {回答id, "answers", 保存路径})
        end
      },
      {
        src=图标("get_app"),text="保存到本地",onClick=function()
          if not get_write_permissions() then return end
          local mview, data, author, name, 回答id = get_current_info()
          if not mview then return end
          local headline = author and author.headline or "Ta还没有签名哦~"
          local 保存路径 = 内置存储文件("Download/".._title.Text.."/"..name)
          local detail = string.format('question_id="%s"\nanswer_id="%s"\nthanks_count="%s"\nvote_count="%s"\nfavlists_count="%s"\ncomment_count="%s"\nauthor="%s"\nheadline="%s"\n', 
            问题id, 回答id, thanks_count.Text, vote_count.Text, favlists_count.Text, comment_count.Text, name, headline)
          写入文件(保存路径.."/detail.txt", detail)
          newActivity("saveweb", {mview.ids.content.getUrl(), 保存路径, detail})
        end,
        onLongClick=function()
          local content = 获取当前WebView()
          if content then
            content.evaluateJavascript('getmd()', {onReceiveValue=function(b)
                local _, _, _, name = get_current_info()
                提示("请选择一个保存位置")
                saf_writeText = b
                createDocumentLauncher.launch(_title.Text.."_"..name..".md")
            end})
          end
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
          local _, _, _, _, 回答id = get_current_info()
          if not 回答id then return 提示("加载中") end
          local url = "https://www.zhihu.com/report?id="..回答id.."&type=answer"
          newActivity("browser", {url.."&source=android&ab_signature=", "举报"})
        end
      },
      {
        src=图标("search"),text="在网页查找内容",onClick=function()
          local v = 获取当前WebView()
          if v then webview查找文字(v) end
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
    local mview = getCurrentMView()
    if not mview then return end
    local content = mview.ids.content
    local offset = (direction == "up" and -1 or 1) * (content.height - dp2px(40))
    content.scrollBy(0, offset)
  end
  up_button.onClick = function() 滑动("up") end
  down_button.onClick = function() 滑动("down") end
end