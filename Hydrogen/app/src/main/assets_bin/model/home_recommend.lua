local base={}



function base:new(id)--类的new方法
  local child=table.clone(self)
  child.id=id
  return child
end

--全局变量
recommend_data={}
homeapphead=table.clone(head)
homeapphead["x-close-recommend"]="0"

local accessibilityManager = this.getSystemService(Context.ACCESSIBILITY_SERVICE);

function base.resolvedata(v,data)
  if v.type~="feed" then
    return
  end

  local isread='"t"'
  local readdata=v.brief
  local v=v.target or v
  local 标题=v.title
  local 点赞数=tostring(v.voteup_count or v.vote_count or v.reaction_count)
  local 评论数=tostring(v.comment_count)
  local 作者=v.author.name
  local 预览内容=作者.." : "..(v.excerpt or v.excerpt_title)
  if tointeger(activity.getSharedData("feed_cache"))>1
    if File(tostring(activity.getExternalCacheDir()).."/rc.json").exists()
      pcall(function()recommend_history=luajson.decode(io.open(tostring(activity.getExternalCacheDir()).."/rc.json"):read("*a"))end)
     else
      recommend_history={}
    end
    if table.find(recommend_history,预览内容)
      --开启无障碍后不提示找到重复内容
      if activity.getSharedData("feed_cache_tip") == "true" and not accessibilityManager.isTouchExplorationEnabled() then
        提示("找到重复内容")
      end
      local postdata=luajson.encode(readdata)
      postdata=urlEncode('[["r",'..postdata..']]')
      postdata="targets="..postdata
      zHttp.post("https://api.zhihu.com/lastread/touch/v2",postdata,apphead,function(code,content)
        if code==200 then
        end
      end)
      return
     else
      if #recommend_history>tointeger(activity.getSharedData("feed_cache") or 100)
        table.remove(recommend_history,1)
      end
      table.insert(recommend_history,预览内容)
      io.open(tostring(tostring(activity.getExternalCacheDir()).."/rc.json"),"w"):write(tostring(luajson.encode(recommend_history))):close()
    end
  end
  local id=v.id
  local 分割字符串

  local datatype
  local content_type=v.type
  switch content_type
   case "answer"
    datatype=0
    标题=v.question.title
    分割字符串="回答分割"
   case "pin"
    datatype=1
    标题=作者.."发表了想法"
    分割字符串="想法分割"
   case "article"
    datatype=2
    分割字符串="文章分割"
   case "zvideo"
    datatype=3
    分割字符串="视频分割"
   case "drama"
    datatype=4
    分割字符串="直播分割"
  end

  if not 预览内容 or 预览内容=="" or 预览内容=="无预览内容" then
    预览内容=nil
   else
    预览内容=Html.fromHtml(预览内容)
  end

  if 点赞数 then
    点赞数=tostring(点赞数)
   else
    点赞数="未知"
  end

  local id内容=分割字符串..id


  local add={}
  add.标题=标题
  add.预览内容=预览内容
  add.评论数=评论数
  add.点赞数=点赞数
  add.id内容=id内容

  local extradata= {
    isread=isread,
    readdata=readdata
  }
  table.insert(recommend_data,extradata)
  add.extradata=extradata

  table.insert(data,add)
end



function base.getAdapter(home_pagetool,pos)
  local data=home_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      loaditemc=获取适配器项目布局("home/home_layout")
      holder=LuaCustRecyclerHolder(loadlayout(loaditemc,views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      local type=data.datatype

      local 标题=data.标题
      local 预览内容=data.预览内容
      local 评论数=data.评论数
      local 点赞数=data.点赞数
      local id内容=data.id内容
      local extradata=data.extradata
      local isread=extradata.isread
      local readdata=extradata.readdata

      views.标题.text=标题
      views.预览内容.text=预览内容
      views.评论数.text=评论数
      views.点赞数.text=点赞数

      views.card.onTouch=function(v,event)
        downx=event.getRawX()
        downy=event.getRawY()
      end

      views.card.onClick=function()
        if getLogin() then
          home_pagetool:getItemData()[position+1].extradata.isread='"r"'

          local postdata=luajson.encode(readdata)
          postdata=urlEncode('[["r",'..postdata..']]')
          postdata="targets="..postdata

          zHttp.post("https://api.zhihu.com/lastread/touch/v2",postdata,apphead,function(code,content)
            if code==200 then
            end
          end)
        end

        nTView=views.card
        点击事件判断(data.id内容,data.标题)
      end

      views.card.onLongClick=function(view)
        if tostring(data.id内容):find("文章分割") then
          mytype="article"
          myid=tostring(data.id内容):match("文章分割(.+)")
         elseif tostring(data.id内容):find("想法分割") then
          mytype="pin"
          myid=tostring(data.id内容):match("想法分割(.+)")
         elseif tostring(data.id内容):find("视频分割") then
          mytype="zvideo"
          myid=tostring(data.id内容):match("视频分割(.+)")
         elseif tostring(data.id内容):find("直播分割") then
          mytype="drama"
          myid=tostring(data.id内容):match("直播分割(.+)")
         else
          mytype="answer"
          myid=tostring(data.id内容):match("分割(.+)")
        end
        zHttp.get("https://api.zhihu.com/negative-feedback/panel?scene_code=RECOMMEND&content_type="..mytype.."&content_token="..myid,apphead,function(code,content)
          if code==200 then
            local menu={}
            local data=luajson.decode(content).data.items
            for k,v in ipairs(data) do
              local raw_button=v.raw_button
              local method=string.lower(raw_button.action.method)
              local panel_text=raw_button.text.panel_text
              table.insert(menu,{
                panel_text,
                function()
                  if raw_button.action.backend_url then
                    zHttp.request(raw_button.action.backend_url,method,"",apphead,function(code,content)
                      if code==200 then
                        提示(raw_button.text.toast_text)
                      end
                    end)
                   elseif raw_button.action.intent_url then
                    newActivity("browser",{raw_button.action.intent_url.."&source=android&ab_signature=","举报"})
                  end
                end
              })
            end
            local pop=showPopMenu(menu)
            pop.showAtLocation(v, Gravity.NO_GRAVITY, downx, downy);
          end
        end)
      end

    end,
  }))

end

function base:initpage(view,sr)
  return MyPageTool2:new({
    view=view,
    sr=sr,
    head="homeapphead",
    adapters_func=self.getAdapter,
    func=self.resolvedata,
    allow_prev=true
  })
  :initPage()
  :createfunc()
  :setUrlItem("https://api.zhihu.com/topstory/recommend")
end

return base