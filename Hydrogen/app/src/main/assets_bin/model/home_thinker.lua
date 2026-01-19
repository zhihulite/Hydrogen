local base={}

function base:new(id)--类的new方法
  local child=table.clone(self)
  child.id=id
  return child
end

function base.resolvedata(v,data)
  local 图像
  local v=v.target or v
  xpcall(function()
    图像=v.images[1].url
    end,function()
    图像=v.video.thumbnail
  end)

  local add={}

  local 标题=v.excerpt
  local id内容=v.id
  local 点赞数=v.reaction.statistics.up_vote_count
  local 评论数=v.reaction.statistics.comment_count

  add.图像=图像
  add.标题=获取想法标题(标题)
  add.id内容=id内容
  add.点赞数=点赞数
  add.评论数=评论数

  table.insert(data,add)
end



function base.getAdapter(thinker_pagetool,pos)
  local data=thinker_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      holder=LuaCustRecyclerHolder(loadlayout(获取适配器项目布局("home/home_thinker"),views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      local 图像=data.图像

      loadglide(views.图像,图像)
      views.标题.Text=data.标题
      views.点赞数.Text=tostring(data.点赞数)
      views.评论数.Text=tostring(data.评论数)
      --子项目点击事件
      views.card.onClick=function(v)
        nTView=views.card
        newActivity("column",{data.id内容,"想法"})
        return true
      end

    end,
  }))
end

function base:initpage(view,sr)
  return MyPageTool2:new({
    view=view,
    sr=sr,
    head="head",
    adapters_func=self.getAdapter,
    func=self.resolvedata,
    allow_prev=true
  })
  :initPage()
  :createfunc()
  :setUrlItem("https://api.zhihu.com/prague/feed?offset=0&limit=10")
end

return base