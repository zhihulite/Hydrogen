local zemojip={}
task(1, function()
  local zemoji_mod = require "model.zemoji":getZemoji().zemoji
  for ii, j in pairs(zemoji_mod) do
    table.insert(zemojip, {ii=ii, i=表情(ii)})
  end
  zemoji = zemoji_mod
end)

local base={}

function base:new(id,type)
  local child=table.clone(self)
  child.id=id
  child.type=type
  return child
end

function base:getUrlByType(sortby)
  if self.type ~= "comments" then
    return string.format("https://api.zhihu.com/comment_v5/%s/%s/root_comment?order_by=%s", self.type, self.id, sortby or "score")
  end
  return string.format("https://api.zhihu.com/comment_v5/comment/%s/child_comment?order_by=%s", self.id, sortby or "ts")
end

local function MyClickableSpan(url)
  return ClickableSpan{
    onClick=function(v)
      if v.Text:find("图片") or v.Text:find("动图") or url:lower():match("%.(jpg|gif|bmp|png|webp|jpeg)$") or url:find("zhimg.com") then
        this.setSharedData("imagedata", luajson.encode({["0"]=url, ["1"]=1}))
        activity.newActivity("image")
        return true
      end
      检查链接(url)
    end,
    updateDrawState=function(v)
      v.setColor(v.linkColor)
      v.setUnderlineText(true)
    end
  }
end

function base.resolvedata(v, data)
  local author = v.author
  local content = v.content:gsub("</p>+$", ""):gsub("^<p>", "")
  local name = author.name
  
  if v.reply_to_author then
    name = name .. " -> " .. v.reply_to_author.name
    if v.reply_author_tag and v.reply_author_tag[1] then
      name = name .. "「" .. v.reply_author_tag[1].text .. "」"
    end
  end
  if v.author_tag and v.author_tag[1] then
    name = name .. "「" .. v.author_tag[1].text .. "」"
  end

  local myspan
  local has_url, has_img = false, nil
  if content:find("http") then
    local style = SpannableStringBuilder(Html.fromHtml(content))
    local spans = luajava.astable(style.getSpans(0, style.length(), URLSpan))
    has_url = true
    for _, span in ipairs(spans) do
      local url = span.getURL()
      style.setSpan(MyClickableSpan(url), style.getSpanStart(span), style.getSpanEnd(span), Spannable.SPAN_EXCLUSIVE_INCLUSIVE)
      if url:lower():match("%.(jpg|gif|bmp|png|webp|jpeg)$") then has_img = url end
      style.removeSpan(span)
    end
    myspan = style
   else
    myspan = Html.fromHtml(content)
  end

  if content:find("%[.-%]") then
    for i, d in pairs(zemoji) do
      Spannable_Image(myspan, "\\["..i.."\\]", d)
    end
  end

  local time = 时间戳(v.created_time)
  pcall(function()
    if v.comment_tag and v.comment_tag[1] and v.comment_tag[1].type == "ip_info" then
      time = v.comment_tag[1].text .. " · " .. time
    end
  end)

  table.insert(data, {
    评论 = (v.child_comment_count and v.child_comment_count > 0) and tostring(v.child_comment_count) or "false",
    id内容 = tostring(v.id),
    作者id = author.id,
    author = author,
    预览内容 = myspan,
    标题 = name,
    图像 = author.avatar_url,
    赞 = tostring(v.like_count),
    时间 = time,
    like_count = v.like_count,
    can_delete = v.can_delete,
    liked = v.liked,
    disliked = v.disliked,
    包含url = has_url,
    包含图片 = has_img
  })
end

local function 多选菜单(data, views)
  local id内容 = data.id内容
  local menu = {
    {"分享", function() 分享文本(data.预览内容.toString()) end},
    {"复制", function()
        activity.getSystemService(Context.CLIPBOARD_SERVICE).setText(data.预览内容.toString())
        提示("复制文本成功")
    end},
    { data.disliked and "取消踩" or "踩评论", function()
        if not getLogin() then return 提示("请登录后使用本功能") end
        local method = data.disliked and zHttp.delete or zHttp.put
        method("https://api.zhihu.com/comment_v5/comment/"..id内容.."/reaction/dislike", '', postapphead, function(code)
          if code == 200 then
            提示(data.disliked and "取消踩成功" or "踩成功")
            data.disliked = not data.disliked
          end
        end)
    end},
    { data.liked and "取消赞" or "赞评论", function()
        if not getLogin() then return 提示("请登录后使用本功能") end
        local method = data.liked and zHttp.delete or zHttp.put
        method("https://api.zhihu.com/comment_v5/comment/"..id内容.."/reaction/like", '', postapphead, function(code)
          if code == 200 then
            提示(data.liked and "取消赞成功" or "赞成功")
            data.liked = not data.liked
          end
        end)
    end},
    {"举报", function()
        local url = "https://www.zhihu.com/report?id="..id内容.."&type=comment"
        newActivity("browser", {url.."&source=android&ab_signature=", "举报"})
    end},
    {"屏蔽", function()
        if not getLogin() then return 提示("请登录后使用本功能") end
        AlertDialog.Builder(this).setTitle("提示").setMessage("确定拉黑该用户吗？")
        .setPositiveButton("确定", {onClick=function()
            zHttp.post("https://api.zhihu.com/settings/blocked_users", "people_id="..data.作者id, apphead, function(code)
              if code == 200 or code == 201 then 提示("已拉黑") end
            end)
        end}).setNegativeButton("取消", nil).show()
    end},
    {"查看主页", function() newActivity("people", {data.作者id, data.author}) end}
  }

  if isstart then
    table.insert(menu, {"回复评论", function() 发送评论(id内容, "回复"..data.标题) end})
  end

  showPopMenu(menu).showAsDropDown(views, downx, 0)
  return true
end

function base.getAdapter(comment_pagetool,pos)
  local data=comment_pagetool:getItemData(pos)
  local item_layout = comment_pagetool.adapters_func_config.item_layout -- 从配置中获取布局
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      local holder=LuaCustRecyclerHolder(loadlayout(item_layout,views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      local type=data.datatype
      local 标题=data.标题
      local 预览内容=data.预览内容
      local 预览图片=data.包含图片
      local id内容=data.id内容
      local 评论=data.评论
      local 作者id=data.作者id
      local 图像=data.图像
      local 时间=data.时间
      local 赞=data.赞
      local isme=data.isme

      views.标题.text=标题
      views.时间.text=时间
      views.赞.text=赞
      views.评论.text=评论
      views.预览内容.text=预览内容
      loadglide(views.图像,图像)
      --[[if 预览图片
        loadglide(views.预览图片,预览图片)
        views.预览图片.onClick=function()
          nTView=views.预览图片
          this.setSharedData("imagedata",luajson.encode(预览图片))
        activity.newActivity("image")
        end
      end]]

      if 评论~="false"then
        views.评论.visibility=0
       else
        views.评论.visibility=8

      end
      if (data.liked)
        views.赞.ChipIcon=liked_drawable
       else
        views.赞.ChipIcon=like_drawable
      end
      import "android.view.MotionEvent"
      import "android.animation.ObjectAnimator"

      views.赞.onTouch=function(v,e)
        local action = e.action
        if action == MotionEvent.ACTION_DOWN then
          赞set=AnimatorSet()
          赞set.setInterpolator(AnticipateOvershootInterpolator(0.1))
          赞set.setDuration(200)
          赞set.play(ObjectAnimator.ofFloat(views.赞, "ChipCornerRadius", {views.赞.ChipCornerRadius, dp2px(4)}))
          .with(ObjectAnimator.ofFloat(views.赞, "ChipStartPadding", {views.赞.ChipStartPadding, dp2px(16)}))
          .with(ObjectAnimator.ofFloat(views.赞, "ChipEndPadding", {views.赞.ChipEndPadding, dp2px(16)}))
          .with(ObjectAnimator.ofFloat(views.评论, "ChipStartPadding", {views.评论.ChipStartPadding, dp2px(6)}))
          .with(ObjectAnimator.ofFloat(views.评论, "ChipEndPadding", {views.评论.ChipEndPadding, dp2px(6)}))
          views.赞.tag="t"
          赞set.start()
         else
          if views.赞.tag=="t"
            views.赞.tag="off"
            task(200,function()
              赞set=AnimatorSet()
              赞set.setInterpolator(AnticipateOvershootInterpolator(0.1))
              赞set.setDuration(200)
              赞set.play(ObjectAnimator.ofFloat(views.赞, "ChipCornerRadius", {views.赞.ChipCornerRadius, dp2px(16)}))
              .with(ObjectAnimator.ofFloat(views.赞, "ChipStartPadding", {views.赞.ChipStartPadding, dp2px(8)}))
              .with(ObjectAnimator.ofFloat(views.赞, "ChipEndPadding", {views.赞.ChipEndPadding, dp2px(8)}))
              .with(ObjectAnimator.ofFloat(views.评论, "ChipStartPadding", {views.评论.ChipStartPadding, dp2px(8)}))
              .with(ObjectAnimator.ofFloat(views.评论, "ChipEndPadding", {views.评论.ChipEndPadding, dp2px(8)}))

              赞set.start()
            end)
          end
        end
        return false
      end
      views.评论.onTouch=function(v,e)
        local action = e.action
        if action == MotionEvent.ACTION_DOWN then
          views.评论.tag="t"
          评论set=AnimatorSet()
          评论set.setInterpolator(AnticipateOvershootInterpolator(0.1))
          评论set.setDuration(200)
          评论set.play(ObjectAnimator.ofFloat(views.评论, "ChipCornerRadius", {views.评论.ChipCornerRadius, dp2px(4)}))
          .with(ObjectAnimator.ofFloat(views.评论, "ChipStartPadding", {views.评论.ChipStartPadding, dp2px(16)}))
          .with(ObjectAnimator.ofFloat(views.评论, "ChipEndPadding", {views.评论.ChipEndPadding, dp2px(16)}))
          .with(ObjectAnimator.ofFloat(views.赞, "ChipStartPadding", {views.赞.ChipStartPadding, dp2px(6)}))
          .with(ObjectAnimator.ofFloat(views.赞, "ChipEndPadding", {views.赞.ChipEndPadding, dp2px(6)}))

          评论set.start()
         else
          if views.评论.tag=="t"
            views.评论.tag="off"
            task(200,function()
              评论set=AnimatorSet()
              评论set.setInterpolator(AnticipateOvershootInterpolator(0.1))
              评论set.setDuration(200)
              评论set.play(ObjectAnimator.ofFloat(views.评论, "ChipCornerRadius", {views.评论.ChipCornerRadius, dp2px(16)}))
              .with(ObjectAnimator.ofFloat(views.评论, "ChipStartPadding", {views.评论.ChipStartPadding, dp2px(8)}))
              .with(ObjectAnimator.ofFloat(views.评论, "ChipEndPadding", {views.评论.ChipEndPadding, dp2px(8)}))
              .with(ObjectAnimator.ofFloat(views.赞, "ChipStartPadding", {views.赞.ChipStartPadding, dp2px(8)}))
              .with(ObjectAnimator.ofFloat(views.赞, "ChipEndPadding", {views.赞.ChipEndPadding, dp2px(8)}))

              评论set.start()
            end)
          end
        end
        return false
      end
      if comment_type=="comments"&&position==0
        local layoutParams = views.line.LayoutParams;
        layoutParams.height=dp2px(24)
        views.line.setLayoutParams(layoutParams);
        --感谢可爱的喵立方
        function draw_sin(canvas, x, y, length, height, periods, paint)
          local path = Path()
          local density = 40
          for i = 0, 1, 1 / periods / density do
            path.lineTo(i * length, math.sin(i * periods * math.pi * 2) * height)
          end
          path.offset(x, y)
          canvas.drawPath(path, paint)
        end

        local paint_qwq = Paint()
        paint_qwq.setColor(res.color.attr.colorSurfaceVariant)
        paint_qwq.setStrokeWidth(dp2px(1.5))
        paint_qwq.setStyle(Paint.Style.STROKE)
        paint_qwq.setStrokeCap(Paint.Cap.ROUND)

        views.line.setBackground(LuaDrawable(
        function(canvas, paint, drawable)
          canvas.drawColor(转0x(backgroundc))
          draw_sin(canvas, 0, views.line.height/2, views.line.width, views.line.height/4, 8, paint_qwq)
        end
        ))




        --[[已有加粗分割线，没必要 elseif comment_type=="comments"
        local layoutParams = views.card.LayoutParams;
        layoutParams.setMargins(dp2px(20), layoutParams.rightMargin, layoutParams.rightMargin,layoutParams.bottomMargin);
        views.card.setLayoutParams(layoutParams);]]
      end
      views.评论.onClick=function()
        发送评论(id内容,"回复"..data.标题.."发送的评论")
      end
      views.赞.onClick=function()
        if not(data.liked)
          zHttp.put("https://api.zhihu.com/comment_v5/comment/"..id内容.."/reaction/like",'',postapphead,function(code,content)
            if code==200 then
              提示("赞成功")
              data.liked=true
              data.like_count=data.like_count+1
              views.赞.ChipIcon=liked_drawable
              views.赞.text=data.like_count..""

            end
          end)
         else
          zHttp.delete("https://api.zhihu.com/comment_v5/comment/"..id内容.."/reaction/like",postapphead,function(code,content)
            if code==200 then
              提示("取消赞成功")
              data.liked=false
              data.like_count=data.like_count-1
              views.赞.ChipIcon=like_drawable
              views.赞.text=data.like_count..""
            end
          end)
        end
      end




      views.author_lay.onClick=function()
        nTView=views.图像
        newActivity("people",{data.作者id, data.author})
      end

      views.card.onTouch=function(v,event)
        downx=event.getX()
        downy=event.getY()
      end
      views.card.onClick=function()
        if 评论=="false" then
          return
         else
          if comment_type=="comments" then
            return 提示("当前已在该对话列表内")
          end
        end
        nTView=views.card
        newActivity("comment",{data.id内容,"comments",保存路径,comment_id})
      end
      views.预览内容.onClick=function()
        views.card.performClick()
      end
      views.card.onLongClick=function(view)
        多选菜单(data,view)
      end

      if data.包含url then
        views.预览内容.MovementMethod=LinkMovementMethod.getInstance()
      end

    end,
  }))

end

function base:initpage(view,sr,item_layout)
  self.view=view
  self.sr=sr
  orititle=_title.text

  return MyPageTool2:new({
    view=view,
    sr=sr,
    head="head",
    adapters_func=self.getAdapter,
    adapters_func_config={item_layout=item_layout}, -- 显式传递布局配置
    func=self.resolvedata,
    firstfunc=function(data,adpdata)
      --针对对话列表 添加父评论
      if self.type=="comments" then
        self.resolvedata(data.root,adpdata)
        评论类型=data.root.resource_type.."s"
        评论id=父回复id or comment_id
       else
        评论类型=comment_type
        评论id=comment_id
      end
      if data.counts then
        _title.text=orititle.." "..tostring(data.counts.total_counts).."条"
       else
        local tip="知识被荒原了"
        if data.comment_status and data.comment_status.text then
          tip=data.comment_status.text
        end
        AlertDialog.Builder(this)
        .setTitle("提示")
        .setCancelable(false)
        .setMessage(tip)
        .setPositiveButton("我知道了",{onClick=function()
            关闭页面()
        end})
        .show()
      end
    end
  })
  :initPage()
  :createfunc()
  :setUrlItem(self:getUrlByType())

end

function 发送评论(id,title)
  if not(getLogin()) then
    return 提示("请登录后使用本功能")
  end
  local stitle = title or "输入评论"
  local mytext
  local postdata
  local 请求链接
  回复id=id
  local endicondrawable=BitmapDrawable(Bitmap.createScaledBitmap(loadbitmap(图标("face")), sp2px(48),sp2px(48), true))


  bottomSheetDialog = BottomSheetDialog(this)
  bottomSheetDialog.setContentView(
  loadlayout({
    LinearLayout;
    id="root",
    fitsSystemWindows=false;
    orientation="vertical";
    layout_height="fill";
    layout_width="fill";
    {
      LinearLayout;
      layout_width="fill";
      layout_height="fill";
      gravity="center";
      id="sendlay";
      Focusable=true;
      FocusableInTouchMode=true;
      --开启动画可能造成卡顿
      --LayoutTransition=LayoutTransition().enableTransitionType(LayoutTransition.CHANGING);
      --[[  {
        EditText;
        id="send_edit";
        layout_weight=1;
        layout_marginLeft="16dp";
        layout_margin="8dp";
        maxLines=10;
        hint="输入评论";
      };]]
      {
        TextInputLayout,
        layout_height="wrap",
        layout_weight=1;
        layout_marginLeft="16dp";
        layout_marginTop="12dp";
        layout_margin="8dp";
        boxStrokeColor=primaryc,
        boxCornerRadii = {dp2px(20),dp2px(20),dp2px(20),dp2px(20)},
        --paddingBottom="16dp",
        layout_width="match",
        hint=stitle,
        id="send_input",
        endIconDrawable=endicondrawable,
        endIconMode=1,
        hintTextColor=ColorStateList.valueOf(转0x(primaryc)),
        boxBackgroundMode=TextInputLayout.BOX_BACKGROUND_OUTLINE,
        --startIconDrawable=R.drawable.material_ic_edit_black_24dp,
        --boxBackgroundColor=0xffffffff,
        {
          TextInputEditText,
          id="send_edit",
          HighlightColor =primaryc,
          textColor=textc,
          --style=R.style.Widget_MaterialComponents_TextInputEditText_OutlinedBox_Dense,
          layout_height="wrap",
          layout_width="match",
        },
      },
      {
        MaterialButton;
        layout_marginRight="10dp";
        id="send";
        textColor=backgroundc;
        text="发送";
      };
    };
    {RecyclerView;
      id="zemorc";
      layout_width="fill";
      layout_height=0;
    };

  }))

  isZemo=false
  heightmax=0
  --不好看（zemorc.setPadding(0,dp2px(24),0,dp2px(24))
  send_edit.requestFocus()
  send_edit.postDelayed(Runnable{
    run=function()
      local imm= this.getSystemService(Context.INPUT_METHOD_SERVICE);
      imm.showSoftInput(send_edit, InputMethodManager.SHOW_IMPLICIT);
    end
  }, 100);
  send_input.setEndIconOnClickListener(View.OnClickListener{
    onClick=function(v)
      local view=bottomSheetDialog.window.getDecorView()
      if heightmax<100
        heightmax=dp2px(260)
      end
      if isShowing then
        local WindowInsets = luajava.bindClass "android.view.WindowInsets"
        view.windowInsetsController.hide(WindowInsets.Type.ime())
        isZemo=true
       else
        local WindowInsets = luajava.bindClass "android.view.WindowInsets"
        view.windowInsetsController.show(WindowInsets.Type.ime())

      end
    end,
  })
  local GridLayoutManager = luajava.bindClass "androidx.recyclerview.widget.GridLayoutManager"
  local LuaRecyclerAdapter = luajava.bindClass "com.androlua.LuaRecyclerAdapter"
  local adapter1=LuaRecyclerAdapter(activity,zemojip,{LinearLayout,id="mainlay",gravity="center",
    {ImageView,id="i",layout_width="32sp",layout_marginTop="8dp";layout_height="32sp";layout_marginLeft="4dp";layout_marginRight="4dp";layout_marginBottom="8dp";},
  })
  pcall(function() bottomSheetDialog.getWindow().setDecorFitsSystemWindows(false)
    bottomSheetDialog.getWindow().addFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
  end)
  bottomSheetDialog.show()
  .setCancelable(true)
  .behavior.setMaxWidth(dp2px(600))

  local view=bottomSheetDialog.window.getDecorView()
  view.setOnApplyWindowInsetsListener(View.OnApplyWindowInsetsListener{
    onApplyWindowInsets=function(v,i)
      local WindowInsets = luajava.bindClass "android.view.WindowInsets"
      local status = i.getInsets(WindowInsets.Type.statusBars())
      local nav = i.getInsets(WindowInsets.Type.navigationBars())
      local ime = i.getInsets(WindowInsets.Type.ime())
      local layoutParams = sendlay.LayoutParams;
      layoutParams.setMargins(layoutParams.leftMargin, layoutParams.rightMargin, layoutParams.rightMargin,nav.bottom);
      sendlay.setLayoutParams(layoutParams);
      if ime.bottom>heightmax
        heightmax=ime.bottom
      end
      if Build.VERSION.SDK_INT<31
        local layoutParams = zemorc.LayoutParams;
        layoutParams.height=(function() if !isZemo then return ime.bottom else return heightmax end end)()
        zemorc.setLayoutParams(layoutParams);
        local layoutParams = root.LayoutParams;
        layoutParams.height=-2
        root.setLayoutParams(layoutParams);
      end
      isShowing=i.isVisible(WindowInsets.Type.ime())
      return i
    end
  })
  if Build.VERSION.SDK_INT >30
    view.setWindowInsetsAnimationCallback(luajava.override(WindowInsetsAnimation.Callback,{
      onProgress=function(_,i,animations)
        local WindowInsets = luajava.bindClass "android.view.WindowInsets"
        local status = i.getInsets(WindowInsets.Type.statusBars())
        local nav = i.getInsets(WindowInsets.Type.navigationBars())
        local ime = i.getInsets(WindowInsets.Type.ime())
        local layoutParams = zemorc.LayoutParams;
        layoutParams.height=(function() if !isZemo then return ime.bottom else return heightmax end end)()
        zemorc.setLayoutParams(layoutParams);
        local layoutParams = root.LayoutParams;
        layoutParams.height=-2
        root.setLayoutParams(layoutParams);
        return i
      end,
    },1))
  end
  zemorc.adapter=adapter1
  zemorc.layoutManager=GridLayoutManager(activity,8)
  adapter1.setAdapterInterface(LuaRecyclerAdapter.AdapterInterface{
    onBindViewHolder=function(viewHolder,index)
      viewHolder.tag.i.setBackgroundDrawable(activity.Resources.getDrawable(ripple).setColor(ColorStateList(int[0].class{int{}},int{primaryc})))
      --lua的adapter不支持直接调用非索引table，因此在这里脱裤子放屁（
      xpcall(function()
        viewHolder.tag.i.setTooltipText(tostring(adapter1.data[index+1].ii or "error"))
        viewHolder.tag.i.onClick=function()
          local s,e = send_edit.getSelectionStart(),send_edit.getSelectionEnd()
          send_edit.text=utf8.sub(send_edit.text,1,s).."["..adapter1.data[index+1].ii.."]"..utf8.sub(send_edit.text,s+1)
          --[[ 效果不佳    myspan=Html.fromHtml(send_edit.text)
          for i,d in pairs(zemoji) do
    Spannable_Image(myspan, "["..i.."]",d)
  end
send_edit.text=myspan]]
          send_edit.setSelection(utf8.len(adapter1.data[index+1].ii)+2+s)
        end
      end,function(a) print(index) end)
    end
  })



  send.onClick=function()
    --测试不通过unicode编码也可以 暂时这么解决
    --或许之后知乎会仅支持unicode 到时候下载知乎app分析一下

    --替换 防止发表评论提交多行知乎api报错
    local mytext=send_edit.text
    --回车
    :gsub("\r","\\u000D")
    --换行
    :gsub("\n","\\u000A")

    if tostring(send_edit.text)==""
      提示("你还没输入喵")
      return
    end
    --评论类型和评论id处理逻辑在comment_base
    local postdata='{"comment_id":"","content":"'..mytext..'","extra_params":"","has_img":false,"reply_comment_id":"'..回复id..'","score":0,"selected_settings":[],"sticker_type":null,"unfriendly_check":"strict"}'
    local 请求链接="https://www.zhihu.com/api/v4/comment_v5/"..评论类型.."/"..评论id.."/comment"

    local url,head=require "model.zse96_encrypt"(请求链接)
    zHttp.post(url,postdata,head,function(code,json)
      if code==200 then
        提示("发送成功 如若想看到自己发言请刷新数据")
        bottomSheetDialog.dismiss()
      end
    end)
  end

end

return base