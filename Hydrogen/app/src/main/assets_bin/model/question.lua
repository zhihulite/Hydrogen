local base_question={}


function base_question:new(id)
  local child=table.clone(self)
  child.id=id
  return child
end


function base_question:getData(callback)
  local url="https://www.zhihu.com/api/v4/questions/"..self.id.."?include=read_count,answer_count,comment_count,follower_count,detail,excerpt,author,relationship.is_following,topics"
  zHttp.get(url,head
  ,function(code,content)
    if code==200 then
      local data=luajson.decode(content)
      callback(data)
     else
      callback(false)
    end
  end)
  return self
end

function base_question:getUrl(sortby)
  --2025 501 幽默知乎网页api 不填写url参数无法访问
  return "https://www.zhihu.com/api/v4/questions/"..self.id.."/feeds?include=badge%5B*%5D.topics,comment_count,excerpt,voteup_count,created_time,updated_time,upvoted_followees,voteup_count,media_detail&limit=20".."&order="..(sortby or "default").. "&ws_qiangzhisafe=0"
end


function base_question.getAdapter(question_pagetool,pos)
  local data=question_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      local holder=LuaCustRecyclerHolder(loadlayout(question_itemc,views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      views.标题.Text=data.标题
      views.点赞数.Text=data.点赞数
      views.评论数.Text=data.评论数
      views.预览内容.Text=data.预览内容
      loadglide(views.图像,data.图像)

      views.card.onClick=function()
        nTView=views.card
        newActivity("answer",{question_id,tostring(data.id内容)})
      end
    end,
  }))

end

function base_question.resolvedata(v,data)
  local v=v.target
  if v.excerpt == nil or v.excerpt=="" then
    if v.media_detail and v.media_detail.videos then
      if #v.media_detail.videos>0 then
        v.excerpt="[视频]"
      end
    end
  end
  local 图片=v.author.avatar_url
  local add={}

  add.标题=v.author.name
  add.点赞数=v.voteup_count..""
  add.评论数=v.comment_count..""
  add.id内容=v.id..""
  add.预览内容=Html.fromHtml(v.excerpt or "无")
  add.图像=图片
  table.insert(data,add)
end

function base_question:initpage(view,sr)
  return MyPageTool2:new({
    view=view,
    sr=sr,
    head="head",
    adapters_func=self.getAdapter,
    func=self.resolvedata
  })
  :initPage()
  :createfunc()
  :setUrlItem(self:getUrl())
  :refer()
end


return base_question