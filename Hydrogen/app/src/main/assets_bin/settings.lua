require "import"
import "android.widget.*"
import "android.view.*"
import "android.graphics.PorterDuffColorFilter"
import "android.graphics.PorterDuff"
import "mods.muk"
import "com.google.android.material.materialswitch.MaterialSwitch"
设置视图("layout/settings")
设置toolbar(toolbar)
设置toolbar属性(toolbar,"设置")
edgeToedge(mainLay,settings_list )
function onOptionsItemSelected()
  关闭页面()
end

import "com.google.android.material.slider.Slider"
import "com.google.android.material.slider.LabelFormatter"


function clear()
  清理内存()
end

data = processTable{

  {__type=1,title="浏览设置"},

  {__type=3,subtitle="搜索设置"},
  {__type=4,subtitle="自动打开剪贴板上的知乎链接",status={Checked=Boolean.valueOf(this.getSharedData("自动打开剪贴板上的知乎链接"))}},

  {__type=4,subtitle="夜间模式追随系统",status={Checked=Boolean.valueOf(this.getSharedData("Setting_Auto_Night_Mode"))}},
  {__type=4,subtitle="夜间模式",status={Checked=Boolean.valueOf(this.getSharedData("Setting_Night_Mode"))}},
  {__type=4,subtitle="OLED纯黑",status={Checked=Boolean.valueOf(this.getSharedData("OLED"))}},

  {__type=4,subtitle="不加载图片",status={Checked=Boolean.valueOf(this.getSharedData("不加载图片"))}},
  {__type=4,subtitle="智能无图模式",status={Checked=Boolean.valueOf(this.getSharedData("智能无图模式"))}},
  {__type=5,subtitle="字体大小",status={
      valueFrom=10,
      value=tonumber(activity.getSharedData("font_size")),
      valueTo=30,
      LabelFormatter=LabelFormatter{
        getFormattedValue=function(value)
          local formattedNumber = string.format("%.0f", value)
          return formattedNumber.." sp"
        end,
      },

  }},
  {__type=5,subtitle="推荐缓存",status={
      valueFrom=0,
      value=tointeger(activity.getSharedData("feed_cache")),
      valueTo=180,
  }},
  {__type=4,subtitle="回答单页模式",status={Checked=Boolean.valueOf(this.getSharedData("回答单页模式"))}},
  {__type=4,subtitle="关闭热门搜索",status={Checked=Boolean.valueOf(this.getSharedData("关闭热门搜索"))}},


  {__type=4,subtitle="代码块自动换行",status={Checked=Boolean.valueOf(this.getSharedData("代码块自动换行"))}},
  {__type=4,subtitle="切换webview",status={Checked=Boolean.valueOf(this.getSharedData("切换webview"))}},
  {__type=4,subtitle="使用系统字体",status={Checked=Boolean.valueOf(this.getSharedData("使用系统字体"))}},
  {__type=3,subtitle="自定义网页字体(beta)"},
  {__type=3,subtitle="设置屏蔽词"},

  {__type=1,title="主页设置"},

  {__type=4,subtitle="热榜关闭图片",status={Checked=Boolean.valueOf(this.getSharedData("热榜关闭图片"))}},
  {__type=4,subtitle="热榜关闭热度",status={Checked=Boolean.valueOf(this.getSharedData("热榜关闭热度"))}},
  {__type=3,subtitle="设置关注默认选中栏"},
  {__type=3,subtitle="设置主页排序"},
  {__type=3,subtitle="修改主页排序",rightIcon={Visibility=0}},

  {__type=1,title="缓存设置"},

  {__type=4,subtitle="自动清理缓存",status={Checked=Boolean.valueOf(this.getSharedData("自动清理缓存"))}},
  {__type=4,subtitle="禁用大部分缓存",status={Checked=Boolean.valueOf(this.getSharedData("禁用缓存"))}},
  {__type=3,subtitle="清理软件缓存"},

  {__type=1,title="页面设置"},
  {__type=3,subtitle="主题设置",rightIcon={Visibility=0}},
  {__type=4,subtitle="平行世界",status={Checked=Boolean.valueOf(this.getSharedData("平行世界"))}},
  {__type=4,subtitle="预见性返回手势",status={Checked=Boolean.valueOf(this.getSharedData("预见性返回手势"))}},

  {__type=1,title="其他"},
  {__type=3,subtitle="关于",rightIcon={Visibility=0}},
  {__type=3,subtitle="管理/android/data存储",rightIcon={Visibility=0}},
  {__type=3,subtitle="手动填写token"},
  {__type=4,subtitle="音量键切换",status={Checked=Boolean.valueOf(this.getSharedData("音量键选择tab"))}},
  {__type=4,subtitle="显示虚拟滑动按键",status={Checked=Boolean.valueOf(this.getSharedData("显示虚拟滑动按键"))}},
  {__type=4,subtitle="显示报错信息",status={Checked=Boolean.valueOf(this.getSharedData("调式模式"))}},
  {__type=4,subtitle="允许加载代码",status={Checked=Boolean.valueOf(this.getSharedData("允许加载代码"))}},
  {__type=4,subtitle="自动检测更新",status={Checked=Boolean.valueOf(this.getSharedData("自动检测更新"))}},

}


--[[for k, v in ipairs(data) do
  if type(v) == "table" then
    local typeValue = v.__type
    if typeValue ~= 1 and typeValue ~= 6 then
      table.insert(data, k + 1, {__type = 6})
    end
  end
end]]

mtip=false

tab=processTable{
  搜索设置=function()


    local editDialog=AlertDialog.Builder(this)
    .setTitle("设置搜索引擎")
    .setView(loadlayout({
      LinearLayout;
      layout_height="fill";
      layout_width="fill";
      orientation="vertical";
      {--标题,switch type4
        LinearLayout;
        layout_width="fill";
        layout_height="wrap";
        orientation="vertical";
        {
          TextView;
          TextIsSelectable=true;
          layout_marginTop="10dp";
          layout_marginLeft="10dp",
          layout_marginRight="10dp",
          Text='请使用?q=类似物为结尾，如下\n知乎搜索页面 "https://www.zhihu.com/search?type=content&q="\n bing "https://www.bing.com/search?q=site%3Azhihu.com%20"';
          Typeface=字体("product-Medium");
        },
        {
          EditText;
          layout_width="match";
          layout_height="match";
          layout_marginTop="5dp";
          layout_marginLeft="10dp",
          layout_marginRight="10dp",
          id="edit";
          Text=自定义路径;
          Typeface=字体("product");
        }
      };
    }))
    .setPositiveButton("确定", {onClick=function()

        if edit.Text:gsub(" ","")=="" then
          edit.Text=""
        end
        if edit.Text~="" then
          this.setSharedData("搜索引擎",edit.Text)
          提示("设置成功")
         else
          提示("无法读取")
          this.setSharedData("搜索引擎","https://www.bing.com/search?q=site%3Azhihu.com%20")
          return
        end


    end})
    .setNegativeButton("取消", nil)
    .show()
  end,
  夜间模式=function()
    提示("返回主页面生效")
    设置主题()
  end,
  夜间模式追随系统=function(self)
    self.夜间模式()
  end,
  字体大小=function(slider,value,fromUser)
    activity.setResult(1200,nil)
    activity.setSharedData("font_size",value.."")
    if mtip==false then
      双按钮对话框("提示","更改字号后 推荐重启App获得更好的体验","立即重启","我知道了",function(an)
        关闭对话框(an)
        --清除历史记录()
        task(200,function()
          import "android.os.Process"
          local intent =activity.getBaseContext().getPackageManager().getLaunchIntentForPackage(activity.getBaseContext().getPackageName());
          intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
          activity.startActivity(intent);
          Process.killProcess(Process.myPid());
        end)
        end,function(an)
        关闭对话框(an)
      end)
      mtip=true
    end
  end,
  推荐缓存=function(slider,value,fromUser)
    activity.setSharedData("feed_cache",value.."")
    提示("设置为0即关闭缓存推荐以实现去重，知乎仅对重度使用用户推荐流添加重复数据\nEMMC设备推荐关闭该选项以使加载更流畅")
  end,
  设置屏蔽词=function()
    local 屏蔽词=this.getSharedData("屏蔽词")
    local editDialog=AlertDialog.Builder(this)
    .setTitle("设置屏蔽词")
    .setView(loadlayout({
      LinearLayout;
      layout_height="fill";
      layout_width="fill";
      orientation="vertical";
      {
        TextView;
        TextIsSelectable=true;
        layout_marginTop="10dp";
        layout_marginLeft="10dp",
        layout_marginRight="10dp",
        Text='屏蔽后的内容将不会出现 该内容是全局屏蔽词 屏蔽词格式使用空格分割';
        Typeface=字体("product-Medium");
      },
      {
        EditText;
        layout_width="match";
        layout_height="match";
        layout_marginTop="5dp";
        layout_marginLeft="10dp",
        layout_marginRight="10dp",
        id="edit";
        Text=屏蔽词;
        Typeface=字体("product");
      }
    }))
    .setPositiveButton("确定", {onClick=function()
        this.setSharedData("屏蔽词",edit.Text)
        提示("设置成功 重启App生效")
    end})
    .setNegativeButton("取消", nil)
    .show()
  end,
  设置关注默认选中栏=function()
    local startfollow={"精选","最新","想法"}
    local startfollowtab={["精选"]=1,["最新"]=2,["想法"]=3}
    local starnum=startfollowtab[this.getSharedData("startfollow")] or 1
    tipalert=AlertDialog.Builder(this)
    .setTitle("请选择关注默认选中栏")
    .setSingleChoiceItems(startfollow, starnum-1,{onClick=function(v,p)
        starnum=p+1
    end})
    .setPositiveButton("确定", nil)
    .setNegativeButton("取消",nil)
    .show();
    tipalert.getButton(tipalert.BUTTON_POSITIVE).onClick=function()
      if starnum==nil then
        starnum=1
      end
      local startfollow=startfollow[starnum]

      this.setSharedData("startfollow",startfollow)
      starnum=nil
      提示("下次启动App生效")
      tipalert.dismiss()
    end
  end,
  ["自定义网页字体(beta)"]=function()
    local result=get_write_permissions(true)
    if result~=true then
      return false
    end
    local 自定义字体路径=this.getSharedData("网页自定义字体")
    local editDialog=AlertDialog.Builder(this)
    .setTitle("设置网页自定义字体")
    .setView(loadlayout({
      LinearLayout;
      layout_height="fill";
      layout_width="fill";
      orientation="vertical";
      {
        LinearLayout;
        gravity="center_vertical";
        layout_width="fill";
        layout_height="64dp";
        ripple="方自适应",
        onClick=function()
          --没选中就先选中 显示布局
          if font_status.Checked==false then
            font_status.Checked=true
            font_layout_bottom.Visibility=0
           else
            --选中了就取消选中 隐藏布局
            font_status.Checked=false
            font_layout_bottom.Visibility=8
          end
        end,
        {
          TextView;
          Typeface=字体("product");
          textSize="16sp";
          textColor=textc;
          text="开启自定义字体";
          gravity="center_vertical";
          layout_weight="1";
          layout_height="-1";
          layout_marginLeft="16dp";
        };
        {
          MaterialSwitch;
          id="font_status";
          layout_marginRight="16dp";
          focusable=false;
          clickable=false;
          Checked=this.getSharedData("网页自定义字体")~=nil;
        };
      };
      {--标题,switch type4
        LinearLayout;
        layout_width="fill";
        layout_height="wrap";
        orientation="vertical";
        id="font_layout_bottom";
        Visibility=this.getSharedData("网页自定义字体")~=nil and 0 or 8;
        {
          TextView;
          TextIsSelectable=true;
          layout_marginTop="10dp";
          layout_marginLeft="10dp",
          layout_marginRight="10dp",
          Text='部分页面使用网页加载 开启可自定义字体 理论支持绝大多数网页 请输入字体的路径 例如/sdcard/a.ttf 留空则为使用默认App字体 关闭则使用默认网页自带字体';
          Typeface=字体("product-Medium");
        },
        {
          EditText;
          layout_width="match";
          layout_height="match";
          layout_marginTop="5dp";
          layout_marginLeft="10dp",
          layout_marginRight="10dp",
          id="edit";
          Text=自定义字体路径;
          Typeface=字体("product");
        }
      };
    }))
    .setPositiveButton("确定", {onClick=function()
        if font_status.Checked==true then
          if edit.Text:gsub(" ","")=="" then
            edit.Text=""
          end
          if edit.Text=="" or File(edit.Text).canRead() then
            this.setSharedData("网页自定义字体",edit.Text)

            AlertDialog.Builder(this)
            .setTitle("提示")
            .setMessage("软件仅支持ttf格式文件自定义字体 此提示只是提醒 并非代表输入有误 如果无效果请检查输入文件是否为ttf文件（为空可以无视 因为使用的是软件默认内置字体）")
            .setCancelable(false)
            .setPositiveButton("我知道了",nil)
            .show()

           else
            提示("无法读取文件夹 请检查输入是否正确或是否可读")
            return
          end
         else
          this.setSharedData("网页自定义字体",nil)
        end
        提示("设置成功 重启App生效")
    end})
    .setNegativeButton("取消", nil)
    .show()
  end,
  切换webview=function(self,index)
    import "com.norman.webviewup.lib.WebViewUpgrade"
    import "com.norman.webviewup.lib.UpgradeCallback"
    import "com.norman.webviewup.lib.source.UpgradePackageSource"


    if pcall(function() this.getPackageManager().getPackageInfo(webview_packagename,0) end)==false then
      this.setSharedData("切换webview","false")
      data[index].status["Checked"]=false
      adp.notifyDataSetChanged()
      return showSimpleDialog("提示","你还没有安装谷歌浏览器 请安装后开启 本功能开启后将会默认使用谷歌浏览器的WebView而并非系统WebView")
    end

    提示("你需要重启App来生效")

    AlertDialog.Builder(this)
    .setTitle("提示")
    .setMessage("切换后 软件将默认使用谷歌浏览器内置的WebView 请手动下载谷歌浏览器\n该功能仅提供给无法升级WebView使用 如果你可以升级你的WebView 请不要开启")
    .setPositiveButton("我知道了",nil)
    .setCancelable(false)
    .show()

  end,
  使用系统字体=function()
    提示("为了更好的浏览体验 推荐重启App")
  end,
  热榜关闭图片=function()
    提示("设置成功 刷新热榜生效")
  end,
  热榜关闭热度=function()
    提示("设置成功 重刷新热榜生效")
  end,
  修改主页排序=function()
    if not(getLogin()) then
      return 提示("请登录后使用本功能")
    end
    activity.newActivity("homesort")
  end,
  设置主页排序=function()

    提示("可拖拽排序 选中的为主页")

    local data={}

    AlertDialog.Builder(activity)
    .setView(loadlayout({
      LinearLayout;
      orientation="vertical";
      Focusable=true,
      FocusableInTouchMode=true,
      {
        RelativeLayout;
        id="letgo";
        layout_width="match_parent";
        layout_height="wrap_content";
        {
          RecyclerView,
          id="recycler_view",
          layout_width="match_parent";
        };
      };
    }))
    .setPositiveButton("确定",function()
      local starthome=""
      local conf={}
      for _,v ipairs(data)
        if v.myt then
          if v.myt=="其他" then
            break
          end
          continue
        end
        if v.ishome==true then
          starthome=v.title
        end
        table.insert(conf,v.title)
      end
      if #conf<2 then
        return 提示("必须至少开启两个页")
      end
      if starthome=="" then
        return 提示("必须选择一个主页")
      end
      table.insert(conf,starthome)
      local conf=table.concat(conf,",")
      this.setSharedData('home_cof',conf)
      提示("保存成功 下次启动App生效")
    end)
    .setNegativeButton("取消",nil)
    .show()

    recycler_view.layoutManager=LinearLayoutManager(this)

    local 启动页=this.getSharedData("home_cof")
    local items = {}
    for item in 启动页:gmatch('[^,]+') do
      table.insert(items, item)
    end
    local starthome=table.remove(items)
    local allpages={"推荐"=true,"想法"=true,"热榜"=true,"关注"=true}

    table.insert(data,{"myt"="当前"})
    for i, item in ipairs(items) do
      local ishome=false
      if item==starthome then
        ishome=true
      end
      allpages[item]=nil
      table.insert(data,{title=item,ishome=ishome})
    end

    table.insert(data,{"myt"="其他"})
    for key, item in pairs(allpages) do
      table.insert(data,{title=key,ishome=false})
    end

    local item=
    {
      LinearLayout;
      gravity="center_vertical";
      layout_width="fill";
      layout_height="50dp";
      id="root";
      ripple="方自适应",
      {
        TextView;
        id="title";
        textColor=textc;
        gravity="center_vertical";
        layout_weight="1";
        layout_height="-1";
        layout_marginLeft="16dp";
        textSize="16sp";
      };
      {
        RadioButton;
        clickable=false,
        layout_marginRight="16dp";
        focusable=false,
        id="status";
      };
    };

    local item2={
      LinearLayout;
      layout_width="fill";
      layout_height="wrap";
      id="root";
      {
        TextView,
        id="myt",
        layout_margin="16dp";
        layout_marginTop="12dp";
        layout_marginBottom="0dp";
        textColor=primaryc;
        textSize="18sp";
      };
    };


    adapter=LuaCustRecyclerAdapter(AdapterCreator({

      getItemCount=function()
        return #data
      end,

      getItemViewType=function(pos)
        local newdata=data[pos+1]
        if newdata.myt then return 1 end
        return 0
      end,
      onCreateViewHolder=function(parent,type)
        local views={}
        local itemc
        if type==0 then
          itemc=item
         else
          itemc=item2
        end
        local holder=LuaCustRecyclerHolder(loadlayout(itemc,views))
        holder.view.setTag(views)
        return holder
      end,
      areContentsTheSame=function(old,new)
        return old.title==new.title
      end,
      areItemsTheSame=function(old,new)
        return old.title==new.title
      end,
      onBindViewHolder=function(holder,position)
        local newdata=data[position+1]
        local tag=holder.itemView.tag
        if not(newdata.myt) then
          tag.title.text=newdata.title
          tag.status.Checked=newdata.ishome
          tag.root.onClick=function()
            local position=holder.getBindingAdapterPosition()
            for i,v in ipairs(data)
              local index=i-1
              if v.ishome and index~=position then
                v.ishome=false
                adapter.notifyItemChanged(index)
              end
            end
            if tag.status.Checked==false then
              newdata.ishome=true
              tag.status.Checked=true
            end
          end
         else
          tag.myt.text=newdata.myt
        end
      end
    }))

    recycler_view.adapter=adapter

    function table.swap(数据, 查找位置, 替换位置, ismode)
      if ismode then
        替换位置 = 替换位置 + 1
        查找位置 = 查找位置 + 1
      end
      local 删除数据
      xpcall(function()
        删除数据=table.remove(数据, 查找位置)
        end,function()
        return false
      end)
      table.insert(数据, 替换位置, 删除数据)
    end

    import "androidx.recyclerview.widget.ItemTouchHelper"
    luajava.new(luajava.bindClass("androidx.recyclerview.widget.ItemTouchHelper"), luajava.override(luajava.bindClass("androidx.recyclerview.widget.ItemTouchHelper").Callback,{
      getMovementFlags=function(b,c,d)
        local itemclass = luajava.bindClass "androidx.recyclerview.widget.ItemTouchHelper$Callback"
        local dragFlags = ItemTouchHelper.UP
        local swipeFlags = ItemTouchHelper.LEFT
        return int(itemclass.makeMovementFlags(ItemTouchHelper.RIGHT | ItemTouchHelper.LEFT | ItemTouchHelper.DOWN | ItemTouchHelper.UP, 0));
      end,
      isLongPressDragEnabled=function(a)
        return true
      end,
      isItemViewSwipeEnabled=function()
        return false
      end,

      canDropOver=function(a,recyclerView, current, target)
        local fromPosition, toPosition = current.getAdapterPosition(), target.getAdapterPosition();
        if toPosition==0 or fromPosition==0 then
          return false
        end
        return true
      end,
      onMove=function(a,recyclerView, viewHolder, target)
        local fromPosition, toPosition = viewHolder.getAdapterPosition(), target.getAdapterPosition();
        table.swap(data, fromPosition, toPosition, true)
        recycler_view.adapter.notifyItemMoved(fromPosition, toPosition)
        return true;
      end,
      onSelectedChanged=function( viewHolder, actionState)
      end
    })).attachToRecyclerView(recycler_view);

  end,

  禁用大部分缓存=function()
    if this.getSharedData("禁用缓存")=="false" then
      clear()
    end
    提示("开启本并非完全禁用 只可禁用60％左右的缓存")
  end,
  自动清理缓存=function()
    提示("下次打开软件时生效")
  end,
  清理软件缓存=function()
    clear()
  end,

  关于=function()
    newActivity("sub/About/main")
  end,

  手动填写token=function()
    local example_data='{"uid":"xx","user_id":xz,"old_id":xx,"token_type":"xx","access_token":"xx","refresh_token":"xx","expires_in":xx,"cookie":{"q_c0":"xx","z_c0":"xx"},"unlock_ticket":null,"lock_in":null,"verification":null,"expires_at":xx}'
    local editDialog=AlertDialog.Builder(this)
    .setTitle("填写token")
    .setView(loadlayout({
      LinearLayout;
      layout_height="fill";
      layout_width="fill";
      orientation="vertical";
      {
        TextView;
        TextIsSelectable=true;
        layout_marginTop="10dp";
        layout_marginLeft="10dp",
        layout_marginRight="10dp",
        Text='请在下方输入你账号的数据 获取方式 使用抓包软件(例如HttpCanary) 安装https证书后 尝试抓取https://www.baidu.com 查看是否抓取成功 成功后退出知乎登录 抓取数据 登录成功后停止抓取数据 搜索 account/prod/sign_in 找到响应内容复制粘贴在这里 \n示例数据结构 注意 实际数据可能有出入\n'..example_data..'\n提示:请勿随意填写 填写错误可能会导致无法使用本软件 如填写无法使用请点击还原\n长按可复制内容';
        Typeface=字体("product-Medium");
      },
      {
        EditText;
        layout_width="match";
        layout_height="match";
        layout_marginTop="5dp";
        layout_marginLeft="10dp",
        layout_marginRight="10dp",
        id="edit";
        Typeface=字体("product");
      }
    }))
    .setPositiveButton("确定", nil)
    .setNeutralButton("还原",{onClick=function()
        local oridata=this.getSharedData("usersign")
        local oridata1=this.getSharedData("signdata")
        if oridata==nil then
          提示"你似乎还没有手动设置token"
         else
          this.setSharedData("signdata",oridata)
          this.setSharedData("userdata",oridata1)
          提示("还原成功")
        end
    end})
    .setNegativeButton("取消", nil)
    .create()

    local istrue=this.getSharedData("signdata")
    local 状态
    if istrue then
      状态="存在"
     else
      状态="不存在"
    end
    AlertDialog.Builder(this)
    .setTitle("提示")
    .setMessage("当登录时软件默认会自动获取并存储token 如果没有 你也可以手动填写 如果存在 就不推荐手动填写 可能会造成访问报错\n现阶段 软件还不会使用token 所以即使状态为不存在 也可以暂不填写".."\n".."当前状态："..状态)
    .setPositiveButton("我知道了",{onClick=function()
        editDialog.show()
        editDialog.getButton(editDialog.BUTTON_POSITIVE).onClick=function()
          local _check
          pcall(function()
            _check=luajson.decode(edit.Text)
            if _check.access_token then
              _check="Bearer ".._check.access_token
            end
          end)
          if _check then
            local myurl= 'https://www.zhihu.com/api/v4/me'
            local head = {
              ["authorization"] = _check
            }

            zHttp.get(myurl,head,function(code,content)

              if code==200 then--判断网站状态
                local oridata=this.getSharedData("signdata")
                this.setSharedData("usersign",oridata)
                this.setSharedData("signdata",edit.Text)
                提示("保存成功")
                editDialog.dismiss()
               else
                提示("获取个人信息失败 请检查输入内容是否正确")
              end
            end)
           else
            提示("获取access_token失败 请检查输入内容是否正确")
          end
        end
    end})
    .setNegativeButton("取消", nil)
    .show()
  end,

  ["管理/android/data存储"]=function()

    if this.getSharedData("data提示0.01")~="true" then
      AlertDialog.Builder(this)
      .setTitle("建议将Hydrogen的/android/data添加到文件管理器中")
      .setMessage("以下以MT管理器2.0举例".."\n".."点击MT管理器2.0右上角进入菜单 点击菜单内右上角三个点 点击添加本地存储 之后 点击右上角 进入菜单 往下找到Hydrogen 点击 进入后点击最下方的允许访问 之后 添加就成功了")
      .setCancelable(false)
      .setPositiveButton("我知道了",{onClick=function() this.setSharedData("data提示0.01","true") end})
      .show()
      return
    end

    import "android.content.Intent"
    import "android.net.Uri"
    import "java.net.URLDecoder"
    import "java.io.File"
    import "android.provider.DocumentsContract"
    import "android.content.ComponentName"

    import "android.content.pm.PackageManager"
    intent = Intent(Intent.ACTION_GET_CONTENT)
    intent.setType("text/plain");
    intent.addCategory(Intent.CATEGORY_OPENABLE)
    info = this.getPackageManager().resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
    packageName = info.activityInfo.packageName;

    intent = Intent()
    intent.setType("*/*");
    uri=Uri.parse("content://com.android.externalstorage.documents/document/primary%3AAndroid%2Fdata%2F"..activity.getPackageName().."%2Ffiles");
    intent.setData(uri);
    intent.setAction(Intent.ACTION_VIEW);
    componentName = ComponentName(packageName, "com.android.documentsui.files.FilesActivity");
    intent.setComponent(componentName);
    activity.startActivityForResult(intent,1);
    提示("已跳转"..tostring(activity.getExternalFilesDir(nil)).. "请自行管理")
  end,

  主题设置=function()
    newActivity("sub/ThemePicker/main")
  end,


  显示报错信息=function(self,index)
    if this.getSharedData("调式模式")~="false" then
      this.setSharedData("调式模式","false")
      sta=1
    end
    if sta==1 then
      sta=0
      debugtip=AlertDialog.Builder(this)
      .setTitle("是否要开启?")
      .setMessage("开启后会提示一些错误信息 在一定程度上会影响阅读 注意 如果你的机型在安卓12或更高版本 错误信息最多显示两行 请手动修改软件的AndroidManifest.xml 的android:targetSdkVersion= 后的数字改为29 并重写打包 签名密钥在开源项目中 或联系开发者下载修改后安装包 或者使用logfox录制将日志文件发送给开发者")
      .setCancelable(false)
      .setPositiveButton("开启",{onClick=function()
          this.setSharedData("调式模式","true")
          提示("成功！重启App生效")
      end})
      .setNeutralButton("取消",{onClick=function()
          this.setSharedData("调式模式","false")
          data[index].status["Checked"]=false
          adp.notifyDataSetChanged()
      end})
      .show()
     else
      this.setSharedData("调式模式","false")
      提示("成功！重启App生效")
    end
  end,

  允许加载代码=function()
    提示("开启后 将在右上角的功能中增加一个可以执行代码的选项")
  end
}


波纹({fh},"圆主题")

import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"

topcard=ShapeAppearanceModel.builder()
.setBottomLeftCornerSize(RelativeCornerSize(0.1))
.setBottomRightCornerSize(RelativeCornerSize(0.1))
.setTopLeftCornerSize(RelativeCornerSize(0.3))
.setTopRightCornerSize(RelativeCornerSize(0.3)).build()
bottomcard=ShapeAppearanceModel.builder()
.setBottomLeftCornerSize(RelativeCornerSize(0.3))
.setBottomRightCornerSize(RelativeCornerSize(0.3))
.setTopLeftCornerSize(RelativeCornerSize(0.1))
.setTopRightCornerSize(RelativeCornerSize(0.1)).build()
middlecard=ShapeAppearanceModel.builder()
.setBottomLeftCornerSize(RelativeCornerSize(0.1))
.setBottomRightCornerSize(RelativeCornerSize(0.1))
.setTopLeftCornerSize(RelativeCornerSize(0.1))
.setTopRightCornerSize(RelativeCornerSize(0.1)).build()

about_item=processTable{
  {--大标题 type1
    LinearLayout;

    layout_width="fill";
    layout_height="-2";
    {
      TextView;
      Focusable=true;
      layout_marginTop="12dp";
      layout_marginBottom="12dp";
      gravity="center_vertical";
      Typeface=字体("product");
      id="title";
      textSize="14sp";
      textColor=primaryc;
      layout_marginLeft="16dp";
    };
  };

  {--标题,简介 type2
    LinearLayout;
    gravity="center";
    layout_width="fill";
    layout_height="64dp";
    {
      LinearLayout;
      orientation="vertical";
      layout_height="fill";
      gravity="center_vertical";
      layout_weight="1";
      {
        TextView;
        id="subtitle";
        textSize="16sp";
        textColor=textc;
        Typeface=字体("product");
        layout_marginLeft="16dp";
      };
      {
        TextView;
        textColor=stextc;
        id="message";
        textSize="15sp";
        Typeface=字体("product");
        layout_marginLeft="16dp";
      };
    };
  };

  {--标题 图标 type3
    LinearLayout;
    layout_width="fill";
    layout_height="64dp";
    {
      MaterialCardView,
      id="card",
      strokeWidth=0,
      shapeAppearanceModel=middlecard,
      cardBackgroundColor=res.color.attr.colorSurfaceContainerLow,
      layout_width="fill",
      layout_height="fill",
      layout_marginTop="2dp",
      layout_marginBottom="2dp",
      layout_marginLeft="12dp",
      layout_marginRight="12dp",
      paddingTop="0.2dp",
      paddingBottom="0.2dp",
      paddingLeft="16dp",
      paddingRight="16dp",
      layout_gravity="center";
      {LinearLayout,
        layout_width="fill",
        layout_height="fill",
        paddingTop="1dp",
        paddingBottom="1dp",
        paddingLeft="16dp",
        paddingRight="16dp",
        layout_gravity="center";
        {
          TextView;
          id="subtitle";
          layout_weight="1",
          layout_margin="8dp",
          layout_gravity="left|center",
          Typeface=字体("product");
          textSize="16sp";
          textColor=textc;
        };
        {
          AppCompatImageView;
          id="rightIcon";
          layout_marginLeft=0;
          layout_width="24dp";
          layout_height="24dp";
          layout_gravity="right|center",
          colorFilter=theme.color.textColorSecondary;
          ImageResource=R.drawable.ic_chevron_right;
          Visibility=8;
        },
      },
    },
  };



  {--标题,switch type4
    LinearLayout;
    gravity="center_vertical";
    layout_width="fill";
    layout_height="64dp";
    {
      MaterialCardView,
      id="card",
      strokeWidth=0,
      shapeAppearanceModel=middlecard,
      cardBackgroundColor=res.color.attr.colorSurfaceContainerLow,
      layout_width="fill",
      layout_height="fill",
      layout_marginTop="2dp",
      layout_marginBottom="2dp",
      layout_marginLeft="12dp",
      layout_marginRight="12dp",
      paddingTop="0.2dp",
      paddingBottom="0.2dp",
      paddingLeft="16dp",
      paddingRight="16dp",
      layout_gravity="center";
      {LinearLayout,
        layout_width="fill",
        layout_height="fill",
        paddingTop="1dp",
        paddingBottom="1dp",
        paddingLeft="16dp",
        paddingRight="16dp",
        layout_gravity="center";
        {
          TextView;
          id="subtitle";
          Typeface=字体("product");
          textSize="16sp";
          textColor=textc;
          gravity="center_vertical";
          layout_weight="1";
          layout_height="-1";
          layout_marginLeft="8dp";
        };
        {
          MaterialSwitch;
          id="status";
          focusable=false;
          clickable=false;
        };
      };
    },
  },

  {--标题 描述 选框 type5
    LinearLayout;
    gravity="center_vertical";
    layout_width="fill";
    layout_height="100dp";
    {
      MaterialCardView,
      id="card",
      strokeWidth=0,
      shapeAppearanceModel=middlecard,
      cardBackgroundColor=res.color.attr.colorSurfaceContainerLow,
      layout_width="fill",
      layout_height="fill",
      layout_marginTop="2dp",
      layout_marginBottom="2dp",
      layout_marginLeft="12dp",
      layout_marginRight="12dp",
      paddingTop="0.2dp",
      paddingBottom="0.2dp",
      paddingLeft="16dp",
      paddingRight="16dp",
      layout_gravity="center";
      {LinearLayout,
        orientation="vertical",
        layout_width="fill",
        layout_height="fill",
        paddingTop="12dp",
        paddingBottom="1dp",
        paddingLeft="16dp",
        paddingRight="16dp",
        layout_gravity="center";
        {
          TextView;
          id="subtitle";
          textSize="16sp";
          textColor=textc;
          Typeface=字体("product");
          layout_marginLeft="8dp";
        };

        {
          Slider;
          id="status";
          focusable=true;
          clickable=true;
          layout_marginTop="2dp",
          getView=function(view)
            view.addOnChangeListener(Slider.OnChangeListener{
              onValueChange = function(slider,value,fromUser)
                if fromUser then
                  local pos=settings_list.getPositionForView(view)+1
                  data[pos].status.value=value
                  tab[data[pos].subtitle](slider,value,fromUser)
                end
              end
            })
          end
        };
      },
    },
  };

  {--分割线 type6
    LinearLayout;
    layout_width="-1";
    layout_height="-2";
    gravity="center|left";
    onClick=function()end;
    {
      TextView;
      layout_width="-1";
      layout_height="3px";
      background=cardback,
    };
  };

  {--导航栏 type7
    LinearLayout;
    layout_width="-1";
    layout_height="-2";
    gravity="center|left";
    onClick=function()end;
    {
      TextView;
      layout_width="-1";
      layout_height=导航栏高度;

    };
  };

};

--[[for i,j in pairs(data) do
  if j.__type==1
    if data[i-1]~=nil
      local upv = settings_list.getChildAt(i-2)
      print(dump(data[i-1]))
      upv.getChildAt(0).shapeAppearanceModel=bottomcard
    end
    if data[i+1]~=nil
      local down = settings_list.getChildAt(i)
      down.getChildAt(0).shapeAppearanceModel=topcard
    end
  end
end]]

if this.getSharedData("内部浏览器查看回答") == nil then
  this.setSharedData("内部浏览器查看回答","false")
end


adp=luajava.override(BaseAdapter,{
  getItemViewType=function(super, position)
    return int(0)
  end,
  getCount=function(super)
    return int(#data)
  end,
  getItemId=function(super, position)
    return long(position)
  end,
  getViewTypeCount=function(super)
    return int(1)
  end,
  getItem=function(super, position)
    return data[position+1]
  end,
  getView=function(super, position, convertView, parent)

    local holder
    holder = {}
    -- 如果 convertView 为空，则需要创建新的视图和 ViewHolder
    convertView = loadlayout(about_item[data[position+1].__type], holder)
    convertView.setTag(holder)
    -- 设置视图内容
    for i,j in pairs(data[position+1])
      if i=="type"
        continue
       else
        if luajava.instanceof(holder[i],TextView)
          holder[i].text=j
         elseif type(j)==type({})
          for k,v in pairs(j) do
            holder[i][k]=v
          end
        end
      end
    end
    if holder.card
      if data[position] then
        if data[position].__type==1
          holder.card.shapeAppearanceModel=topcard
        end
      end
      if data[position+2] then
        if data[position+2].__type==1
          holder.card.shapeAppearanceModel=bottomcard
        end
      end
    end
    return convertView
  end
})
settings_list.setAdapter(adp)

settab=processTable{
  ["夜间模式"]="Setting_Night_Mode",
  ["夜间模式追随系统"]="Setting_Auto_Night_Mode",
  ["OLED纯黑"]="OLED",
  ["禁用大部分缓存"]="禁用缓存",
  ["暗色工具栏主题"]="theme_darkactionbar",
  ["显示报错信息"]="调式模式",
  ["音量键切换"]="音量键选择tab"
}--设置数据

settings_list.setOnItemClickListener(AdapterView.OnItemClickListener{
  onItemClick=function(id,v,zero,one)
    if v.Tag.status ~= nil then

      if v.Tag.status.Checked then
        this.setSharedData(settab[tostring(v.Tag.subtitle.Text)] or v.Tag.subtitle.Text,"false")
        data[one+1].status["Checked"]=false
       else
        this.setSharedData(settab[tostring(v.Tag.subtitle.Text)] or v.Tag.subtitle.Text,"true")
        data[one+1].status["Checked"]=true
      end
      v.Tag.status.Checked=!v.Tag.status.Checked
    end
    (tab[tostring(v.Tag.subtitle.Text)] or function()end) (tab,one)
    adp.notifyDataSetChanged()--更新列表
end})