local base={
  nextUrl=nil,
  is_end=false,
  data={},
}

function base:new(id)
  local child=table.clone(self)
  child.id=id
  return child
end

function base:getData(callback)
  local include='?include=voteup_count%2Cfollower_count%2Cfollowing_count%2Cis_following'
  local url="https://www.zhihu.com/api/v4/members/"..self.id..include
  zHttp.get(url,head,function(code,content)
    if code==200 then
      local data=luajson.decode(content)
      self.id=data.id
      self.url_token=data.url_token
      callback(data,self)
     elseif luajson.decode(content).error then
      提示(luajson.decode(content).error.message)
      callback(false)
    end
  end)
  return self
end

function base.getAdapter(people_pagetool,pos)
  local data=people_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return data[position+1].type or 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      local holder=LuaCustRecyclerHolder(loadlayout(people_itemc,views))
      switch viewType
       case 1
        views.点赞数布局.getParent().removeView(views.点赞数布局)
        views.点赞数布局=nil
        views.评论图标.layoutParams.leftMargin=0
       case 2
        views.评论数布局.getParent().removeView(views.点赞数布局)
        views.评论数布局=nil
       case 3
        views.底部内容.getParent().removeView(views.底部内容)
        views.底部内容=nil
      end
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]

      views.活动.Text=data.活动
      if data.预览内容 then
        views.预览内容.Visibility=0
        views.预览内容.text=data.预览内容
       else
        views.预览内容.Visibility=8
      end
      if data.点赞数 then
        views.点赞数.Text=data.点赞数
      end
      if data.评论数 then
        views.评论数.Text=data.评论数
      end
      views.标题.Text=data.标题

      loadglide(views.图像,data.图像)

      views.card.onClick=function()
        if tostring(data.id内容):find("更多") then
          local id内容=data.id内容:gsub("更多","")
          newActivity("people_more",{用户id,id内容})
         else
          点击事件判断(data.id内容,data.标题)
        end
      end
    end,
  }))
end

function base.resolvedata(v,data)
  --针对more的支持
  if v.more_tabs then
    for i,v in ipairs(v.more_tabs) do
      local 头像=大头像
      local 活动="的更多"
      local 标题=v.title
      local id内容="更多"..v.title
      local 添加字符串
      if v.sub_title then
        添加字符串="共有"..v.sub_title.."个内容 "
        if v.sub_title=="" then
          添加字符串=""
        end
       else
        添加字符串=""
      end
      local 预览内容=添加字符串.."点击查看"
      local 点赞数="0"
      local 评论数="0"
      local add={}
      add.活动=活动
      add.预览内容=预览内容
      add.点赞数=点赞数
      add.评论数=评论数
      add.id内容=id内容
      add.标题=标题
      add.图像=头像
      table.insert(data,add)
    end
    return
  end

  --针对columm的支持
  if v.column then
    v=v.column
  end

  local 活动=v.action_text
  local 头像=大头像
  xpcall(function()
    头像=v.actor.avatar_url
    end,function()
    头像=v.author.avatar_url
  end)

  if v.source then
    头像=v.source.actor.avatar_url
    活动=v.source.action_text
  end

  local v=v.target or v
  头像=头像 or v.author.avatar_url
  local 预览内容=v.excerpt
  local 点赞数=v.voteup_count
  local 评论数=v.comment_count
  local id内容,标题

  local add={}
  if v.type=="answer" then
    id内容=(v.question.id) or "null"
    id内容=id内容.."分割"..(v.id)
    标题=v.question.title
    活动=活动 or "发布了回答"
   elseif v.type=="topic" then
    预览内容="无预览内容"
    id内容="话题分割"..v.id
    标题=v.name
    活动=活动 or "发布了话题"
   elseif v.type=="question" then
    id内容="问题分割"..(v.id)
    标题=v.title
    预览内容="无预览内容"
    活动=活动 or "发布了问题"
   elseif v.type=="column" then
    id内容="专栏分割"..v.id
    评论数=v.items_count
    标题=v.title
    预览内容=v.intro
    活动=活动 or "发布了专栏"
   elseif v.type=="collection" then
    return
   elseif v.type=="pin" or v.type=="moments_pin" then
    id内容="想法分割"..tostring(v.id)
    local title=v.content[1].title
    if #v.content>0 and title and title~="" then
      标题=v.content[1].title
     else
      标题="一个想法"
    end
    预览内容=v.content_html
    点赞数=v.like_count
    活动=活动 or "发布了想法"
   elseif v.type=="article" then
    id内容="文章分割"..(v.id)
    标题=v.title
    活动=活动 or "发布了文章"
   elseif v.type=="zvideo" then
    id内容="视频分割"..v.id
    标题=v.title
    活动=活动 or "发布了视频"
   elseif v.type=="roundtable" then
    id内容="圆桌分割"..v.id
    标题=v.name
    活动=活动 or "关注了圆桌"
    预览内容=v.description
   elseif v.type=="special" then
    id内容="专题分割"..v.id
    标题=v.title
    活动=活动 or "关注了专题"
    预览内容=v.description
   else
    标题="未知"
    活动="未知"
  end
  if not 预览内容 or 预览内容=="" or 预览内容=="无预览内容" then
    预览内容=nil
   else
    预览内容=Html.fromHtml(预览内容)
  end

  if 点赞数 then
    点赞数=tostring(点赞数)
   else
    add.type=1
  end

  if 评论数 then
    评论数=tostring(评论数)
   else
    add.type=2
  end

  if not 点赞数 and not 评论数 then
    add.type=3
  end

  add.活动=活动
  add.预览内容=预览内容
  add.点赞数=点赞数
  add.评论数=评论数
  add.id内容=id内容
  add.标题=标题
  add.图像=头像
  table.insert(data,add)
end

-- 根据用户ID构造各类标签对应的URL配置
function base:getUrls()
  local people_id = self.id
  local url_token=self.url_token
  return {
    activities = "https://www.zhihu.com/api/v3/moments/" .. people_id .. "/activities?limit=20",
    zvideo = "https://www.zhihu.com/api/v4/members/" .. url_token .. "/zvideos?offset=0&limit=20",
    answer = "https://www.zhihu.com/api/v4/members/" .. people_id .. "/answers?order_by=created&offset=0&limit=20",
    vote = "https://api.zhihu.com/moments/" .. people_id .. "/vote?limit=20",
    more = "https://api.zhihu.com/people/" .. people_id .. "/profile/tab/more?tab_type=1",
    article = "https://www.zhihu.com/api/v4/members/" .. url_token .. "/articles?offset=0&limit=20",
    column = "https://www.zhihu.com/api/v4/members/"..url_token.."/column-contributions?offset=0&limit=20",
    pin = "https://api.zhihu.com/v2/pins/" .. people_id .. "/moments",
    question = "https://api.zhihu.com/people/" .. people_id .. "/questions?offset=0&limit=20",
  }
end

-- 处理标签数据方法
-- 输入：标签名称列表和标签信息列表
-- 处理过程：遍历标签信息，匹配预置URL（如无则取接口返回的URL），同时将"动态"（activities）标签置顶
-- 返回：最终的标签名称、对应的URL列表，以及答案标签(answer)的位置索引（如果存在的话）
function base:processTabs(tabNames, tabInfos)
  local urls = self:getUrls()
  local finalNames = {}
  local finalUrls = {}
  local answerIndex
  local activitiesIndex

  -- 遍历所有标签数据
  for i, info in ipairs(tabInfos) do
    local key = info.key
    local url = urls[key] or info.url
    if url then
      table.insert(finalNames, tabNames[i])
      table.insert(finalUrls, url)
      if key == "activities" then
        activitiesIndex = #finalUrls
       elseif key == "answer" then
        answerIndex = #finalUrls
      end
    end
  end

  -- 如果存在 "动态" 标签且不在第一个，则移动到第一位
  if activitiesIndex and activitiesIndex > 1 then
    local actName = table.remove(finalNames, activitiesIndex)
    local actUrl = table.remove(finalUrls, activitiesIndex)
    table.insert(finalNames, 1, actName)
    table.insert(finalUrls, 1, actUrl)
    -- 如果答案标签存在，简单处理下索引关系（这里只做简单调整，实际需要根据具体需求调整）
    if answerIndex then
      if activitiesIndex < answerIndex then
        answerIndex = answerIndex - 1
       elseif activitiesIndex > answerIndex then
        answerIndex = answerIndex + 1
      end
    end
  end

  -- 若列表为空，默认返回"动态"标签
  if #finalNames == 0 then
    finalNames = {"动态"}
    finalUrls = {urls["activities"]}
    answerIndex = nil
  end

  return finalNames, finalUrls, answerIndex
end

-- 辅助方法：根据单个标签数据过滤并处理标签名称（例如排除“全部”标签）
local function collectTabData(v, names, infos)
  if v.name == "全部" or v.key == "all" then
    return
  end
  local tabName = v.name
  if v.number and v.number > 0 then
    tabName = tabName .. " " .. tostring(v.number)
  end
  table.insert(names, tabName)
  table.insert(infos, { key = v.key, url = v.url })
end

-- 获取标签数据主方法，调用HTTP接口后解析返回的JSON数据
-- 回调函数 callback(self, finalNames, finalUrls, answerIndex)
function base:getTabs(callback)
  -- 如果未登录，则直接返回默认的“动态”标签
  if not getLogin() then
    local defaultUrl = self:getUrls().activities
    callback(self, {"动态"}, {defaultUrl}, nil)
    return self
  end

  local names = {}
  local infos = {}
  local url = "https://api.zhihu.com/people/" .. self.id .. "/profile/tab"
  zHttp.get(url, apphead, function(code, content)
    if code == 200 then
      local data = luajson.decode(content)
      local tabs = data.tabs_v3 or {}
      for _, tab in ipairs(tabs) do
        if tab.sub_tab then
          for _, sub in ipairs(tab.sub_tab) do
            collectTabData(sub, names, infos)
          end
         else
          collectTabData(tab, names, infos)
        end
      end
      local finalNames, finalUrls, answerIndex = self:processTabs(names, infos)
      callback(self, finalNames, finalUrls, answerIndex)
    end
  end)
  return self
end

function base:initpage(view,tabview)
  return MyPageTool2:new({
    view=view,
    tabview=tabview,
    addcanclick=true,
    needlogin=false,
    head="apphead",
    adapters_func=self.getAdapter,
    func=self.resolvedata
  })

end

return base