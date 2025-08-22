zemoji = require "model.zemoji":getZemoji().zemoji
--pcall(function()LuaUtil.unZip(srcLuaDir.."/res/zemoji.zip",activity.getExternalCacheDir().getPath())end)

zemojip={}
for ii,j in pairs(zemoji) do
  table.add(zemojip,{ii=ii,i=表情(ii)})
end

local base={}

function base:new(id,type)
  local child=table.clone(self)
  child.id=id
  child.type=type
  return child
end

function base:getUrlByType(sortby)
  local type=self.type
  if type~="comments" then
    return "https://api.zhihu.com/comment_v5/"..type.."/"..self.id.."/root_comment?order_by="..(sortby or "score")
   else
    return "https://api.zhihu.com/comment_v5/comment/"..self.id.."/child_comment?order_by="..(sortby or "ts")
  end
end

local function MyClickableSpan(url)
  local myspan=ClickableSpan{
    onClick=function(v)
      print(v)
      if v.Text:find("图片") or v.Text:find("动图") then
        local data={["0"]=url,["1"]=1}
        this.setSharedData("imagedata",luajson.encode(data))
        activity.newActivity("image")
        return
      end
      检查链接(url)
    end,
    updateDrawState=function(v)
      v.setColor(v.linkColor);
      v.setUnderlineText(true);
    end
  }
  return myspan
end



function base.resolvedata(v,data)
  local 头像=v.author.avatar_url
  local 内容=string.gsub(string.gsub(v.content,"</p>+$",""),"^<p>","")
  local 点赞数=v.vote_count
  local 时间=时间戳(v.created_time)
  local 名字=v.author.name
  local 回复名字=""

  if v.reply_to_author ~= nil
    --名字=v.author.. "  →  "..addauthor(v.reply_to_author)
    回复名字=" -> "..v.reply_to_author.name
    if v.reply_author_tag[1]~=nil
      回复名字=回复名字.."「"..v.reply_author_tag[1].text.."」"
    end
  end
  if v.author_tag[1] ~= nil
    名字=名字.."「"..v.author_tag[1].text.."」"
  end
  名字=名字..回复名字

  local myspan


  local 包含url
  local 包含图片
  if 内容:find("https?://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]") then
    local text=Html.fromHtml(内容)
    local style = SpannableStringBuilder(text)
    local len= style.length()
    local urltab=luajava.astable(style.getSpans(0, len,URLSpan))


    包含url=true
    if #urltab>0 then
      style.clearSpans()
      for i=1,#urltab do
        local urlspan=urltab[i]
        local url=urlspan.getURL()
        local Span=MyClickableSpan(url)
        local startindex= text.getSpanStart(urlspan)
        local endindex=text.getSpanEnd(urlspan)
        style.setSpan(Span, startindex, endindex, Spannable.SPAN_EXCLUSIVE_INCLUSIVE)
        local ext = url:sub(-4):lower()
        if ext==".jpg"||ext==".gif"||ext==".bmp"||ext==".png"||ext=="webp"||ext=="jpeg"
          包含图片=url
        end
      end
      myspan=style
    end
   else
    myspan=Html.fromHtml(内容)
  end


  --25.1.5 评论区表情 （参考于小白马）
  if 内容:find("%[.-%]") then
    for i,d in pairs(zemoji) do
      Spannable_Image(myspan, "\\["..i.."\\]",d)
    end
  end

  local 评论=""..tostring(v.child_comment_count or 0)
  local id内容=tostring(v.id)
  local 作者id=v.author.id
  local 预览内容=myspan
  local 标题=名字
  local 图像=头像
  local 赞=""..v.like_count
  --[[if tostring(v.liked)=="true"
    赞 = Spannable_Image(Html.fromHtml(赞),"赞",liked_drawable)
   else
    赞 = Spannable_Image(Html.fromHtml(赞),"赞",like_drawable)
  end]]
  if tostring(评论)=="0"
    评论 = "false"
  end
  local isme=(v.is_author==true and "true" or "false")
  pcall(function()
    local comment_tag=v.comment_tag[1]
    if comment_tag.type=="ip_info" then
      时间=comment_tag.text.." · "..时间
    end
  end)


  local add={}
  add.评论=评论
  add.id内容=id内容
  add.作者id=作者id
  add.预览内容=预览内容
  add.标题=标题
  add.图像=图像
  add.赞=赞
  add.时间=时间
  add.like_count=v.like_count
  add.can_delete=v.can_delete
  add.liked=v.liked
  add.disliked=v.disliked
  add.包含url=包含url
  add.包含图片=包含图片
  table.insert(data,add)
end

local function 多选菜单(data,views)
  local id内容=data.id内容

  local menu={

    {"分享",function()
        分享文本(data.预览内容)
    end},
    {"收藏至本地",function()
        local commenttype
        local 对话id=data.id内容
        local 对话用户=data.标题
        local 对话内容=data.预览内容.toString()
        if isme=="true" then
          local 请求链接="https://www.zhihu.com/api/v4/comment_v5/comment/"..对话id

          双按钮对话框("删除","删除该回复？该操作不可撤消！","是的","点错了",function(an)
            local url,head=require "model.zse96_encrypt"(请求链接)
            zHttp.delete(url,head,function(code)
              if code==200 then
                提示("删除成功！")
                an.dismiss()
              end
            end)
          end,function(an)an.dismiss()end)
          return true
        end

        local result=get_write_permissions()
        if result~=true then
          return true
        end

        if not 保存路径 then
          return 提示("该内容下评论不支持保存")
        end

        if not(文件夹是否存在(保存路径))then
          return 提示("先保存 才可以收藏评论")
        end

        if comment_type~="comments" then

          local 写入文件路径=保存路径.."/".."fold/"..对话id
          local 写入内容='author="'..对话用户..'"'
          local 写入内容=写入内容.."\n"
          local 写入内容=写入内容..'content="'..对话内容..'"'

          双按钮对话框("收藏","收藏这条评论？","是的","点错了",function(an)
            写入文件(写入文件路径,写入内容)
            提示("收藏成功")
            an.dismiss()
          end,
          function(an)an.dismiss()end)
         else
          --如果是在对话列表里
          local 写入文件路径=保存路径.."/".."fold/"..comment_id
          local 写入内容=''

          双按钮对话框("收藏","收藏整条列表？","是的","点错了",function(an)
            local alldata=comment_pagetool:getItemData(1)
            for i=1,#alldata do
              local 对话用户= alldata[i].标题
              local 对话内容= tostring(alldata[i].预览内容)
              写入内容=写入内容..'author="'..对话用户..'"'
              写入内容=写入内容.."\n"
              写入内容=写入内容..'content="'..对话内容..'"'
              写入内容=写入内容..'\n'
            end
            写入文件(写入文件路径,写入内容)
            提示("收藏成功")
            an.dismiss()
          end,
          function(an)an.dismiss()end)
        end
    end},
    {"复制",function()
        import "android.content.*"
        activity.getSystemService(Context.CLIPBOARD_SERVICE).setText(data.预览内容)
        提示("复制文本成功")
    end},
    {(function()
        if data.disliked
          return "取消踩"
         else
          return "踩评论"
        end
        end)(),function()
        if not(getLogin()) then
          return 提示("请登录后使用本功能")
        end
        if not(data.disliked)
          zHttp.put("https://api.zhihu.com/comment_v5/comment/"..id内容.."/reaction/dislike",'',postapphead,function(code,content)
            if code==200 then
              提示("踩成功")
              data.disliked=true
            end
          end)
         else
          zHttp.delete("https://api.zhihu.com/comment_v5/comment/"..id内容.."/reaction/dislike",postapphead,function(code,content)
            if code==200 then
              提示("取消踩成功")
              data.disliked=false
            end
          end)
        end
    end},
    {(function()
        if data.liked
          return "取消赞"
         else
          return "赞评论"
        end
        end)(),function()
        if not(getLogin()) then
          return 提示("请登录后使用本功能")
        end
        if not(data.liked)
          zHttp.put("https://api.zhihu.com/comment_v5/comment/"..id内容.."/reaction/like",'',postapphead,function(code,content)
            if code==200 then
              提示("赞成功")
              data.liked=true
            end
          end)
         else
          zHttp.delete("https://api.zhihu.com/comment_v5/comment/"..id内容.."/reaction/like",postapphead,function(code,content)
            if code==200 then
              提示("取消赞成功")
              data.liked=false
            end
          end)
        end
    end},
    {"举报",function()
        local url="https://www.zhihu.com/report?id="..id内容.."&type=comment"
        newActivity("browser",{url.."&source=android&ab_signature=","举报"})
    end},
    {"屏蔽",function()
        if not(getLogin()) then
          return 提示("请登录后使用本功能")
        end
        AlertDialog.Builder(this)
        .setTitle("提示")
        .setMessage("屏蔽过后如果想查看屏蔽的所有用户 可以在软件内主页右划 点击消息 选择设置 之后打开屏蔽即可管理屏蔽 你也可以选择管理屏蔽用户 但是这样没有选择设置可设置的多 如果只想查看屏蔽的用户 推荐选择屏蔽用户管理")
        .setPositiveButton("我知道了", {onClick=function()
            zHttp.post("https://api.zhihu.com/settings/blocked_users","people_id="..data.作者id,apphead,function(code,json)
              if code==200 or code==201 then
                提示("已拉黑")
              end
            end)
        end})
        .setNegativeButton("取消",nil)
        .show();
    end},
    {"查看主页",function()
        newActivity("people",{data.作者id})
    end}
  }

  if isstart then
    local authortext=data.标题
    local addmenu={"回复评论",function()
        发送评论(id内容,"回复"..data.标题.."发送的评论")
    end}
    table.insert(menu,addmenu)
  end

  local pop=showPopMenu(menu)
  pop.showAsDropDown(views,downx,0);

  return true
end

function base.getAdapter(comment_pagetool,pos)
  local data=comment_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      holder=LuaCustRecyclerHolder(loadlayout(comment_item,views))
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
          .with(ObjectAnimator.ofFloat(views.评论, "ChipStartPadding", {views.评论.ChipStartPadding, dp2px(2)}))
          .with(ObjectAnimator.ofFloat(views.评论, "ChipEndPadding", {views.评论.ChipEndPadding, dp2px(2)}))
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
          .with(ObjectAnimator.ofFloat(views.赞, "ChipStartPadding", {views.赞.ChipStartPadding, dp2px(2)}))
          .with(ObjectAnimator.ofFloat(views.赞, "ChipEndPadding", {views.赞.ChipEndPadding, dp2px(2)}))

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
        newActivity("people",{data.作者id})
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

function base:initpage(view,sr)
  self.view=view
  self.sr=sr
  orititle=_title.text

  return MyPageTool2:new({
    view=view,
    sr=sr,
    head="head",
    adapters_func=self.getAdapter,
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
  :refer()

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