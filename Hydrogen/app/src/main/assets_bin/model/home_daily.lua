local base={
  日报data={},
  可以加载日报=true,
  thisdata=0,
  news={},
  ZUOTIAN=nil,
  needcheck=true
}

function base:new(id)--类的new方法
  local child=table.clone(self)
  return child
end

local function checkIfRecyclerViewIsFullPage(recyclerView)
  local layoutManager = recyclerView.getLayoutManager();
  local lastVisiblePosition = layoutManager.findLastVisibleItemPosition();
  local totalItemCount = recyclerView.getAdapter().getItemCount();
  if lastVisiblePosition >= totalItemCount - 1 then
    return true;
  end
  return false;
end

function base:getData(isclear,isinit)

  if isinit and self.view.adapter.getItemCount()>0 then
    return self
  end

  local ZUOTIAN=self.ZUOTIAN
  local thisdata=self.thisdata
  local 日报adp=self.view.adapter

  if ZUOTIAN==nil then
    self.链接 = "https://news-at.zhihu.com/api/4/stories/latest"
    self.ZUOTIAN = true
   else
    thisdata=thisdata-1
    import "android.icu.text.SimpleDateFormat"
    local cal=Calendar.getInstance();
    cal.add(Calendar.DATE,thisdata);
    local d=cal.getTime();
    local sp= SimpleDateFormat("yyyyMMdd");
    local ZUOTIAN=sp.format(d);
    self.链接 = 'https://news-at.zhihu.com/api/4/stories/before/'..tostring(ZUOTIAN)
  end
  self.可以加载日报=false
  zHttp.get(self.链接,head,function(code,content)
    if code==200 then
      self.可以加载日报=true

      local function updateData()
        if isclear then
          self.thisdata=0
          self.news={}
          self.ZUOTIAN=true
          self.needcheck=true
          table.clear(self.日报data)
          self.view.removeAllViews();
          self.view.getRecycledViewPool().clear();
        end

        self.thisdata=thisdata

        if self.needcheck then
          --延迟 防止获取不准确
          self.view.postDelayed(Runnable{
            run=function()
              if checkIfRecyclerViewIsFullPage(self.view) then
                if self.canload_more then
                  self:getData()
                  System.gc()
                end
               else
                self.needcheck=false
              end
            end
          }, 50);
        end

        if self.thisdata==0 then
          self.newnews=content
         elseif self.thisdata==-1 then
          if content==self.newnews
            return
          end
        end

        local old_size=#self.日报data
        for k,v in ipairs(luajson.decode(content).stories) do
          local add={}
          add.标题=v.title
          add.id内容=v.url
          table.insert(self.日报data,add)
        end
        local add_count=#self.日报data-old_size
        if isclear then
          日报adp.notifyDataSetChanged()
          self.view.animate().alpha(1).setDuration(100).withEndAction(Runnable{
            run=function()
              self.sr.setRefreshing(false)
            end
          }).start()
         else
          --notifyItemRangeInserted第一个参数是开始插入的位置 adp数据的下标是0 table下标是1 所以直接使用table的长度即可
          日报adp.notifyItemRangeInserted(old_size,add_count)
          self.sr.setRefreshing(false);
        end
      end

      if isclear then
        self.view.animate().alpha(0).setDuration(100).withEndAction(Runnable{
          run=updateData
        }).start()
       else
        updateData()
      end

     else
      self.sr.setRefreshing(false);
      return
    end
  end)
end

function base:getAdapter(home_pagetool,pos)
  local 日报adp=LuaRecyclerAdapter(activity,self.日报data,获取适配器项目布局("home/home_daily"))
  日报adp.setAdapterInterface(LuaRecyclerAdapter.AdapterInterface{
    onBindViewHolder=function(holder,position)
      local views=holder.getTag()
      local data=self.日报data[position+1]

      local 标题=data.标题
      local id内容=data.id内容

      views.标题.text=标题
      views.card.onClick=function()
        nTView=views.card
        newActivity("browser",{data.id内容})
      end
    end,
  })

  return 日报adp
end

function base:initpage(view,sr)
  self.view=view
  self.sr=sr
  view.setAdapter(self:getAdapter())
  --自定义LinearLayoutManager尝试解决闪退问题
  local MyLinearLayoutManager=luajava.bindClass("com.hydrogen.MyLinearLayoutManager")(this,RecyclerView.VERTICAL,false)
  local manager=MyLinearLayoutManager
  view.setLayoutManager(manager)

  sr.setProgressBackgroundColorSchemeColor(转0x(backgroundc));
  sr.setColorSchemeColors({转0x(primaryc)});
  sr.setOnRefreshListener({
    onRefresh=function()
      self:getData(true)
    end,
  });

  self.view.addOnScrollListener(RecyclerView.OnScrollListener{
    onScrollStateChanged=function(recyclerView,newState)
      if newState == RecyclerView.SCROLL_STATE_IDLE then
        local lastVisiblePosition = manager.findLastVisibleItemPosition();
        if lastVisiblePosition >= manager.getItemCount() - 1 and self.可以加载日报 then
          self:getData(false)
          System.gc()
        end
      end
  end});


  return self
end

return base