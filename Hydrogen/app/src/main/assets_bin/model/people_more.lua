local base={}

function base:new(id,type)
  local child=table.clone(self)
  child.id=id
  child.type=type
  _peoplemore={}

  local type1=child.type
  if type1:find("视频合集") then
    if type1:find("详情") then
      _peoplemore.resolvedata=function(v)
        local 标题=v.title
        local 预览内容=v.description
        local 底部内容=v.play_count.."个播放"
        local id内容="视频分割"..v.id
        return {标题=标题,预览内容=预览内容,底部内容=底部内容,id内容=id内容}
      end
     else
      _peoplemore.resolvedata=function(v)
        local 标题=v.name
        local 预览内容=v.description
        local id内容="视频合集详情分割"..v.id
        local 底部内容=v.zvideo_count.."个视频 · "..v.voteup_count.."个赞同"
        return {标题=标题,预览内容=预览内容,底部内容=底部内容,id内容=id内容}
      end
    end
   elseif type1:find("专栏") then
    child.gettype="columns"
    _peoplemore.resolvedata=function(v)
      local 标题=v.title
      local 预览内容=v.description
      local id内容="专栏分割"..v.id
      local 底部内容=v.items_count.."篇内容 · "..v.voteup_count.."个赞同"
      return {标题=标题,预览内容=预览内容,底部内容=底部内容,id内容=id内容}
    end
   elseif type1:find("话题") then
    child.gettype="topics"
    simple_item[2][2][2][4]=nil
    _peoplemore.resolvedata=function(v)
      local 标题=v.name
      local 预览内容=v.excerpt
      local id内容="话题分割"..v.id
      return {标题=标题,预览内容=预览内容,id内容=id内容}
    end
   elseif type1:find("问题") then
    child.gettype="questions"
    --预览内容删除
    simple_item[2][2][2][3]=nil
    _peoplemore.resolvedata=function(v)
      local 标题=v.title
      local 链接="问题分割"..v.id
      local 底部内容=v.answer_count.."个回答 · "..v.follower_count.."个关注"
      local 预览内容
      return {标题=标题,底部内容=底部内容,id内容=链接}
    end

  end
  return child
end

function base:getUrl()
  local type1=self.type

  if type1:find("视频合集")
    if type1:find("详情") then
      return "https://api.zhihu.com/zvideo-collections/collections/"..self.id.."/include?offset=0&limit=10&include=answer"
     else
      return "https://api.zhihu.com/zvideo-collections/members/"..self.id.."/collections?offset=0&limit=10"
    end
   else
    return "https://api.zhihu.com/people/"..self.id.."/following_"..self.gettype.."?offset=0&limit=20"
  end
end

function base.getAdapter(people_more_pagetool,pos)
  local data=people_more_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      local holder=LuaCustRecyclerHolder(loadlayout(simple_item,views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      views.标题.text=data.标题

      if data.预览内容 then
        views.预览内容.text=data.预览内容
      end

      if data.底部内容 then
        views.底部内容.text=data.底部内容
      end

      views.card.onClick=function()
        点击事件判断(data.id内容)
      end
    end,
  }))
end


function base.resolvedata(v,data)
  local add=_peoplemore.resolvedata(v)
  table.insert(data,add)
end

function base:initpage(view,sr)
  return MyPageTool2:new({
    view=view,
    sr=sr,
    head="apphead",
    adapters_func=self.getAdapter,
    func=self.resolvedata,
  })
  :initPage()
  :createfunc()
  :setUrlItem(self:getUrl())
end

return base