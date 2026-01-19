--收藏事体类
--author dingyi
--time 2020-6-14
--self:对象本身
local base_collections={--表初始化
  isfollow=false
}

function base_collections:new(id)--类的new方法
  local child=table.clone(self)
  child.id=id
  return child
end

function base_collections:getData(callback)
  zHttp.get("https://api.zhihu.com/collections/"..self.id.."?with_deleted=1&censor=1",apphead
  ,function(code,content)
    if code==200 then
      local data=luajson.decode(content).collection
      callback(data)
    end
  end)
  return self
end

function base_collections:getUrl()
  return "https://api.zhihu.com/collections/"..self.id.."/contents?with_deleted=1&offset=0"
end

local function 多选菜单(data,v)

  local 类型
  local id=data.id内容:match("分割(.+)")
  if tostring(data.id内容):find("回答分割") then
    类型="answer"
   elseif tostring(data.id内容):find("文章分割") then
    类型="article"
   elseif tostring(data.id内容):find("想法分割") then
    类型="pin"
   elseif tostring(data.id内容):find("视频分割") then
    类型="zvideo"
  end

  local menu={

    {"取消收藏",function()
        双按钮对话框("取消收藏","取消收藏？该操作不可撤消！","是的","点错了",function(an)
          an.dismiss()
          zHttp.delete("https://api.zhihu.com/collections/"..collections_id.."/contents/"..id.."?content_type="..类型,head,function(code,json)
            if code==200 then
              提示("已删除 刷新生效")
            end
          end)
        end,function(an)an.dismiss()end)
    end},
    {"移动到其他收藏夹",function()
        加入收藏夹(id,类型,function(count)
          提示("移动成功 刷新生效")
        end)
    end},
  }


  local pop=showPopMenu(menu)
  pop.showAtLocation(rootview, Gravity.NO_GRAVITY, downx, downy);

  return true
end

function base_collections.resolvedata(v,data)
  local v=v.target or v
  local 点赞数,评论数,预览内容,标题,id分割
  if v.type=="answer" then
    点赞数=v.voteup_count..""
    评论数=v.comment_count..""
    预览内容=v.excerpt
    标题=v.question.title
    id分割=v.question.id.."回答分割"..v.id
   elseif v.type=="article" then
    点赞数=v.voteup_count..""
    评论数=v.comment_count..""
    预览内容=v.excerpt
    标题=v.title
    id分割="文章分割"..v.id
   elseif v.type=="pin" then
    预览内容=v.excerpt_title
    点赞数=v.collection_count..""
    评论数=v.comment_count..""
    标题="一个想法"
    id分割="想法分割"..v.id
   elseif v.type=="zvideo" then
    预览内容=v.excerpt_title
    点赞数=v.collection_count..""
    评论数=v.comment_count..""
    标题=v.title
    id分割="视频分割"..v.id
   else
    id分割="其他分割"..(v.target.id)
    标题=v.title
  end
  local add={}
  if 点赞数 then
    点赞数=tostring(点赞数)
   else
    点赞数="未知"
  end
  if 评论数 then
    评论数=tostring(评论数)
   else
    评论数="未知"
  end
  add.标题=标题
  add.点赞数=点赞数
  add.评论数=评论数
  add.id内容=id分割
  add.预览内容=预览内容
  table.insert(data,add)
end



function base_collections.getAdapter(collection_pagetool,pos)
  local data=collection_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      local holder=LuaCustRecyclerHolder(loadlayout(collection_item,views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      views.标题.Text=data.标题
      if data.点赞数 then
        views.点赞数.Text=data.点赞数
      end
      if data.评论数 then
        views.评论数.Text=data.评论数
      end
      views.预览内容.Text=data.预览内容

      views.card.onClick=function()
        点击事件判断(data.id内容,data.标题)
      end

      views.card.onTouch=function(v,event)
        downx=event.getRawX()
        downy=event.getRawY()
      end

      views.card.onLongClick=function(view)
        多选菜单(data,view)
      end

    end,
  }))
end

function base_collections:initpage(view,sr)
  return MyPageTool2:new({
    view=view,
    sr=sr,
    head="head",
    adapters_func=collections_base.getAdapter,
    func=collections_base.resolvedata
  })
  :initPage()
  :createfunc()
  :setUrlItem(collections_base:getUrl())
end

return base_collections