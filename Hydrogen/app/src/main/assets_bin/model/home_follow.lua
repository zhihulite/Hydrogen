local base={}

function base:new(id)--类的new方法
  local child=table.clone(self)
  child.id=id
  return child
end

local function resolve_moments_feed(v,data)
  local 头像
  local 作者名称=v.source.actor.name
  local 动作=作者名称..v.source.action_text
  local 时间=时间戳(v.source.action_time)
  xpcall(function()
    头像=v.target.author.avatar_url
    end,function()
    头像=v.source.actor.avatar_url
  end)
  local v=v.target or v
  local 点赞数=v.voteup_count
  local 评论数=v.comment_count
  local 标题=v.title or v.excerpt_title
  local 预览内容=v.excerpt
  local id内容
  local add={}
  if v.type=="answer" then
    id内容=v.question.id or "null"
    id内容=id内容.."分割"..v.id
    标题=v.question.title
   elseif v.type=="question" then
    id内容="问题分割"..v.id
    标题=v.title
   elseif v.type=="article" then
    id内容="文章分割"..v.id
    标题=v.title
   elseif v.type=="moments_pin" or v.type=="pin" then
    if 标题==nil or 标题=="" then
      标题="一个想法"
    end
    id内容="想法分割"..v.id
    点赞数=v.reaction_count
    if #v.content>0 then
      预览内容=v.content[1].content
     else
      预览内容="无"
    end
    if 预览内容=="" then
      if v.content[2].type=="image" then
        预览内容="[图片]"
      end
    end
   elseif v.type=="zvideo" then
    id内容="视频分割"..v.id
    标题=v.title
    if 预览内容==nil or 预览内容=="" then
      预览内容="[视频]"
    end
   elseif v.type=="moments_drama" then
    id内容="直播分割"..v.id
    标题=v.title
    if 预览内容==nil or 预览内容=="" then
      预览内容="[直播]"
    end
   elseif v.type=="topic" then
    id内容="话题分割"..v.id
  end
  if 预览内容 then
    if 预览内容~="[视频]" then
      预览内容=作者名称.." : "..预览内容
    end
   else
    预览内容=nil
  end
  if 点赞数 then
    点赞数=tostring(点赞数)
   else
    点赞数=""
  end
  if 评论数 then
    评论数=tostring(评论数)
   else
    评论数=nil
  end
  add.点赞数=点赞数
  add.标题=标题
  if 预览内容 then
    add.预览内容=Html.fromHtml(预览内容)
  end
  add.评论数=评论数
  add.id内容=id内容
  add.动作=动作
  add.时间=时间
  add.图像=头像
  if data then
    table.insert(data,add)
  end
  return add
end

local function resolve_feed_item_index_group(v,data)

  local 头像,名称,动作

  --针对item_group_card的支持
  if v.actors then
    头像=v.actors[1].avatar_url
    名称=v.actors[1].name
    动作=名称..v.action_text
  end

  local 时间=时间戳(v.action_time)
  local v=v.target or v
  -- 示例 12345万 赞同 · 67890 收藏 · 123456 评论
  local 数据=get_number_and_following(v.desc)
  local 点赞数=数据[1]
  local 评论数=数据[3]
  local 标题=v.title
  local 预览内容=v.digest
  local 作者名称=v.author
  local id内容
  local add={}
  if v.type=="answer" then
    id内容="null"
    id内容=id内容.."分割"..v.id
    标题=v.title
   elseif v.type=="question" then
    id内容="问题分割"..v.id
    标题=v.title
   elseif v.type=="article" then
    id内容="文章分割"..v.id
    标题=v.title
   elseif v.type=="moments_pin" or v.type=="pin" then
    id内容="想法分割"..v.id
    标题=v.excerpt_title
    if 标题==nil or 标题=="" then
      标题="一个想法"
    end
   elseif v.type=="zvideo" then
    id内容="视频分割"..v.id
    标题=v.title
    if 预览内容==nil or 预览内容=="" then
      预览内容="[视频]"
    end
   elseif v.type=="drama" then
    id内容="直播分割"..v.id
    标题=v.title
    if 预览内容==nil or 预览内容=="" then
      预览内容="[直播]"
    end
   elseif v.type=="topic" then
    id内容="话题分割"..v.id
   elseif v.type=="people" then
    --不打算支持用户推荐
    return false
  end
  if 预览内容 then
    if 预览内容~="[视频]" then
      local 名称= v.author or 名称
      预览内容=名称.." : "..预览内容
    end
   else
    预览内容=nil
  end
  if 点赞数 then
    点赞数=tostring(点赞数)
   else
    点赞数=""
  end
  if 评论数 then
    评论数=tostring(评论数)
   else
    评论数=nil
  end
  add.点赞数=点赞数
  add.标题=标题
  if 预览内容 then
    add.预览内容=Html.fromHtml(预览内容)
  end
  add.评论数=评论数
  add.id内容=id内容
  add.动作=动作
  add.时间=时间
  add.图像=头像
  if data then
    table.insert(data,add)
  end
  return add
end

function base.resolvedata(v,data)
  local type1=v.type
  switch type1
   case "moments_feed"
    resolve_moments_feed(v,data)
   case "feed_item_index_group"
    resolve_feed_item_index_group(v,data)
   case "item_group_card"
    local 头像=v.actor.avatar_url
    local 名称=v.actor.name
    local 动作=名称..v.action_text
    local 时间=时间戳(v.action_time)
    local 组文本=v.group_text
    local temptable={}
    for _,v2 in ipairs(v.data) do
      if resolve_feed_item_index_group(v2,temptable)==false then
        return
      end
    end
    local add={}
    add.图像=头像
    add.名称=名称
    add.动作=动作
    add.时间=时间
    add.组文本=组文本
    --table.remove会立即返回被删除的元素
    for k, v in pairs(table.remove(temptable,1)) do
      add[k] = v
    end
    -- 将剩余的键值对放入 extra_data 表中
    add.extra_data = {}
    for k, v in pairs(temptable) do
      add.extra_data[k] = v
    end

    if #add.extra_data>0 then
      add.type=1
    end

    table.insert(data,add)
   case "recommend_user_card_list"
    --推荐关注用户 不打算支持
   case "moments_recommend_followed_group"
    local 组文本=v.group_text
    --目前只会推送一个 所以暂时这么写
    local add=resolve_moments_feed(v.list[1])
    add.组文本=组文本
    add.type=2
    table.insert(data,add)
   default
    return false
  end
end

MaterialDivider=luajava.bindClass "com.google.android.material.divider.MaterialDivider"

local function 加载主页关注折叠adp(data,views)
  --创建第二个适配器对象
  local adapter2=LuaRecyclerAdapter(activity,data,获取适配器项目布局("home/hone_follow_carditem"))
  adapter2.setAdapterInterface(LuaRecyclerAdapter.AdapterInterface{
    onBindViewHolder=function(holder,position)
      local views=holder.getTag()
      local data=data[position+1]

      local 标题=data.标题
      local 预览内容=data.预览内容
      local 评论数=data.评论数
      local 点赞数=data.点赞数
      local id内容=data.id内容

      if 预览内容 then
        views.预览内容.Visibility=0
        views.预览内容.text=预览内容
       else
        views.预览内容.Visibility=8
      end

      views.标题.text=标题
      views.点赞数.text=点赞数
      if 评论数 then
        views.评论数布局.Visibility=0
        views.评论数.text=评论数
       else
        views.评论数布局.Visibility=8
      end
      views.card.onClick=function()
        nTView=views.card
        点击事件判断(data.id内容,data.标题)
      end
    end,
  })
  --自定义LinearLayoutManager尝试解决闪退问题
  local MyLinearLayoutManager=luajava.bindClass("com.hydrogen.MyLinearLayoutManager")(this,RecyclerView.VERTICAL,false)
  views.底部recy.setLayoutManager(MyLinearLayoutManager)
  views.底部recy.setAdapter(adapter2)
  addAutoHideListener({views.底部recy},{bottombar})

end

function base.getAdapter(follow_pagetool,pos)
  local data=follow_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      local data=data[position+1]
      return data.type or 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      switch viewType
       case 3
       default
        holder=LuaCustRecyclerHolder(loadlayout(获取适配器项目布局("home/home_following"),views))
      end
      switch viewType
       case 0
        views.顶部文字.getParent().removeView(views.顶部文字)
        views.底部recy.getParent().removeView(views.底部recy)
        views.顶部文字=nil
        views.底部recy=nil
       case 1
        views.顶部文字.getParent().removeView(views.顶部文字)
        views.顶部文字=nil
       case 2
        views.底部recy.getParent().removeView(views.底部recy)
        views.底部recy=nil
      end
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      local type1=data.type

      local 标题=data.标题
      local 预览内容=data.预览内容
      local 评论数=data.评论数
      local 点赞数=data.点赞数
      local id内容=data.id内容

      views.标题.Text=data.标题
      views.点赞数.Text=data.点赞数
      if 评论数 then
        views.评论数布局.Visibility=0
        views.评论数.text=评论数
       else
        views.评论数布局.Visibility=8
      end

      if 预览内容 then
        views.预览内容.Visibility=0
        views.预览内容.text=预览内容
       else
        views.预览内容.Visibility=8
      end

      views.动作.Text=data.动作.." · "..data.时间
      loadglide(views.图像,data.图像)

      switch type1
       case 1
        local data=data.extra_data
        加载主页关注折叠adp(data,views)
       case 2
        local text=data.组文本
        views.顶部文字.text=text
      end

      --子项目点击事件
      views.card.onClick=function(v)
        nTView=views.card
        点击事件判断(data.id内容,data.标题)
      end

    end,
  }))
end

function base:initpage(view,tabview)
  followhead = table.clone(apphead)
  followhead["x-moments-ab-param"] = "follow_tab=1";
  local pagetool=MyPageTool2:new({
    view=view,
    tabview=tabview,
    addcanclick=true,
    needlogin=true,
    head="followhead",
    adapters_func=self.getAdapter,
    func=self.resolvedata,
    urls={
      "https://api.zhihu.com/moments_v3?feed_type=recommend",
      "https://api.zhihu.com/moments_v3?feed_type=timeline",
      "https://api.zhihu.com/moments_v3?feed_type=pin"
    }
  })
  :addPage(2,{"精选","最新","想法"},this.getSharedData("startfollow"))
  :createfunc()
  :setOnTabListener()

  return pagetool
end

return base