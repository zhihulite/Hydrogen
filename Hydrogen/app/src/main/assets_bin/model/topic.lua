local base={
  nextUrl=nil,
  is_end=false,
  data={},
}

function base:new(id)
  local child=table.clone(self)
  child.id=id
  return child
end

function base:getData(callback)
  zHttp.get("https://www.zhihu.com/api/v5.1/topics/"..self.id.."?include=meta%2Cmeta.casts%2Cmeta.medias%2Cmeta.playlist%2Cmeta.awards%2Cmeta.pubinfo%2Cmeta.parameters%2Cvote%2Crank_list_info%2Cmeta.review_question%2Crelated_topics%2Crelated_topics.vote%2Cmeta.game_medias%2Cmeta.game_parameters%2Cmeta.team_parameters%2Cmeta.sports_parameters%2Cclub%2Ctimeline%2Cuniversity%2Cheader_video%2Cactivity%2Cpin_template",head,function(code,content)
    if code==200 then
      local data=luajson.decode(content)
      callback(data)
     elseif luajson.decode(content).error then
      提示(luajson.decode(content).error.message)
      callback(false)
    end
  end)
  return self
end


function base.getAdapter(topic_pagetool,pos)
  local data=topic_pagetool:getItemData(pos)
  local itemc
  local onclick=function(data)
    if data.标题 then
      点击事件判断(data.id内容,data.标题)
     else
      点击事件判断(data.id内容)
    end
  end
  switch pos
   case 1,2,3
    itemc=获取适配器项目布局("topic/topic_best")
   case 4
    itemc=获取适配器项目布局("topic/topic_all")
  end

  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      local holder=LuaCustRecyclerHolder(loadlayout(itemc,views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]

      if data.预览内容 then
        views.预览内容.Text=data.预览内容
      end
      if data.底部内容 then
        views.底部内容.Text=data.底部内容
      end
      views.标题.Text=data.标题
      if data.评论数 then
        views.评论数.Text=data.评论数
      end
      if data.点赞数 then
        views.点赞数.Text=data.点赞数
      end

      views.card.onClick=function()
        nTView=views.card
        onclick(data)
      end
    end,
  }))

end


function base.resolvedata(v,data)
  local name
  local v=v.target or v
  xpcall(function()
    name=v.author.name
    end,function()
    name=""
  end)
  local excerpt_data=v.excerpt or ""
  local excerpt=name.." : "..excerpt_data
  local add={}
  local title,id,voteup_count,comment_count,底部内容
  if v.type=="answer" then
    title=v.question.title
    id=v.question.id or "null"
    id=id.."分割"..v.id
   elseif v.type=="question" then
    title=v.title
    id=v.id
    local answer_count=v.answer_count.."个回答"
    local follower_count=v.follower_count.."人关注"
    id="问题分割"..v.id
    底部内容=answer_count.." · "..follower_count
   elseif v.type=="article" then
    title=v.title
    id="文章分割"..v.id
   elseif v.type=="zvideo" then
    title=v.title
    if excerpt_data=="" then
      local excerpt_data="[视频]"
      excerpt=name.." : "..excerpt_data
    end
    id="视频分割"..v.id
   elseif v.type=="pin" then
    title=v.title
    if title==nil or title==""
      title="一个想法"
    end
    id="想法分割"..v.id

    pcall(function()
      excerpt=Html.fromHtml(v.content[1].content)
    end)

  end

  pcall(function()
    voteup_count=v.voteup_count or v.like_count or v.counter.applaud
    comment_count=v.comment_count or v.comment_count or v.counter.comment
  end)

  if voteup_count then
    voteup_count=tostring(voteup_count)
   else
    voteup_count=""
  end

  if comment_count then
    comment_count=tostring(comment_count)
   else
    comment_count=""
  end

  if 底部内容 then
    excerpt=nil
    voteup_count=nil
    comment_count=nil
  end

  add.预览内容=excerpt
  add.标题=title
  add.评论数=comment_count
  add.id内容=id
  add.点赞数=voteup_count
  add.底部内容=底部内容

  table.insert(data,add)
end


function base:initpage(view,sr)
  return MyPageTool2:new({
    view=view,
    tabview=sr,
    addcanclick=true,
    head="head",
    adapters_func=self.getAdapter,
    func=self.resolvedata,
    addpos=1,
    urls={
      "https://www.zhihu.com/api/v5.1/topics/"..topic_id.."/feeds/essence/v2",
      "https://www.zhihu.com/api/v5.1/topics/"..topic_id.."/feeds/pin-hot/v2",
      "https://www.zhihu.com/api/v5.1/topics/"..topic_id.."/feeds/top_zvideo/v2",
      "https://www.zhihu.com/api/v5.1/topics/"..topic_id.."/feeds/top_question/v2",
    },
  })
  :addPage(2,{"详情","讨论","想法","视频","问题"})
  :createfunc()
  :refer(nil,nil,true)
end

return base