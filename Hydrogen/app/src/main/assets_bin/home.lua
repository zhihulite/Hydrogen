require "import"
import "mods.muk"
import "com.lua.custrecycleradapter.*"
import "androidx.recyclerview.widget.*"
import "android.widget.ImageView$ScaleType"
import "androidx.recyclerview.widget.GridLayoutManager"
import "com.google.android.material.navigation.NavigationView"
import "androidx.viewpager.widget.ViewPager"
import "androidx.swiperefreshlayout.widget.*"
import "com.google.android.material.tabs.TabLayout"
import "com.bumptech.glide.Glide"
import "com.google.android.material.bottomnavigation.BottomNavigationView"
import "android.view.ViewTreeObserver"
import "com.google.android.material.appbar.AppBarLayout"
import "com.google.android.material.navigationrail.NavigationRailView"
import "androidx.core.view.insets.ProtectionLayout"
import "androidx.core.view.insets.Protection"
import "androidx.core.view.WindowInsetsCompat"

--导入 MyViewPager
MyViewPager = require "views/MyViewPager"

activity.setContentView(loadlayout("layout/fragment"))
--activity.window.setNavigationBarContrastEnforced(false)
--edgeToedge(mainfLay,true)
Protection=luajava.bindClass("androidx.core.view.insets.Protection")
inSekai=false
if activity.getSharedData("平行世界")~="false" then
  local rootView = activity.getDecorView()
  inSekai=rootView.width>dp2px(600,true)
  observer = rootView.getViewTreeObserver()
  orirh={}
  observer.addOnGlobalLayoutListener(ViewTreeObserver.OnGlobalLayoutListener({
    onGlobalLayout=function()
      if orirh[1]==tointeger(rootView.height)&&orirh[2]==tointeger(rootView.width)
       else
        --onBackCancelled()
        orirh[1]=tointeger(rootView.height)
        orirh[2]=tointeger(rootView.width)
        inSekai=rootView.width>dp2px(600,true)
        if rootView.width>dp2px(600,true)
          if f1 local layoutParams = f1.LayoutParams;
            layoutParams.width=orirh[2]*0.5
            f1.setLayoutParams(layoutParams); end

         else
          if f1 local layoutParams = f1.LayoutParams;
            layoutParams.width=orirh[2]
            f1.setLayoutParams(layoutParams); end

        end
      end
    end
  }))
end

f1.setId(View.generateViewId())
f2.setId(View.generateViewId())
fragmentManager = activity.getSupportFragmentManager()
local t = fragmentManager.beginTransaction()
.add(f1.id,LuaFragment(loadlayout("layout/home")))
.commit()

--fn={{"home",1}}
f1.setTag("home")
f1.setTag(R.id.tag_last_time,tonumber(os.time()))
f2.setTag("empty")
f2.setTag(R.id.tag_last_time,tonumber(os.time())-114514)


nav.setNavigationItemSelectedListener(NavigationView.OnNavigationItemSelectedListener{
  onNavigationItemSelected=function(menuItem)
    if menuItem.isCheckable() then
      for i=0,nav.getMenu().size()-1 do
        nav.getMenu().getItem(i).setChecked(false)
      end
      menuItem.setChecked(true);
    end
    --项目点击事件
    local s=menuItem.title

    switch s
     case "收藏"
      if getLogin()~=true then
        提示("请登录后使用本功能")
        return true
      end
      collection_pagetool:refer(nil,nil,true)
     case "日报"
      daily_pagetool:getData()
     case "关注"
      if getLogin()~=true then
        提示("请登录后使用本功能")
        return true
      end
      followcontent_pagetool:refer(nil,nil,true)
     case "本地"
      task(300,function()newActivity("local_list")end)
     case "设置"
      task(300,function()newActivity("settings")end)
     case "历史"
      task(300,function()newActivity("history")end)
     case "通知"
      if getLogin()~=true then
        提示("请登录后使用本功能")
        return true
      end
      task(300,function()newActivity("browser",{"https://www.zhihu.com/notifications"})end)
     case "更多"

      if not(getLogin()) then
        return 提示("请登录后使用本功能")
      end
      task(20,function()
        AlertDialog.Builder(this)
        .setTitle("请选择")
        .setSingleChoiceItems({"通知","私信","设置","屏蔽用户管理","圆桌","专题"}, 0,{onClick=function(v,p)
            local mtab={"https://www.zhihu.com/notifications","https://www.zhihu.com/messages","https://www.zhihu.com/settings/account","屏蔽用户管理","https://www.zhihu.com/appview/roundtable","https://www.zhihu.com/appview/special"}
            jumpurl=mtab[p+1]
        end})
        .setNegativeButton("确定", {onClick=function()
            if jumpurl=="屏蔽用户管理" then
              jumpurl=nil
              return newActivity("people_list",{"我的屏蔽用户列表"})
            end
            --防止没选中 nil
            newActivity("browser",{jumpurl or "https://www.zhihu.com/notifications"})
            jumpurl=nil
        end})
        .show();
      end)
    end

    切换布局(s)
    _drawer.close();
    return true;
  end
});


import "com.google.android.material.shape.MaterialShapeDrawable"

--activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(Color.TRANSPARENT);


mmenu = {
  { MenuItem,
    title = "主页",
    id = "home_nav",
    checkable=true;
    checked=true;
    icon = 图标("home");
  },
  { MenuItem,
    title = "收藏",
    checkable=true;
    icon = 图标("book");
  },
  { MenuItem,
    title = "日报",
    checkable=true;
    icon = 图标("work");
  },
  { MenuItem,
    title = "关注",
    checkable=true;
    icon = 图标("list_alt");
  },
  { MenuItem,
    title = "通知",
    icon = 图标("notification");
  },
  { MenuItem,
    title = "更多",
    id = "menu_nav",
    icon = 图标("menu");
  },
  -- 子菜单项
  { MenuItem,
    title = "本地",
    icon = 图标("inbox");
    group=1,
  },
  { MenuItem,
    title = "历史",
    icon = 图标("history");
    group=1,
  },
  { MenuItem,
    title = "设置",
    icon = 图标("settings");
    group=1,
  },

}

loadmenu(nav.getMenu(), mmenu)

import "androidx.appcompat.widget.Toolbar"
for i=0,toolbar.getChildCount() do
  local view = toolbar.getChildAt(i);
  if luajava.instanceof(view,TextView) then
    local textView = view;
    textView.setTextSize(20)
  end
end


nav.addHeaderView(loadlayout {
  LinearLayout;
  layout_height="-1";
  layout_width="-1";
  orientation="vertical";
  {
    MaterialCardView;
    layout_height="wrap";
    CardBackgroundColor=cardedge,
    Elevation="0";
    layout_width="-1";
    radius=cardradius;
    StrokeColor=cardedge;
    StrokeWidth=0,
    clickable=true,
    id="侧滑头";
    {
      LinearLayout;
      layout_height="-1";
      layout_width="-1";
      orientation="vertical";
      fitsSystemWindows=true,
      {
        LinearLayout;
        layout_margin="16dp";
        orientation="horizontal";
        layout_width="-1";
        {
          CircleImageView;
          layout_height="48dp";
          layout_gravity="left";
          src="logo",
          id="头像id",
          layout_width="48dp";
          layout_weight="-1",
        };
        {
          LinearLayout;
          layout_marginRight="56dp";
          layout_marginTop="16dp";
          orientation="horizontal";
          gravity="right",
          id="sign_out";
          Visibility=4;
          layout_width="-1";
          {
            ImageView;
            ColorFilter=textc;
            src=图标("exit");
            id="注销",
            layout_width="25dp";
            layout_height="25dp",
            onClick=function()
              双按钮对话框("注销","你确定要注销吗","手滑了","确定",function(an) 关闭对话框(an)end,function(an)
                --避免head刷新不及时
                local head = {
                  ["cookie"] = 获取Cookie("https://www.zhihu.com/")
                }
                Http.get("https://www.zhihu.com/logout",head,function(code,content)
                end)
                清除所有cookie()
                activity.setSharedData("signdata",nil)
                activity.setSharedData("idx",nil)
                activity.setSharedData("udid",nil)
                关闭对话框(an)
                渐变跳转页面("home")
                activity.finish()
              end)
            end
          };
        };
      };
      {
        LinearLayout;
        orientation="vertical";
        {
          TextView;
          layout_marginTop="10dp";
          layout_height="30dp";
          layout_width="-2";
          Text="未登录，点击登录",
          id="名字id",
          textColor=primaryc;
          textSize="15sp";
          paddingLeft="16dp";
          layout_marinBottom="15dp",
          Typeface=字体("product-Bold");
          SingleLine=true;
          gravity="center|left";
        };

        {
          TextView;
          layout_width="-2";
          Text="获取失败";
          textColor=primaryc;
          id="签名id",
          textSize="15sp";
          paddingLeft="16dp";

          Typeface=字体("product");
          SingleLine=true;
          gravity="center|left";
        };
        {
          TextView;
          layout_height="3dp";
        };
      };
    };
  };
})


设置toolbar(toolbar)

if activity.getSharedData("第一次提示") ==nil then
  双按钮对话框("注意","该软件仅供交流学习，严禁用于商业用途，请于下载后的24小时内卸载","登录","知道了",function(an)
    activity.setSharedData("第一次提示","x")
    跳转页面("login")
    关闭对话框(an)

    end,function(an)
    activity.setSharedData("第一次提示","x")
    关闭对话框(an)
  end)
end

if activity.getSharedData("第一次提示") and activity.getSharedData("开源提示")==nil then
  activity.setSharedData("开源提示","true")
  双按钮对话框("提示","本软件已开源 请问是否跳转开源页面?","我知道了","跳转开源地址",function(an)
    关闭对话框(an) end,function(an)
    关闭对话框(an) 浏览器打开("https://gitee.com/huajicloud/Hydrogen/")
  end)
end


if this.getSharedData("自动清理缓存") == nil then
  this.setSharedData("自动清理缓存","true")
end

if this.getSharedData("全屏模式") == nil then
  this.setSharedData("全屏模式","false")
end

if this.getSharedData("font_size")==nil then
  this.setSharedData("font_size","20")
end

if this.getSharedData("Setting_Auto_Night_Mode")==nil then
  activity.setSharedData("Setting_Auto_Night_Mode","true")
end

if activity.getSharedData("feed_cache")==nil
  activity.setSharedData("feed_cache","100")
end

if activity.getSharedData("scroll_sense")==nil
  activity.setSharedData("scroll_sense","2.5")
end

pagadp=SWKLuaPagerAdapter()

local home_layout_table=require("layout/home_layout/page_home")

if not this.getSharedData("home_cof") then
  --格式为底栏,底栏,启动页 最后一个为启动页
  this.setSharedData('home_cof','推荐,热榜,关注,推荐')
end

local 启动页=this.getSharedData("home_cof")
local home_items = {}
for item in 启动页:gmatch('[^,]+') do
  table.insert(home_items, item)
end
local starthome=table.remove(home_items)

home_pageinfo={
  推荐={
    menu= { MenuItem,
      title = "主页",
      id = "home_tab",
      enabled=true;
      icon = 图标("home");
    },
    lay=home_layout_table[1],
    init=function()
      --推荐
      home_pagetool=require "model.home_recommend"
      :new()
      :initpage(home_recy,homesr)
      return home_pagetool
    end,
    refer=function(isclear)
      if isclear==true or HometabLayout.getTabCount()==0 then
        return 加载主页tab()
      end
      home_pagetool:refer(nil,nil,true)
    end,
    getrecy=function()
      return home_recy
    end
  },
  想法={
    menu= { MenuItem,
      title = "想法",
      id = "think_tab",
      enabled=true;
      icon = 图标("bubble_chart")
    },
    lay=home_layout_table[2],
    init=function()
      --想法
      thinker_pagetool=require "model.home_thinker"
      :new()
      :initpage(think_recy,thinksr)
      return thinker_pagetool
    end,
    refer=function(isclear)
      if isclear then
        return thinker_pagetool
        :clearItem(1)
        :refer(1)
      end
      thinker_pagetool:refer(nil,nil,true)
    end,
    getrecy=function()
      return think_recy
    end
  },
  热榜={
    menu= { MenuItem,
      title = "热榜",
      id = "hot_tab",
      enabled=true;
      icon = 图标("fire")
    },
    lay=home_layout_table[3],
    init=function()
      --热榜
      hot_pagetool=require "model.home_hot"
      :new()
      :initpage(hot_recy,hotsr)
      return hot_pagetool
    end,
    refer=function()
      hot_pagetool:getData(false,true)
    end,
    getrecy=function()
      return hot_recy
    end
  },
  关注={
    menu= { MenuItem,
      title = "关注",
      id = "following_tab",
      enabled=true;
      icon = 图标("group")
    },
    lay=home_layout_table[4],
    init=function()
      --关注
      follow_pagetool=require "model.home_follow"
      :new()
      :initpage(follow_vpg,followTab)
      return follow_pagetool
    end,
    refer=function(isclear)
      if not(getLogin()) then
        提示("请登录后使用本功能")
       else
        if isclear then
          return follow_pagetool
          :clearItem()
          :refer(nil,nil,true)
        end
        follow_pagetool:refer(nil,nil,true)
      end
    end,
    getrecy=function()
      return follow_pagetool:getItem()
    end
  }
}

local menu={}
local pageinfo_keys={}
for i,item ipairs(home_items)
  local home_pageinfo=home_pageinfo[item]
  pageinfo_keys[item]=i-1
  if home_pageinfo then
    pagadp.add(loadlayout(home_pageinfo.lay))
    table.insert(menu,home_pageinfo.menu)
    home_pageinfo.init()
   else
    error("错误 找不到"..item)
  end
end

optmenu={}
loadmenu(bnv.getMenu(), menu, optmenu, 3)
bnv.setLabelVisibilityMode(1)

page_home.setAdapter(pagadp)
local startindex=pageinfo_keys[starthome]
page_home.setCurrentItem(startindex,false)
_title.text=(bnv.getMenu().getItem(startindex).getTitle())
bnv.getMenu().getItem(startindex).setChecked(true)

edgeToedge(mainLay,bnv,function()
  --[[local layoutParams = 侧滑头.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  侧滑头.setLayoutParams(layoutParams);
  ]]
  --[[local layoutParams = negbar.LayoutParams;
  layoutParams.height=导航栏高度
  negbar.setLayoutParams(layoutParams);]]
  --[[local layoutParams = bottombar.LayoutParams;
  layoutParams.height=-2
  bottombar.setLayoutParams(layoutParams);]]
  --初始化主页()
end)

local NavlastClickTime = 0
local NavlastClickedItem

function bnv.onNavigationItemSelected(item)
  item = item.getTitle();
  if item =="主页" then
    item="推荐"
  end

  local currentTime = SystemClock.uptimeMillis()
  local pos=pageinfo_keys[item]

  if lastClickedItem == item and currentTime - lastClickTime < 200 then
    home_pageinfo[item].getrecy().smoothScrollToPosition(0)
   else
    lastClickTime = currentTime
    lastClickedItem = item
    page_home.setCurrentItem(pos)
  end
end

page_home.addOnPageChangeListener(ViewPager.OnPageChangeListener {

  onPageScrolled=function(position, positionOffset, positionOffsetPixels)
  end;

  onPageSelected=function(position)
    local pos=position+1
    local home_item=home_items[pos]
    home_pageinfo[home_item].refer()

    for i=0,bnv.getChildCount() do
      bnv.getMenu().getItem(i).setChecked(false)
    end

    bnv.getMenu().getItem(position).setChecked(true)
    _title.text=(bnv.getMenu().getItem(position).getTitle())

  end;

  onPageScrollStateChanged=function(state)

  end
});


function 切换布局(layoutName)
  local pageConfig = {
    主页 = {page_home, bottombar},
    日报 = {page_daily},
    关注 = {page_follow},
    收藏 = {page_collections}
  }

  if not pageConfig[layoutName] then
    return false
  end

  local specialConfig = {
    收藏 = {
      tooltip = "新建收藏夹",
      onClick = function()
        if not getLogin() then
          return 提示("你可能需要登录")
        end
        if collection_pagetool == nil then
          提示("收藏加载中")
          return true
        end
        新建收藏夹(function(mytext, myid, ispublic)
          collection_pagetool:clearItem(1):refer(1)
        end)
      end,
      menuItems = {
        {src=图标("search"), text="在收藏中搜索", onClick=function()
            if not getLogin() then
              return 提示("请登录后使用本功能")
            end

            AlertDialog.Builder(this)
            .setTitle("请输入")
            .setView(loadlayout({
              LinearLayout;
              orientation = "vertical";
              Focusable = true,
              FocusableInTouchMode = true,
              {
                EditText;
                hint = "输入";
                layout_marginTop = "5dp";
                layout_marginLeft = "10dp";
                layout_marginRight = "10dp";
                layout_width = "match_parent";
                layout_gravity = "center";
                id = "edit";
              };
            }))
            .setPositiveButton("确定", {onClick = function()
                newActivity("search_result", {edit.text, "collection"})
            end})
            .setNegativeButton("取消", nil)
            .show()

        end},
        {src=图标("email"), text="反馈", onClick=function() 跳转页面("feedback") end},
        {src=图标("info"), text="关于", onClick=function() 跳转页面("sub/About/main") end}
      }
    },
    其他 = {
      tooltip = "提问",
      onClick = function()
        if not getLogin() then
          return 提示("你可能需要登录")
        end
        nTView = _ask
        task(20, function()
          newActivity("browser", {"https://www.zhihu.com/messages", "提问"})
        end)
      end,
      menuItems = {
        {src=图标("email"), text="反馈", onClick=function() 跳转页面("feedback") end},
        {src=图标("info"), text="关于", onClick=function() 跳转页面("sub/About/main") end}
      }
    }
  }

  local config = specialConfig[layoutName] or specialConfig.其他
  setmyToolip(_ask, config.tooltip)
  _ask.onClick = config.onClick

  if isstart == "true" and layoutName == "收藏" then
    MUKPopu({
      tittle = "菜单",
      list = config.menuItems
    })
  end

  for pageName, views in pairs(pageConfig) do
    for _, view in ipairs(views) do
      view.Visibility = pageName == layoutName and View.VISIBLE or View.GONE
    end
  end
  _title.setText(layoutName)
end


--日报
daily_pagetool=require "model.home_daily"
:new()
:initpage(daily_recy,dailysr)

--收藏
collection_pagetool=require "model.home_collection"
:new()
:initpage(collection_vpg,CollectiontabLayout)

--关注内容
followcontent_pagetool=require "model.follow_content"
:new()
:initpage(followpage,followtabLayout)


local allrecy={home_recy,hot_recy,think_recy}
if follow_pagetool then
  for i=1,follow_pagetool.allcount do
    table.insert(allrecy,follow_pagetool.ids["list".."_"..i])
  end
end

addAutoHideListener(allrecy,{bottombar})


--设置波纹（部分机型不显示，因为不支持setColor）（19 6-6发现及修复因为不支持setColor而导致的报错问题)
波纹({_menu,home_more,_search,_ask,page1,page2,page3,page5,page4,pagetest},"圆主题")
波纹({open_source},"方主题")
--波纹({侧滑头},"方自适应")
--波纹({注销},"圆自适应")


function 加载主页tab()
  if not HometabLayout then
    return
  end

  zHttp.get("https://api.zhihu.com/feed-root/sections/query/v2", head, function(code, content)
    if code == 200 then
      HometabLayout.setVisibility(0)
      local decoded_content = luajson.decode(content)
      if not decoded_content or type(decoded_content.selected_sections) ~= "table" then
        HometabLayout.setVisibility(8)
        home_pagetool:refer(nil, nil, true)
        return
      end

      if this.getSharedData("关闭全站") ~= "true" then
        table.insert(decoded_content.selected_sections, 1, {
          section_name = "全站",
          section_id = nil,
          sub_page_id = nil,
        })
      end

      if HometabLayout.getTabCount() > 0 then
        HometabLayout.removeAllTabs()
      end

      hometab = {}

      for _, v in ipairs(decoded_content.selected_sections) do
        local sub_page_id = v.sub_page_id
        local section_id = v.section_id
        table.insert(hometab, {
          sub_page_id = sub_page_id,
          section_id = section_id,
        })
        local tab = HometabLayout.newTab()
        tab.setText(v.section_name or "")
        HometabLayout.addTab(tab, false)
      end

      HometabLayout.addOnTabSelectedListener(TabLayout.OnTabSelectedListener {
        onTabSelected = function(tab)
          local pos = tab.getPosition() + 1
          local item = hometab[pos]
          if not item then return end

          local section_id = item.section_id
          local sub_page_id = item.sub_page_id

          if section_id == nil then
            home_pagetool:setUrlItem("https://api.zhihu.com/topstory/recommend?tsp_ad_cardredesign=0&feed_card_exp=card_corner|1&v_serial=1&isDoubleFlow=0&action=down&refresh_scene=0&scroll=up&limit=10&start_type=cold&device=phone&short_container_setting_value=0&include_guide_relation=false")
           else
            if sub_page_id then
              home_pagetool:setUrlItem("https://api.zhihu.com/feed-root/section/" .. section_id .. "?sub_page_id=" .. sub_page_id .. "&channelStyle=0")
             else
              home_pagetool:setUrlItem("https://api.zhihu.com/feed-root/section/" .. section_id .. "?channelStyle=0")
            end
          end
          home_pagetool:clearItem()
          home_pagetool:refer()
        end,

        onTabUnselected = function(tab) end,

        onTabReselected = function(tab)
          local pos = tab.getPosition() + 1
          home_pagetool:clearItem(pos, true)
          home_pagetool:refer(nil, true)
        end,
      })

      -- 当滑动结束发送请求 尝试解决重复数据问题
      home_pagetool.urlfunc = function(url, head)
        if not getLogin() then
          return url, head
        end

        local postdatas = {}
        for _, v in ipairs(recommend_data or {}) do
          if v.isread == '"r"' then
            continue
          end
          local encoded_data = luajson.encode(v.readdata)
          if encoded_data then
            table.insert(postdatas, string.format("[%s,%s]", tostring(v.isread), encoded_data))
          end
        end

        table.clear(recommend_data)

        if #postdatas > 0 then
          local postdata = "targets=" .. urlEncode("[" .. table.concat(postdatas, ",") .. "]")
          zHttp.post("https://api.zhihu.com/lastread/touch/v2", postdata, apphead, function(code, content)
          end)
        end

        url = url .. "&start_type=warm&refresh_scene=0"
        return url, head
      end

      --延迟防止滚动
      HometabLayout.postDelayed(Runnable {
        run = function()
          if HometabLayout.getTabCount() > 0 then
            local tab = HometabLayout.getTabAt(0)
            if tab then
              tab.select()
            end
          end
        end
      }, 300)

     else
      HometabLayout.setVisibility(8)
      home_pagetool:refer(nil, nil, true)
    end
  end)
end


function 成功登录回调()
  setHead()
  collection_pagetool:setUrls({
    "https://api.zhihu.com/people/"..activity.getSharedData("idx").."/collections_v2?offset=0&limit=20",
    "https://api.zhihu.com/people/"..activity.getSharedData("idx").."/following_collections?offset=0"
  })
  followcontent_pagetool:setUrls({
    "https://api.zhihu.com/people/"..activity.getSharedData("idx").."/".."following_questions".."?limit=10",
    "https://api.zhihu.com/people/"..activity.getSharedData("idx").."/".."following_collections".."?limit=10",
    "https://api.zhihu.com/people/"..activity.getSharedData("idx").."/".."following_topics".."?limit=10",
    "https://api.zhihu.com/people/"..activity.getSharedData("idx").."/".."following_columns".."?limit=10",
    "https://api.zhihu.com/people/"..activity.getSharedData("idx").."/".."followees".."?limit=10",
    "https://api.zhihu.com/people/"..activity.getSharedData("idx").."/".."following_news_specials".."?limit=10",
    "https://api.zhihu.com/people/"..activity.getSharedData("idx").."/".."following_roundtables".."?limit=10",
  })

  local pos=page_home.getCurrentItem()+1
  local home_item=home_items[pos]
  home_pageinfo[home_item].refer(true)
end


function getuserinfo()

  local myurl= 'https://www.zhihu.com/api/v4/me'

  --不使用zHttp防止报错
  Http.get(myurl, {
    ["cookie"] = 获取Cookie("https://www.zhihu.com/");
    },function(code,content,raw,headers)
    if code==200 then--判断网站状态

      local data=luajson.decode(content)
      local 名字=data.name
      local 头像=data.avatar_url
      local 签名=data.headline
      local uid=data.id
      activity.setSharedData("idx",uid)

      local values= headers.get("x-udid");
      if values and values.isEmpty()==false then
        activity.setSharedData("udid",values.get(0))
      end

      侧滑头.onClick=function()
        newActivity("people",{uid})
      end
      loadglide(头像id,头像,false)
      名字id.Text=名字
      if #签名:gsub(" ","")<1 then
        签名id.Text="你还没有签名呢"
       else
        签名id.Text=签名
      end
      sign_out.setVisibility(View.VISIBLE)
      成功登录回调()
     else
      --状态码不为200的事件
      侧滑头.onClick=function()
        activity.newActivity("login")
      end
      HometabLayout.setVisibility(8)
      loadglide(头像id,logopng)
      名字id.Text="未登录，点击登录"
      签名id.Text="获取失败"
      sign_out.setVisibility(8)

    end
  end)

end

getuserinfo()

local opentab={}
function check()
  if activity.getSharedData("自动打开剪贴板上的知乎链接")~="true" then return end
  import "android.content.*"
  local url=activity.getSystemService(Context.CLIPBOARD_SERVICE).getText()

  url=tostring(url)

  if opentab[url]~=true then
    if url:find("zhihu.com") and 检查链接(url,true) then
      双按钮对话框("提示","检测到剪贴板里含有知乎链接，是否打开？","打开","取消",function(an)关闭对话框(an)
        opentab[url]=true
        检查链接(url)
      end
      ,function(an)
        opentab[url]=true
        关闭对话框(an)
      end)
    end
  end
end

oldTheme=ThemeUtil.getAppTheme()
_全局主题值 = 全局主题值
function onResume()
  if islogin~=getLogin() then
    islogin=getLogin()
    getuserinfo()
  end
  check()
  设置主题()
  if (oldTheme~=ThemeUtil.getAppTheme()) or _全局主题值~=全局主题值 then
    activity.recreate()
    return
  end
end


if this.getSharedData("自动检测更新")=="true" then
  local update_api="https://gitee.com/api/v5/repos/huaji110/huajicloud/contents/zhihu_hydrogen.html?access_token=abd6732c1c009c3912cbfc683e10dc45"
  Http.get(update_api,head,function(code,content)
    if code==200 then
      local content_json=luajson.decode(content)
      local content=base64dec(content_json.content)
      updateversioncode=tonumber(content:match("updateversioncode%=(.+),updateversioncode"))
      isstart=content:match("start%=(.+),start")
      support_version=tonumber(content:match("supportversion%=(.+),supportversion"))
      this.setSharedData("解析zse开关",isstart)
      if updateversioncode > versionCode and tonumber(activity.getSharedData("version"))~=updateversioncode then
        updateversionname=content:match("updateversionname%=(.+),updateversionname")
        updateinfo=content:match("updateinfo%=(.+),updateinfo")
        updateurl=tostring(content:match("updateurl%=(.+),updateurl"))
        if versionCode >= support_version then
          myupdatedialog=AlertDialog.Builder(this)
          .setTitle("检测到最新版本")
          .setMessage("最新版本："..updateversionname.."("..updateversioncode..")\n"..updateinfo)
          .setCancelable(false)
          .setPositiveButton("立即更新",nil)
          .setNeutralButton("忽略本次更新",{onClick=function() activity.setSharedData("version",tostring(updateversioncode)) end})
          .show()
          myupdatedialog.create()
          myupdatedialog.getButton(myupdatedialog.BUTTON_POSITIVE).onClick=function()
            local result=get_write_permissions()
            if result~=true then
              return false
            end
            下载文件对话框("下载安装包中",updateurl,"Hydrogen.apk",false)
          end
         else
          下载方法=content:match("nosupportWay%=(.+),nosupportWay")
          下载提示=content:match("nosupportTip%=(.+),nosupportTip")
          myupdatedialog=AlertDialog.Builder(this)
          .setTitle("检测到最新版本")
          .setMessage("最新版本："..updateversionname.."("..updateversioncode..")\n"..updateinfo)
          .setCancelable(false)
          .setPositiveButton("立即更新",nil)
          .setNeutralButton("暂不更新",{onClick=function() 提示("本次更新为强制更新 下次打开软件会再次提示哦") end})
          .show()
          myupdatedialog.create()
          myupdatedialog.getButton(myupdatedialog.BUTTON_POSITIVE).onClick=function()
            if 下载方法=="native" then
              local result=get_write_permissions()
              if result~=true then
                return false
              end
              下载文件对话框("下载安装包中",updateurl,"Hydrogen.apk",false)
             else
              提示(下载提示)
              浏览器打开(updateurl)
            end
          end
        end
      end
     else
      myupdatedialog=AlertDialog.Builder(this)
      .setTitle("提示")
      .setMessage("检测版本失败 如若是网络问题 请找到网络信号良好的地方使用 如果检查网络后不是网络问题 请打开官网更新 或前往项目页查看往下滑查看最新下载链接 如果开源项目页没了 软件就是寄了")
      .setCancelable(false)
      .setPositiveButton("官网",nil)
      .setNeutralButton("忽略",nil)
      .setNegativeButton("项目页",nil)
      .show()
      myupdatedialog.findViewById(android.R.id.message).TextIsSelectable=true
      myupdatedialog.getButton(myupdatedialog.BUTTON_POSITIVE).onClick=function()
        浏览器打开("https://zhihulite.github.io/")
      end
      myupdatedialog.getButton(myupdatedialog.BUTTON_NEGATIVE).onClick=function()
        浏览器打开("https://gitee.com/huajicloud/hydrogen")
      end
      myupdatedialog.getButton(myupdatedialog.BUTTON_NEUTRAL).onClick=function()
        myupdatedialog.dismiss()
      end

    end
  end)
end

if activity.getSharedData("自动清理缓存")=="true" then
  清理内存()
end

task(1,function()
  a=MUKPopu({
    tittle="菜单",
    list={
      {src=图标("email"),text="反馈",onClick=function()
          跳转页面("feedback")
      end},
      {src=图标("info"),text="关于",onClick=function()
          跳转页面("sub/About/main")
      end},
    }
  })
end)


local MyLuaFileFragment=luajava.bindClass("com.hydrogen.MyLuaFileFragment")

function onKeyDown(code,event)
  if this.getSharedData("音量键选择tab")~="true" then
    return false
  end
  if luajava.instanceof(currentFragment,MyLuaFileFragment) then
    local result=currentFragment.runFunc("onKeyUp",{code,event})
    return result
  end
end

function onKeyUp(code,event)
  if this.getSharedData("音量键选择tab")~="true" then
    return false
  end
  if luajava.instanceof(currentFragment,MyLuaFileFragment) then
    local result=currentFragment.runFunc("onKeyUp",{code,event})
    return result
  end
end

import "model.zHttp"
import "model.zhihu_url"

function onNewIntent(intent)
  local data=tostring(intent.getData())
  检查意图(data)
end

if this.getIntent() then
  --如果本身有intent 就传递给onNewIntent做初始化
  task(1,function()
    onNewIntent(this.getIntent())
  end)
end

if not(this.getSharedData("hometip0.02")) then
  task(50,function()
    if _drawer.isDrawerOpen(Gravity.LEFT) then
      --如果左侧侧滑显示，关闭左侧侧滑并阻止返回键
      _drawer.closeDrawer(Gravity.LEFT)
      return
    end
    _drawer.openDrawer(Gravity.LEFT)
    AlertDialog.Builder(this)
    .setTitle("小提示")
    .setCancelable(false)
    .setMessage("你可点击更多来查看更多功能")
    .setPositiveButton("我知道了",{onClick=function() activity.setSharedData("hometip0.02","true") end})
    .show()
  end)
end

if not(this.getSharedData("updatetip0.01"))and Build.VERSION.SDK_INT <=28 then
  AlertDialog.Builder(this)
  .setTitle("小提示")
  .setCancelable(false)
  .setMessage("如果webview版本过低 可能导致软件基本功能无法使用 建议升级webview使用 升级方法请自行查找")
  .setPositiveButton("我知道了",{onClick=function() activity.setSharedData("updatetip0.01","true") end})
  .show()
end

local packageName = this.getPackageName();
--创建一个Intent对象，用于启动该应用的主Activity
local launchIntent = this.getPackageManager().getLaunchIntentForPackage(packageName);
if launchIntent ~= nil then
  -- 获取应用的ComponentName
  local componentName = launchIntent.getComponent();
  if componentName ~= nil then
    --使用PackageManager清除应用图标缓存
    local packageManager = this.getPackageManager();
    packageManager.clearPackagePreferredActivities(packageName);
    --禁用应用图标并重新启用
    packageManager.setComponentEnabledSetting(componentName,
    PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP);
    packageManager.setComponentEnabledSetting(componentName,
    PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP);
  end
end

if this.getSharedData("切换webview")=="true" then
  if pcall(function() this.getPackageManager().getPackageInfo(webview_packagename,0) end)==false then
    this.setSharedData("切换webview","false")
    return showSimpleDialog("提示","检测不到谷歌浏览器 已自动关闭切换webview")
  end
  import "com.norman.webviewup.lib.WebViewUpgrade"
  import "com.norman.webviewup.lib.source.UpgradePackageSource"
  if WebViewUpgrade.getUpgradeWebViewPackageName()==webview_packagename then
    local upgradeSource = UpgradePackageSource(this.getApplicationContext(),webview_packagename);
    WebViewUpgrade.upgrade(upgradeSource);
  end
end

if this.getSharedData("智能无图模式")=="true" then
  function onStart()
    if 无图模式提醒==true then
      return
    end
    connMgr= this.getSystemService(Context.CONNECTIVITY_SERVICE);
    info=connMgr.getActiveNetworkInfo()
    netType=info.getType()

    if netType==ConnectivityManager.TYPE_WIFI then
      isWifiConn=info.isConnected();
    end

    if netType==ConnectivityManager.TYPE_MOBILE then
      isMobileConn=info.isConnected();
    end

    无图模式=Boolean.valueOf(activity.getSharedData("不加载图片"))
    if isWifiConn and 无图模式==true then
      双按钮对话框("提示","当前在WiFi下 是否关闭不加载图片","关闭","暂不关闭",function(an)
        activity.setSharedData("不加载图片","false")
        提示("关闭不加载图片成功")
        关闭对话框(an)
        end,function(an)
        无图模式提醒=true
        关闭对话框(an)
      end)
     elseif isMobileConn and 无图模式==false then
      双按钮对话框("提示","当前在流量下 是否开启不加载图片","开启","暂不开启",function(an)
        activity.setSharedData("不加载图片","true")
        提示("开启不加载图片成功")
        关闭对话框(an)
        end,function(an)
        无图模式提醒=true
        关闭对话框(an)
      end)
    end
  end
end

--侧滑栏手势
function setupDrawerEdge(drawerLayout)
  -- 获取 DrawerLayout 类
  local drawerLayoutClass = drawerLayout.getClass()

  -- 获取 mLeftDragger 字段（负责左侧拖动手势）
  local leftDraggerField = drawerLayoutClass.getDeclaredField("mLeftDragger")
  leftDraggerField.setAccessible(true)

  -- 获取 ViewDragHelper 实例
  local viewDragHelper = leftDraggerField.get(drawerLayout)
  -- 获取 ViewDragHelper 中的 mDefaultEdgeSize 字段（控制触发边缘大小）
  local edgeSizeField = viewDragHelper.getClass().getDeclaredField("mDefaultEdgeSize")
  edgeSizeField.setAccessible(true)

  -- 获取当前默认边缘大小
  local defaultEdgeSize = edgeSizeField.getInt(viewDragHelper)

  -- 获取屏幕尺寸用于设置更大边缘触发区域
  -- 似乎无用的操作 只修改一次 横竖屏切换还是原来的值 建议改为足够大的值 如果想设置建议加上横竖屏切换动态修改
  local display = activity.getWindowManager().getDefaultDisplay()
  local Point = luajava.bindClass "android.graphics.Point"
  local point = Point()
  display.getRealSize(point)

  -- 设置边缘大小为屏幕宽度或默认值中较大的一个
  edgeSizeField.setInt(viewDragHelper, math.max(defaultEdgeSize, point.x))
  -- 调整触摸滑动阈值（降低滑动灵敏度）
  local touchSlopField = viewDragHelper.getClass().getDeclaredField("mTouchSlop")
  touchSlopField.setAccessible(true)

  local originalTouchSlop = touchSlopField.getInt(viewDragHelper)
  -- 将滑动阈值调整为4倍避免滑动过于灵敏
  touchSlopField.setInt(viewDragHelper, originalTouchSlop * 4)

  -- 禁用长按唤出抽屉 替换 mPeekRunnable 为空实现
  local leftCallbackField = drawerLayoutClass.getDeclaredField("mLeftCallback")
  leftCallbackField.setAccessible(true)

  local dragCallback = leftCallbackField.get(drawerLayout)

  local peekRunnableField = dragCallback.getClass().getDeclaredField("mPeekRunnable")
  peekRunnableField.setAccessible(true)

  -- 创建空的 Runnable 来替代原有的 Runnable
  local nullRunnable = luajava.createProxy("java.lang.Runnable", {
    run = function()
    end
  })

  peekRunnableField.set(dragCallback, nullRunnable)
end

setupDrawerEdge(_drawer)

--Fragment TalkBack适配
function getLastFragmentInContainer(container)
  local fm = this.getSupportFragmentManager()
  local fragments = luajava.astable(fm.getFragments())
  local fragmentsInContainer = {}

  for _, v in ipairs(fragments) do
    if v and v.getView() then
      local parent = v.getView().getParent()
      if parent == container then
        table.insert(fragmentsInContainer, v)
      end
    end
  end

  if #fragmentsInContainer > 0 then
    local lastFragment = table.remove(fragmentsInContainer)
    return fragmentsInContainer, lastFragment
  end

  return nil, nil
end

function getLastFragmentInContainer(container)
  local fm = this.getSupportFragmentManager()
  local fragments = luajava.astable(fm.getFragments())
  local fragmentsInContainer = {}

  for _, v in ipairs(fragments) do
    if v and v.getView() then
      local parent = v.getView().getParent()
      if parent == container then
        table.insert(fragmentsInContainer, v)
      end
    end
  end

  if #fragmentsInContainer > 0 then
    local lastFragment = table.remove(fragmentsInContainer)
    return fragmentsInContainer, lastFragment
  end

  return nil, nil
end

function showLastFragment(container)
  local fm = this.getSupportFragmentManager()
  local fragmentsInContainer, lastFragment = getLastFragmentInContainer(container)

  if not lastFragment then
    return
  end

  local rootView = lastFragment.getView()
  if not rootView then
    return
  end

  -- 显示当前最后的 Fragment
  rootView.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_AUTO)

  -- 隐藏其他 Fragment
  for _, fragment in ipairs(fragmentsInContainer) do
    local view = fragment.getView()
    if view and not fragment.isHidden() then
      view.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS)
    end
  end
end

--保存先有返回栈数量
previousStackSize = this.getSupportFragmentManager().getBackStackEntryCount();
--可以使用 FragmentLifecycleCallbacks实现更精准判断 过快手势返回可能存在bug
local handleBackStackChange=debounce(function()
  currentStackSize = this.getSupportFragmentManager().getBackStackEntryCount();
  --print("currstack"..tostring(currentStackSize))
  --print("prevstack"..tostring(previousStackSize))
  if currentStackSize < previousStackSize then
    -- Fragment 被删除了
    local containers = {
      f1,
      f2,
    }
    for _, container in ipairs(containers) do
      local fragmentsList, lastFragment = getLastFragmentInContainer(container)
      if lastFragment then
        local rootView = lastFragment.getView()
        if not rootView then continue end
        -- 获取当前 accessibility 状态
        local currentFlag = rootView.getImportantForAccessibility()
        -- 判断是否被当成“隐藏”
        local isHidden = currentFlag == View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        if isHidden then
          rootView.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_AUTO)
          import "android.view.accessibility.AccessibilityEvent"

          --只有主页使用LuaFragment
          if luajava.instanceof(lastFragment,LuaFragment)
            local rootView=_menu
            rootView.requestFocus()
            rootView.sendAccessibilityEvent(AccessibilityEvent.TYPE_VIEW_FOCUSED)
           else
            rootView.requestFocus()
            rootView.getChildAt(0).sendAccessibilityEvent(AccessibilityEvent.TYPE_VIEW_FOCUSED)
          end
        end
      end
    end

   elseif currentStackSize > previousStackSize then
    -- 新增 Fragment 到栈中
    local fragmemts=this.getSupportFragmentManager().getFragments()
    local lastFragment=fragmemts[fragmemts.size()-1]
    local container = lastFragment.getView().getParent()
    showLastFragment(container)
  end
  previousStackSize = this.getSupportFragmentManager().getBackStackEntryCount();
end,500)
local accessibilityManager = this.getSystemService(Context.ACCESSIBILITY_SERVICE);
if accessibilityManager.isTouchExplorationEnabled() then
  this.getSupportFragmentManager().addOnBackStackChangedListener(luajava.bindClass "androidx.fragment.app.FragmentManager".OnBackStackChangedListener{
    onBackStackChanged=function()
      handleBackStackChange()
    end
  });
end