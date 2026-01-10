local base={}

function base:new(id)
  local child=table.clone(self)
  child.id=id
  return child
end

function base:getUrl()
  --2025 316 幽默知乎网页api 不填写url参数无法访问
  return "https://www.zhihu.com/api/v4/columns/"..self.id.."/items?ws_qiangzhisafe=0"
end

function base.getAdapter(people_column_pagetool,pos)
  local data=people_column_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      local holder=LuaCustRecyclerHolder(loadlayout(peple_column_item,views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      views.标题.text=data.标题
      views.预览内容.text=data.预览内容
      views.点赞数.text=data.点赞数
      views.评论数.text=data.评论数
      views.活动.text=data.活动
      loadglide(views.图像,data.图像)
      views.card.onClick=function()
        点击事件判断(data.id内容,data.标题)
      end
    end,
  }))
end


function base.resolvedata(v,data)

  local 头像=v.author.avatar_url
  local 点赞数=v.voteup_count
  local 评论数=v.comment_count
  local 预览内容=v.excerpt
  local 活动,id内容,标题
  if v.type=="answer" then
    活动="添加了回答"
    id内容=v.question.id or "null"
    id内容=id内容.."分割"..v.id
    标题=v.question.title
    预览内容=v.content[1].content
   elseif v.type=="zvideo" then
    活动="添加了视频"
    id内容="视频分割"..v.id
    标题=v.title
    预览内容="[视频]"
   elseif v.type=="article" then
    活动="添加了文章"
    id内容="文章分割"..v.id
    标题=v.title
  end

  local add={}
  add.活动=活动
  add.id内容=id内容
  add.标题=标题
  add.预览内容=预览内容
  add.点赞数=点赞数..""
  add.评论数=评论数..""
  add.图像=头像
  table.insert(data,add)
end

function base:initpage(view,sr)
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


return base