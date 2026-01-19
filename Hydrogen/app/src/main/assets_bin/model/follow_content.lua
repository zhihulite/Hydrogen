local base={}

function base:new(id)--类的new方法
  local child=table.clone(self)
  child.id=id
  return child
end

function base.getfuncs()
  return {
    --问题
    function (v,data)
      local add={}
      local 标题=v.title
      local id内容="问题分割"..v.id
      local 底部内容=v.answer_count.."个回答 · "..v.follower_count.."个关注"
      add.id内容=id内容
      add.标题=标题
      add.底部内容=底部内容
      table.insert(data,add)
    end,
    --收藏夹
    function(v,data)
      local add={}
      local 图片
      图片=v.creator.avatar_url
      local add={}
      add.图像=图片
      add.预览内容="由 "..v.creator.name.." 创建"
      add.标题=v.title
      add.关注数=math.floor(v.follower_count).."人关注"
      add.id内容=tostring(v.id)
      table.insert(data,add)
    end,
    --话题
    function (v,data)
      local 标题=v.name
      local 预览内容=v.excerpt
      if 预览内容==false or 预览内容=="" then
        预览内容="无介绍"
      end
      local add={}
      add.预览内容=预览内容
      add.标题=标题
      add.id内容="话题分割"..v.id
      table.insert(data,add)
    end,
    --专栏
    function (v,data)
      local 标题=v.title
      local 预览内容=v.description
      local id内容="专栏分割"..v.id
      local 底部内容=v.items_count.."篇内容 · "..v.voteup_count.."个赞同"
      if 预览内容==false or 预览内容=="" then
        预览内容="无介绍"
      end
      local add={}
      add.预览内容=预览内容
      add.标题=标题
      add.id内容=id内容
      add.底部内容=底部内容
      table.insert(data,add)
    end,
    --用户
    function (v,data)
      if v.type=="people" then
        local 头像=v.avatar_url
        local 名字=v.name
        local 签名=v.headline
        local 用户id=v.id
        local 文本
        if 签名=="" then
          签名="无签名"
        end
        if v.is_following then
          文本="取关";
         else
          文本="关注";
        end
        local add={}
        add.标题=名字
        add.id内容=用户id
        add.图像=头像
        add.预览内容=签名
        table.insert(data,add)
      end
    end,
    --专题
    function(v,data)
      local 标题=v.title
      local 预览内容=v.subtitle.content
      local url=v.url
      local id内容="专题分割"..url:match("special/(.+)")
      local 底部内容=v.footline.content
      if 预览内容==false or 预览内容=="" then
        预览内容="无介绍"
      end
      local add={}
      add.标题=标题
      add.id内容=id内容
      add.图像=头像
      add.预览内容=预览内容
      add.底部内容=底部内容
      table.insert(data,add)
    end,
    --圆桌
    function(v,data)
      local 标题=v.title
      local 预览内容=v.subtitle.content
      local url=v.url
      local id内容="圆桌分割"..url:match("roundtable/(.+)")
      local 底部内容=v.footline.content
      if 预览内容==false or 预览内容=="" then
        预览内容="无介绍"
      end
      local add={}
      add.标题=标题
      add.id内容=id内容
      add.预览内容=预览内容
      add.底部内容=底部内容
      table.insert(data,add)
    end
  }
end



function base.getAdapter(followcontent_pagetool,pos)
  local data=followcontent_pagetool:getItemData(pos)
  local itemc=table.clone(获取适配器项目布局("simple/card"))
  local onclick=function(data)
    点击事件判断(data.id内容)
  end
  switch pos
   case 1
    --预览内容删除
    itemc[2][2][2][3]=nil
   case 2
    itemc=获取适配器项目布局("home/home_shared_collections")
    onclick=function(data)
      if data.id内容=="local" then
        newActivity("collection_recommend")
        return
      end
      newActivity("collections",{data.id内容,true})
    end
   case 3
    itemc[2][2][2][4]=nil
   case 5
    itemc=获取适配器项目布局("people/people_list")
    onclick=function(data)
      newActivity("people",{data.id内容})
    end
  end


  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      if pos==2 and #data==0 then
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
      holder=LuaCustRecyclerHolder(loadlayout(itemc,views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      views.标题.Text=data.标题

      views.card.onClick=function()
        nTView=views.card
        onclick(data)
      end
      if data.底部内容 then
        views.底部内容.Text=data.底部内容
      end
      if data.图像 then
        loadglide(views.图像,data.图像)
      end
      if data.预览内容 then
        views.预览内容.Text=data.预览内容
      end
      if views.following then
        views.following.Text="取关"
        views.following.onClick=function(view)
          local 用户id=data.id内容
          if view.Text=="关注"
            zHttp.post("https://api.zhihu.com/people/"..用户id.."/followers","",posthead,function(a,b)
              if a==200 then
                view.Text="取关";
                提示("关注成功")
               elseif a==500 then
                提示("请登录后使用本功能")
              end
            end)
           elseif view.Text=="取关"
            zHttp.delete("https://api.zhihu.com/people/"..用户id.."/followers/"..activity.getSharedData("idx"),posthead,function(a,b)
              if a==200 then
                view.Text="关注";
                提示("取关成功")
              end
            end)
           else
            提示("加载中")
          end
        end
      end

    end,
  }))
end

function base:initpage(view,tabview)
  return MyPageTool2:new({
    view=view,
    tabview=tabview,
    addcanclick=true,
    needlogin=true,
    head="apphead",
    adapters_func=self.getAdapter,
    funcs=self.getfuncs()
  })
  :addPage(2,{"问题","收藏夹","话题","专栏","用户","专题","圆桌"})
  :createfunc()
  :setOnTabListener()
end

return base