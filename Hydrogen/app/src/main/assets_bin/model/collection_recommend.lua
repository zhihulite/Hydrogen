local base={}

function base:new()
  local child=table.clone(self)
  return child
end

function base:getUrl()
  return "https://api.zhihu.com/explore/collections?offset=20"
end

function base.getAdapter(collection_recommend_pagetool,pos)
  local data=collection_recommend_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      local holder=LuaCustRecyclerHolder(loadlayout(collection_recommend_item,views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      views.标题.text=data.标题
      views.预览内容.text=data.预览内容
      views.底部内容.text=data.底部内容
      views.活动.text=data.活动
      loadglide(views.图像,data.图像)
      views.card.onClick=function()
        nTView=views.card
        newActivity("collections",{data.id内容}) end
    end,
  }))
end


function base.resolvedata(v,data)

  if v.type~="collection" then
    return
  end
  local 头像=v.creator.avatar_url
  local 标题=v.title
  local 内容数量=v.item_count
  local 关注数=v.follower_count
  local 预览内容=v.description
  local 是否关注=v.is_following
  local 底部内容=内容数量.."个内容 · "..关注数.."个关注"
  if 是否关注 then
    底部内容=底部内容.." 已关注"
  end
  local 活动="由 "..v.creator.name.." 创建"
  local id=v.id
  if 预览内容==false or 预览内容=="" then
    预览内容="无介绍"
  end

  local add={}
  add.活动=活动
  add.预览内容=预览内容
  add.底部内容=底部内容
  add.标题=标题
  add.图像=头像
  add.id内容=id..""
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