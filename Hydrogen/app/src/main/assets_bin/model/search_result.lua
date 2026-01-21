local base={}

function base:new(str,type,id)
  local child=table.clone(self)
  child.str=str
  child.type=type
  child.id=id
  return child
end

function base:getUrl()
  local type=self.type
  local str=self.str
  local id=self.id
  switch type
   case "people"
    return "https://www.zhihu.com/api/v4/search_v3?correction=1&t=general&q="..urlEncode(str).."&restricted_scene=member&restricted_field=member_hash_id&restricted_value="..id
   case "collection"
    return "https://www.zhihu.com/api/v4/search_v3?gk_version=gz-gaokao&q="..urlEncode(str).."&t=favlist&lc_idx=0&correction=1&offset=0&advertCount=0&limit=20&is_real_time=0&show_all_topics=0&search_source=History&filter_fields=&city=&pin_flow=false&ruid=undefined&recq=undefined&is_merger=1&raw_query=page_source%3Dmy_collection"
  end
end

function base.getAdapter(search_result_pagetool,pos)
  local data=search_result_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      local holder=LuaCustRecyclerHolder(loadlayout(search_result_item,views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      views.活动.text=data.活动
      views.标题.text=data.标题
      views.点赞数.text=data.点赞数
      views.评论数.text=data.评论数
      views.预览内容.text=data.预览内容
      views.card.onClick=function()
        nTView=views.card
        点击事件判断(data.id内容,data.标题,data.testdata)
      end
    end,
  }))
end


function base.resolvedata(v,data)

  local 活动,id内容,标题
  local v=v.object or v
  local 预览内容=v.excerpt
  local 点赞数=v.voteup_count
  local 评论数=v.comment_count
  local 标题=v.excerpt_title or v.title
  if v.type=="answer" then
    活动="添加了问题"
    local 问题id=v.question.id or "null"
    id内容=问题id.."分割"..v.id
   elseif v.type=="topic" then
    活动="添加了话题"
    id内容="话题分割"..v.id
    标题=v.name
   elseif v.type=="question" then
    活动="添加了问题"
    id内容=v.id.."问题分割"
   elseif v.type=="column" then
    活动="添加了专栏"
    id内容="专栏分割"..v.id
    评论数=v.items_count
   elseif v.type=="pin" or v.type=="pin_general" then
    活动="添加了想法"
    id内容="想法分割"..v.id
    预览内容=v.content[1].content
    点赞数=v.like_count
   elseif v.type=="zvideo" then
    活动="添加了视频"
    id内容="视频分割"..v.id
   else
    活动="添加了文章"
    id内容="文章分割"..v.id
  end

  local add={}
  add.id内容=id内容
  add.标题=Html.fromHtml(标题)
  add.图像=头像
  if 预览内容 then
    add.预览内容=Html.fromHtml(预览内容)
   else
    add.预览内容="无"
  end
  if 评论数 then
    add.评论数=评论数..""
   else
    add.评论数=""
  end
  if 点赞数 then
    add.点赞数=点赞数..""
   else
    add.点赞数=""
  end
  add.活动=活动
  add.testdata=v
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
end

return base