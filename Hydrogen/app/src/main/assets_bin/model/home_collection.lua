local base={}

function base:new(id)--类的new方法
  local child=table.clone(self)
  child.id=id
  return child
end

function base:getData(callback)
  zHttp.get("https://api.zhihu.com/collections/"..self.id.."?with_deleted=1&censor=1",apphead
  ,function(code,content)
    if code==200 then
      local data=luajson.decode(content).collection
      callback(data)
    end
  end)
  return self
end

function base.getfuncs()
  return {
    function(v,data)
      local add={}
      add.标题=v.title
      add.is_lock=v.is_public==false and 图标("https") or nil
      add.预览内容=v.item_count.." 个内容"
      add.评论数=math.floor(v.comment_count)..""
      add.关注数=math.floor(v.follower_count).."人关注"
      add.id内容=tostring(v.id)
      table.insert(data,add)
    end,
    function(v,data)
      local 图片=v.creator.avatar_url
      local add={}
      add.图像=图片
      add.预览内容="由"..v.creator.name.."创建 "..v.item_count.."个内容"
      add.标题=v.title
      add.关注数=math.floor(v.follower_count).."人关注"
      add.id内容=tostring(v.id)
      table.insert(data,add)
    end
  }
end



function base.getAdapter(collection_pagetool,pos)
  local data=collection_pagetool:getItemData(pos)
  switch pos
   case 1
    return LuaCustRecyclerAdapter(AdapterCreator({

      getItemCount=function()
        return #data
      end,

      getItemViewType=function(position)
        return 0
      end,

      onCreateViewHolder=function(parent,viewType)
        local views={}
        holder=LuaCustRecyclerHolder(loadlayout(获取适配器项目布局("home/home_collections"),views))
        holder.view.setTag(views)
        return holder
      end,

      onBindViewHolder=function(holder,position)
        local views=holder.view.getTag()
        local data=data[position+1]

        views.标题.Text=data.标题
        if data.is_lock then
          views.is_lock.ImageBitmap=loadbitmap(data.is_lock)
        end

        views.预览内容.Text=data.预览内容
        views.评论数.Text=data.评论数
        views.关注数.Text=data.关注数
        views.card.onClick=function()
          nTView=views.card
          newActivity("collections",{data.id内容})
        end

      end,
    }))

   case 2
    return LuaCustRecyclerAdapter(AdapterCreator({

      getItemCount=function()
        if #data==0 then
          local add={}
          add.图像=logopng
          add.预览内容="为你推荐"
          add.标题="推荐关注收藏夹"
          add.关注数=""
          add.id内容="local"
          table.insert(data,add)
        end

        return #data
      end,

      getItemViewType=function(position)
        return 0
      end,

      onCreateViewHolder=function(parent,viewType)
        local views={}
        holder=LuaCustRecyclerHolder(loadlayout(获取适配器项目布局("home/home_shared_collections"),views))
        holder.view.setTag(views)
        return holder
      end,

      onBindViewHolder=function(holder,position)
        local views=holder.view.getTag()
        local data=data[position+1]

        views.标题.Text=data.标题
        if data.is_lock then
          views.is_lock.ImageBitmap=loadbitmap(data.is_lock)
        end

        views.预览内容.Text=data.预览内容
        views.关注数.Text=data.关注数
        loadglide(views.图像,data.图像)
        views.card.onClick=function()
          nTView=views.card
          if data.id内容=="local" then
            newActivity("collection_recommend")
            return
          end
          newActivity("collections",{data.id内容,true})
        end

      end,
    }))

  end

end

function base:initpage(view,tabview)
  return MyPageTool2:new({
    view=view,
    tabview=tabview,
    addcanclick=true,
    needlogin=true,
    head="head",
    adapters_func=self.getAdapter,
    funcs=self.getfuncs(),
  })
  :addPage(2,{"收藏","关注"})
  :createfunc()
  :setOnTabListener()
end

return base