--MyPgae Tool
--author huaji
--time 2024-2-1
--self:对象本身
-- 性能优化：缓存常用的 JNI 类绑定
local MyLinearLayoutManager = luajava.bindClass("com.hydrogen.MyLinearLayoutManager")

local Page_Tool={
  canclick={},
  ids={},
  pagedata={},
  datas={},
  urls={},
  adapters={},
  funcs={},
  listeners={},
  allcount=0,
  addpos=0,
}--父类

local function contains_any(test_string)
  for word in string.gmatch(this.getSharedData("屏蔽词"), "%S+") do
    if string.find(test_string, word, 1, true) then
      return true
    end
  end
  return false
end

local function 加载屏蔽词(tab)
  if this.getSharedData("屏蔽词") and this.getSharedData("屏蔽词"):gsub(" ","")~="" then
    local mt = {
      __newindex = function(t, k, v)
        local 匹配内容=tostring(v.标题)..tostring(v.预览内容)
        if contains_any(匹配内容) then
          return
        end
        rawset(t, k, v)
      end
    }
    setmetatable(tab, mt)
  end
end

function Page_Tool:new(conf)
  if not conf then
    error("至少要绑定一个view")
  end
  local child=table.clone(self)
  for key, value in pairs(conf) do
    child[key] = value
  end
  if not luajava.instanceof(child.view,RecyclerView) and child.view.adapter==nil then
    child.view.adapter=SWKLuaPagerAdapter()
  end
  return child
end

function Page_Tool:initPage()

  table.insert(self.datas,{})

  加载屏蔽词(self.datas[#self.datas])

  table.insert(self.pagedata,{
    prev=false,
    nexturl=false,
    isend=false,
    canload=true,
    --是否为首次加载
    isfirst=true,
    --是否需要检查首次加载是否未满第一页
    needcheck=true
  })
  --添加用于限制点击的标识
  if self.addcanclick then
    local canclick=self.canclick
    table.insert(canclick,true)
  end

  local pagedata=self.pagedata
  --allcount从0计数 下标是1符合我的预期 所以先加1
  local pos=self.allcount+1
  local thispage,thissr=self:getItem(pos)


  if self.adapters_func then
    local adapters_func=self.adapters_func
    self.adapters[pos]=adapters_func(self,pos)
  end

  if self.adapter then
    local adapter=self.adapter
    self.adapters[pos]=adapter
  end

  if self.func then
    local func=self.func
    self.funcs[pos]=func
  end

  if not thispage.adapter then
    if thissr then
      thissr.setProgressBackgroundColorSchemeColor(转0x(backgroundc));
      thissr.setColorSchemeColors({转0x(primaryc)});
      thissr.setOnRefreshListener({
        onRefresh=function()
          self:refer(pos,true,false,true)
        end,
      });
    end

    if not thispage.getLayoutManager() then
      --自定义LinearLayoutManager尝试解决闪退问题
      thispage.setLayoutManager(MyLinearLayoutManager(this,RecyclerView.VERTICAL,false))
    end

    local manager=thispage.getLayoutManager()

    local adp=self.adapters[pos]
    if adp then
      thispage.adapter=adp
     else
      error("必须先设置当前页的adp")
    end

    thispage.addOnScrollListener(RecyclerView.OnScrollListener{
      onScrollStateChanged=function(recyclerView,newState)
        if newState == RecyclerView.SCROLL_STATE_DRAGGING or newState == RecyclerView.SCROLL_STATE_SETTLING then
          Glide.with(this).pauseRequests();
         elseif newState == RecyclerView.SCROLL_STATE_IDLE then
          Glide.with(this).resumeRequests();
        end
      end,
      onScrolled=function(recyclerView, dx, dy)
        if dy > 0 then
          local lastVisiblePosition = manager.findLastVisibleItemPosition();
          if lastVisiblePosition >= manager.getItemCount() - 5 and pagedata[pos]["canload"] then
            local pos=self:getCurrentItem()
            self.referfunc(pos,false)
          end
        end
      end
    });
  end

  --变量添加
  self.allcount=self.allcount+1

  return self
end

function Page_Tool:addPage(addtype,mydata,deftab)--新建Page
  if luajava.instanceof(self.view,RecyclerView) then
    error("RecyclerView单页不支持addPage")
  end

  local data_type=type(mydata)

  if data_type=="number" then
    for i=1,mydata do
      self:addPage(addtype)
    end
    return self
   elseif data_type=="table" then
    for i=1,#mydata-self.addpos do
      self:addPage(addtype)
    end

    self.tabview.setupWithViewPager(self.view)
    --setupWithViewPager设置的必须手动设置text
    for i=1, #mydata do
      local itemnum=i-1
      local tab=self.tabview.getTabAt(itemnum)
      local text=mydata[i]
      tab.setText(text);
      if deftab and deftab==text then
        tab.select()
      end
    end

    return self
  end

  --获取adapter
  local adapter=self.view.adapter
  --已经添加页的总数
  --allcount从0计数 下标是1符合我的预期 所以先加1
  local allcount=self.allcount+1
  --要添加页的类型
  local addtype=addtype or 1

  local pagadp=adapter
  local list="list".."_"..tostring(allcount)
  local sr="sr".."_"..tostring(allcount)
  local addview

  if addtype==1 then
    addview=
    {
      RecyclerView;
      layout_width="fill";
      id=list,
      layout_height="fill";
      nestedScrollingEnabled=true,
    };
   elseif addtype==2 then
    addview={
      SwipeRefreshLayout;
      id=sr;
      layout_height="fill";
      layout_width="fill";
      {
        RecyclerView;
        layout_width="fill";
        id=list,
        layout_height="fill";
        nestedScrollingEnabled=true,
      };
    }
  end

  pagadp.add(loadlayout(addview,self.ids))
  pagadp.notifyDataSetChanged()

  --初始化页数据
  self:initPage()

  return self
end


function Page_Tool:setOnTabListener(callback)
  local view=self.tabview
  local canclick=self.canclick

  local referfunc=self.referfunc
  if referfunc==nil then
    error("你必须首先调用createfunc来创建一个刷新的函数")
  end


  local callback=callback or function() end

  view.addOnTabSelectedListener(TabLayout.OnTabSelectedListener {
    onTabSelected=function(tab)
      --选择时触发
      local pos=tab.getPosition()+1-self.addpos

      callback(self,pos)

      if pos>0 and canclick[pos] then
        canclick[pos]=false
        Handler().postDelayed(Runnable({
          run=function()
            canclick[pos]=true
          end,
        }),1050)
      end
      self:refer(pos,false,true)
    end,

    onTabUnselected=function(tab)
      --未选择时触发
    end,

    onTabReselected=function(tab)
      --选中之后再次点击即复选时触发
      local pos=tab.getPosition()+1-self.addpos

      callback(self,pos)

      if pos>0 and canclick[pos] then
        canclick[pos]=false
        Handler().postDelayed(Runnable({
          run=function()
            canclick[pos]=true
          end,
        }),1050)
      end
      self:refer(pos,true,false,true)
    end,
  });
  return self
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

function Page_Tool:createfunc()

  if self.referfunc then
    error("referfunc已创建 只能存在一个referfunc")
  end

  if not self.funcs then
    error("创建referfunc时必须拥有自身funcs属性")
  end

  if not self.adapters then
    error("创建referfunc时必须拥有自身adapters属性")
  end

  local needlogin=self.needlogin

  self.referfunc=function (pos,isprev,isrefresh)
    local pagedata=self.pagedata

    if pos==nil then
      pos=1
    end

    if isrefresh and pagedata[pos].isend then
      pagedata[pos].isend=false
      pagedata[pos].canload=true
    end

    if not pagedata[pos].canload then
      return
    end

    local thispage,thissr=self:getItem(pos)

    if isprev then
      pagedata[pos]["isprev"]=true
    end

    local isprev=pagedata[pos]["isprev"]

    if pagedata[pos].isend and not isrefresh then
      return 提示("已经到底了")
    end

    local posturl = pagedata[pos].nexturl
    if isrefresh then
      posturl = self.urls[pos]
    elseif isprev then
      --防止prev不存在一直加载的bug或prev为""无法加载
      if pagedata[pos].prev and pagedata[pos].prev~="" then
        posturl = pagedata[pos].prev
      end
    end

    local posturl= posturl or self.urls[pos]

    if needlogin and not(getLogin()) then
      return 提示("请登录后使用本功能")
    end

    local adapter=thispage.adapter

    local head
    if self.head then
      head=_G[self.head]
    end
    if self.urlfunc then
      posturl,head=self.urlfunc(posturl,head)
    end

    zHttp.get(posturl,head,function(code,content)
      if code==200 then
        pagedata[pos]["isprev"]=false
        local data=luajson.decode(content)
        local adpdata=self:getItemData(pos)

        local function updateData()
          if isrefresh then
            table.clear(adpdata)
            thispage.adapter.notifyDataSetChanged()
            thispage.removeAllViews();
            thispage.getRecycledViewPool().clear();
            pagedata[pos].isend=false
            pagedata[pos].isfirst=true
            pagedata[pos].needcheck=true
          end

          if data.paging then
            pagedata[pos].isend=data.paging.is_end
            pagedata[pos].prev=data.paging.previous
            pagedata[pos].nexturl=data.paging.next

            if pagedata[pos].isend==false then
              pagedata[pos]["canload"]=true
            end
          end

          local is_first_load = pagedata[pos].isfirst
          if pagedata[pos].isfirst then
            pagedata[pos].isfirst=false
            if self.firstfunc then
              self.firstfunc(data,adpdata,pos)
            end
          end

          if pagedata[pos].needcheck then
            --延迟 防止获取不准确
            self.view.postDelayed(Runnable{
              run=function()
                if checkIfRecyclerViewIsFullPage(thispage) then
                  if pagedata[pos]["canload"] then
                    self.referfunc(pos,isprev)
                  end
                 else
                  pagedata[pos].needcheck=false
                end
              end
            }, 50);
          end

          local old_size=#adpdata

          local func=self.funcs[pos]
          if data.data then
            for _,v in ipairs(data.data) do
              func(v,adpdata)
            end
           else
            func(data,adpdata)
          end

          -- 只有在非首次加载且确实到末尾时才提示
          if pagedata[pos].isend and not is_first_load then
            提示("没有新内容了")
          end

          if isrefresh then
            thispage.adapter.notifyDataSetChanged()
            thispage.animate().alpha(1).setDuration(100).withEndAction(Runnable{
              run=function()
                thissr.setRefreshing(false);
              end
            }).start()
           else
            local add_count=#adpdata-old_size
            --notifyItemRangeInserted第一个参数是开始插入的位置 adp数据的下标是0 table下标是1 所以直接使用table的长度即可
            thispage.adapter.notifyItemRangeInserted(old_size,add_count)
            thissr.setRefreshing(false);
          end
        end

        if isrefresh then
          thispage.animate().alpha(0).setDuration(100).withEndAction(Runnable{
            run=updateData
          }).start()
         else
          updateData()
        end
       else
        pagedata[pos]["isprev"]=false
        pagedata[pos]["canload"]=true
        thispage.animate().alpha(1).setDuration(100).withEndAction(Runnable{
          run=function()
            thissr.setRefreshing(false);
          end
        }).start()
        提示("加载失败" .. code)
      end
    end)

    if isrefresh or pagedata[pos].isfirst then
      thissr.setRefreshing(true)
    end
    pagedata[pos]["canload"]=false

  end

  return self
end

function Page_Tool:getCurrentItem()
  --针对只有一个RecyclerView的适配
  if luajava.instanceof(self.view,RecyclerView) then
    return 1
  end
  local viewpager=self.view
  return viewpager.getCurrentItem()+1-self.addpos
end

function Page_Tool:refer(index,isprev,isinit,isrefresh)
  local index=index or self:getCurrentItem()
  local thispage,thissr=self:getItem(index)
  if index==0 or (isinit and self:getItem(index).adapter.getItemCount()>1) then
    return self
  end
  self.referfunc(index,isprev,isrefresh)
  return self
end

function Page_Tool:getData()
  return self.datas
end

function Page_Tool:getItemData(index)
  local index=index or self:getCurrentItem()
  local datas=self:getData()
  return datas[index]
end

--isprev 是否保留nexturl和prev
function Page_Tool:clearItem(index,isprev)
  local index=index or self:getCurrentItem()
  local prev,nexturl
  --是否允许向上查看上面内容
  local allow_prev=self.allow_prev
  if isprev and allow_prev then
    prev=self.pagedata[index].prev
    nexturl=self.pagedata[index].nexturl
  end
  self.pagedata[index]={
    prev=prev,
    nexturl=nexturl,
    isend=false,
    canload=true,
    isfirst=true,
    needcheck=true
  }
  local list=self:getItem(index)
  if list.adapter then
    table.clear(self:getItemData(index))
    list.adapter.notifyDataSetChanged()
    list.removeAllViews();
    list.getRecycledViewPool().clear();
  end
  return self
end

function Page_Tool:setUrls(urls)
  self.urls=urls
  return self
end

function Page_Tool:setUrlItem(url,index)
  local index=index or self:getCurrentItem()
  self.urls[index]=url
  return self
end

function Page_Tool:getItem(index)

  --针对只有一个RecyclerView的适配
  if luajava.instanceof(self.view,RecyclerView) then
    return self.view,self.sr
  end

  local index=index or self:getCurrentItem()

  local ids=self.ids
  local list="list".."_"..tostring(index)
  local sr="sr".."_"..tostring(index)

  local thislist=ids[list]
  local thissr=ids[sr]

  if thissr==nil then
    thissr = {}
    --防止尝试访问一些没有的方法报错
    setmetatable(thissr, {
      __index = function(table, key)
        return true
      end
    })
  end

  return thislist,thissr
end

return Page_Tool