local base={}

function base:new(id,type)
  local child=table.clone(self)
  child.id=id
  child.type=type
  _peoplelist={}
  if child.type:find("follow") then
    _peoplelist.showtext=function(data)
      if data.is_following then
        return "取关";
       else
        return "关注";
      end
    end

    _peoplelist.onbind=function(views,data)
      local peopleid = data.id内容
      views.following.onClick=function()
        if views.following.Text=="关注"
          zHttp.post("https://api.zhihu.com/people/"..peopleid.."/followers","",posthead,function(a,b)
            if a==200 then
              views.following.Text="取关";
             elseif a==500 then
              提示("请登录后使用本功能")
            end
          end)
         elseif views.following.Text=="取关"
          zHttp.delete("https://api.zhihu.com/people/"..peopleid.."/followers/"..activity.getSharedData("idx"),posthead,function(a,b)
            if a==200 then
              views.following.Text="关注";
            end
          end)
         else
          提示("加载中")
        end
      end
    end

   elseif child.type:find("block") then
    _peoplelist.showtext=function(data)
      return "取消屏蔽"
    end
    _peoplelist.onbind=function(views,data)
      local peopleid = data.id内容
      views.following.onClick=function()
        if views.following.Text=="屏蔽" then
          zHttp.post("https://api.zhihu.com/settings/blocked_users","people_id="..peopleid,apphead,function(code,json)
            if code==200 or code==201 then
              views.following.Text="取消屏蔽";
            end
          end)
         elseif views.following.Text=="取消屏蔽" then
          zHttp.delete("https://api.zhihu.com/settings/blocked_users/"..peopleid,posthead,function(code,json)
            if code==200 then
              views.following.Text="屏蔽";
            end
          end)
         else
          提示("加载中")
        end
      end
    end
   elseif child.type:find("voter") then
    _peoplelist.showtext=function(data)
      if data.action_type=="like" then
        return "喜欢了";
       else
        --print(data.action_type)
        return "转发了";
      end
    end
    _peoplelist.onbind=function(views,data)

    end
  end
  return child
end

function base:getUrl(type)
  switch type
   case "voter"
    return "https://api.zhihu.com/pins/"..self.id.."/actions"
   case "followees"
    return "https://api.zhihu.com/people/"..self.id.."/followees?offset=0"
   case "followers"
    return "https://api.zhihu.com/people/"..self.id.."/followers?offset=0"
   case "block_all"
    return "https://api.zhihu.com/settings/blocked_users?filter=all"
   case "block_walle"
    return "https://api.zhihu.com/settings/blocked_users?filter=walle"
  end
end

function base.getAdapter(people_list_pagetool,pos)
  local data=people_list_pagetool:getItemData(pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #data
    end,

    getItemViewType=function(position)
      return 0
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      local holder=LuaCustRecyclerHolder(loadlayout(peopeo_list_item,views))
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local views=holder.view.getTag()
      local data=data[position+1]
      views.标题.text=data.标题
      views.预览内容.text=data.预览内容
      views.following.text=data.following
      loadglide(views.图像,data.图像)
      _peoplelist.onbind(views,data)
      views.card.onClick=function()
        newActivity("people",{data.id内容})
      end
    end,
  }))
end


function base.resolvedata(v,data)

  local 头像,名字,签名,用户id
  if v.type=="people" then
    头像=v.avatar_url
    名字=v.name
    签名=v.headline
    用户id=v.id
    if 签名=="" then
      签名="无签名"
    end
  end
  if v.type=="pin_action" then
    头像=v.member.avatar_url
    名字=v.member.name
    签名=v.member.headline
    用户id=v.member.id
    if 签名=="" then
      签名="无签名"
    end
  end
  local add={}
  add.id内容=用户id
  add.标题=名字
  add.图像=头像
  add.following=_peoplelist.showtext(v)
  add.预览内容=签名
  table.insert(data,add)
end

function base:initpage(view,sr)
  return MyPageTool2:new({
    view=view,
    sr=sr,
    head="head",
    adapters_func=self.getAdapter,
    func=self.resolvedata,
    urlfunc=function(geturl,head)
      --尝试解决bug
      if geturl:find("api.zhihu.com") then
        geturl=geturl:gsub("api/v4","")
      end
      return geturl,head
    end
  })
  :initPage()
  :createfunc()
  :setUrlItem(self:getUrl(self.type))
end

return base