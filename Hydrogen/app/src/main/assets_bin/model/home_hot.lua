local base={
  myhotdata={}
}

function base:new(id)--类的new方法
  local child=table.clone(self)
  return child
end

function base:getData(isclear,isinit)

  if isclear then
    table.clear(self.myhotdata)
    self.view.removeAllViews();
    self.view.getRecycledViewPool().clear();
    self.view.adapter.notifyDataSetChanged()
  end

  if isinit and self.view.adapter.getItemCount()>0 then
    return self
  end

  zHttp.get("https://www.zhihu.com/api/v3/feed/topstory/hot-lists/total?limit=50&mobile=true",head,function(code,content)
    self.sr.setRefreshing(false)
    if code==200 then--判断网站状态
      local data=luajson.decode(content).data

      for i,v in ipairs(data)
        local 排行=i
        local v=v.target
        local 热榜图片=v.image_area.url
        local 标题=v.title_area.text
        local 热度=v.metrics_area.text
        local id内容=v.link.url

        local add={}
        add.标题=标题
        add.热度=热度
        add.排行=排行
        add.id内容=id内容
        add.热图片={
          src=热榜图片,
          Visibility=#热榜图片>0 and 0 or 8
        }

        table.insert(self.myhotdata,add)

      end
      --notifyItemRangeInserted第一个参数是开始插入的位置 adp数据的下标是0 table下标是1 所以直接使用table的长度即可
      self.view.adapter.notifyItemRangeInserted(0,#self.myhotdata)
     else
      --错误时的操作
    end
  end)
end

function base:getAdapter(home_pagetool,pos)
  return LuaCustRecyclerAdapter(AdapterCreator({

    getItemCount=function()
      return #self.myhotdata
    end,

    getItemViewType=function(position)
      local data=self.myhotdata[position+1]
      if data.热图片.Visibility==0 then
        return 0
       else
        return 1
      end
    end,

    onCreateViewHolder=function(parent,viewType)
      local views={}
      holder=LuaCustRecyclerHolder(loadlayout(获取适配器项目布局("home/home_hot"),views))
      if viewType==1 or activity.getSharedData("热榜关闭图片")=="true" then
        views.热图片布局.getParent().removeView(views.热图片布局)
        views.热图片布局=nil
      end
      if activity.getSharedData("热榜关闭热度")=="true" then
        views.热度.getParent().removeView(views.热度)
        views.热度=nil
      end
      holder.view.setTag(views)
      return holder
    end,

    onBindViewHolder=function(holder,position)
      local view=holder.view.getTag()
      local data=self.myhotdata[position+1]
      view.标题.text=data.标题
      if view.热度 then
        view.热度.text=tostring(data.热度)
      end
      view.排行.text=tostring(data.排行)

      view.card.onClick=function()
        检查链接(data.id内容)
      end

      if view.热图片 then
        loadglide(view.热图片,data.热图片.src)
      end

    end,
  }))

end

function base:initpage(view,sr)
  self.view=view
  self.sr=sr
  view.setAdapter(self:getAdapter())
  --自定义LinearLayoutManager尝试解决闪退问题
  local MyLinearLayoutManager=luajava.bindClass("com.hydrogen.MyLinearLayoutManager")(this,RecyclerView.VERTICAL,false)
  view.setLayoutManager(MyLinearLayoutManager)

  sr.setProgressBackgroundColorSchemeColor(转0x(backgroundc));
  sr.setColorSchemeColors({转0x(primaryc)});
  sr.setOnRefreshListener({
    onRefresh=function()
      self:getData(true)
    end,
  });


  return self
end

return base