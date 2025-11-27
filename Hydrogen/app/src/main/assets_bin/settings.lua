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

local function getSetting(key)
  return this.getSharedData(key) == "true"
end

local function setSetting(key, value)
  this.setSharedData(key, value and "true" or "false")
end

local function getNumberSetting(key, default_value)
  local v = tonumber(this.getSharedData(key))
  return v and v or default_value
end

local data = {}
local function addTitle(title)
  table.insert(data, {type = 1, title = title})
end

local function addCard(subtitle, rightIcon_Visibility)
  if rightIcon_Visibility then
    rightIcon_Visibility = 0
   else
    rightIcon_Visibility = 8
  end
  table.insert(data, {type = 2, subtitle = subtitle, rightIcon = {Visibility = rightIcon_Visibility }})
end

local function addToggle(subtitle, key, onToggle)
  table.insert(data, {
    type = 3,
    subtitle = subtitle,
    status = { Checked = getSetting(key) },
    _key = key,
    _onToggle = onToggle
  })
end

local function addSlider(subtitle, key, from, to, step, formatter)
  table.insert(data, {
    type = 4,
    subtitle = subtitle,
    slider = {
      valueFrom = from,
      value = getNumberSetting(key, from),
      valueTo = to,
      stepSize = step,
      LabelFormatter = {
        getFormattedValue = formatter
      }
    },
    _key = key,
    _onSlide = nil -- 后续在 clickfunc 中绑定
  })
end

addTitle("浏览设置")
addCard("搜索设置")
addToggle("自动打开剪贴板上的知乎链接", "自动打开剪贴板上的知乎链接")
addToggle("夜间模式追随系统", "Setting_Auto_Night_Mode")
addToggle("夜间模式", "Setting_Night_Mode")
addToggle("OLED纯黑", "OLED")
addToggle("不加载图片", "不加载图片")
addToggle("智能无图模式", "智能无图模式")
addSlider("字体大小", "font_size", 10, 30, nil, function(v)
  return string.format("%.0f sp", v)
end)
addSlider("推荐缓存", "feed_cache", 0, 180, nil, function(v)
  return string.format("%.0f 条", v)
end)
addToggle("回答单页模式", "回答单页模式")
addToggle("关闭热门搜索", "关闭热门搜索")
addToggle("代码块自动换行", "代码块自动换行")
addSlider("左右滑动倍数阈值", "scroll_sense", 2.5, 10, 0.1, function(v)
  return string.format("%.1f", v)
end)
addToggle("切换webview", "切换webview")
addToggle("使用系统字体", "使用系统字体")
addCard("自定义网页字体(beta)")
addCard("设置屏蔽词")

addTitle("主页设置")
addToggle("热榜关闭图片", "热榜关闭图片")
addToggle("热榜关闭热度", "热榜关闭热度")
addToggle("关闭推荐全站", "关闭全站")
addCard("修改推荐地点")
addCard("设置关注默认选中栏")
addCard("设置主页底栏排列")

addTitle("缓存设置")
addToggle("自动清理缓存", "自动清理缓存")
addCard("清理软件缓存")

addTitle("页面设置")
addCard("主题设置", true)
addToggle("平行世界", "平行世界")
addToggle("预见性返回手势", "预见性返回手势")

addTitle("其他")
addCard("关于", true)
addCard("管理/android/data存储", true)
addToggle("音量键切换", "音量键选择tab")
addToggle("显示虚拟滑动按键", "显示虚拟滑动按键")
addToggle("显示报错信息", "调式模式")
addToggle("允许加载代码", "允许加载代码")
addToggle("启用内部 WebView eruda 调试", "eruda")
addToggle("自动检测更新", "自动检测更新")

local clickfunc = {}
-- 搜索设置
clickfunc["搜索设置"] = function()
  local 自定义路径 = this.getSharedData("搜索引擎") or "https://www.bing.com/search?q=site%3Azhihu.com%20"
  local editDialog = AlertDialog.Builder(this)
  .setTitle("设置搜索引擎")
  .setView(loadlayout({
    LinearLayout;
    layout_height = "fill";
    layout_width = "fill";
    orientation = "vertical";
    {
      TextView;
      TextIsSelectable = true;
      layout_marginTop = "10dp";
      layout_marginLeft = "10dp",
      layout_marginRight = "10dp",
      Text = '请使用?q=类似物为结尾，如下\n知乎搜索页面 "https://www.zhihu.com/search?type=content&q="\n bing "  https://www.bing.com/search?q=site%3Azhihu.com%20"';
      Typeface = 字体("product-Medium");
    },
    {
      EditText;
      layout_width = "match";
      layout_height = "match";
      layout_marginTop = "5dp";
      layout_marginLeft = "10dp",
      layout_marginRight = "10dp",
      id = "edit";
      Text = 自定义路径;
      Typeface = 字体("product");
    }
  }))
  .setPositiveButton("确定", { onClick = function()
      local text = edit.Text:gsub(" ", "")
      if text == "" then
        text = "https://www.bing.com/search?q=site%3Azhihu.com%20"
      end
      this.setSharedData("搜索引擎", text)
      提示("设置成功")
  end })
  .setNegativeButton("取消", nil)
  .show()
end

-- 夜间模式相关
clickfunc["夜间模式"] = function()
  提示("返回主页面生效")
  设置主题()
end

clickfunc["夜间模式追随系统"] = function()
  clickfunc["夜间模式"]()
end

-- 字体大小
clickfunc["字体大小"] = function()
  if not font_tip then
    font_tip = true
    AlertDialog.Builder(this)
    .setTitle("提示")
    .setMessage("更改字号后推荐重启App获得更好的体验")
    .setPositiveButton("立即重启", { onClick = function()
        import "android.os.Process"
        local intent = activity.getPackageManager().getLaunchIntentForPackage(activity.getPackageName())
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        activity.startActivity(intent)
        Process.killProcess(Process.myPid())
    end })
    .setNegativeButton("我知道了", nil)
    .show()
  end
end

-- 推荐缓存
clickfunc["推荐缓存"] = function(slider, value)
  if not cachetipdia then
    cachetipdia = true
    this.setSharedData("feed_cache_tip", "false")
    AlertDialog.Builder(this)
    .setTitle("提示")
    .setMessage("是否开启重复内容去重提示？本提示仅在每次进入设置页时显示一次")
    .setCancelable(false)
    .setPositiveButton("关闭", nil)
    .setNeutralButton("开启", { onClick = function()
        this.setSharedData("feed_cache_tip", "true")
    end })
    .show()
  end
  提示("设置为0即关闭缓存推荐以实现去重，知乎仅对重度使用用户推荐流添加重复数据\nEMMC设备推荐关闭该选项以使加载更流畅")
end

-- 滑动阈值
clickfunc["左右滑动倍数阈值"] = function(_)
  提示("设置后可前往回答页手动测试")
end

-- 屏蔽词
clickfunc["设置屏蔽词"] = function()
  local 屏蔽词 = this.getSharedData("屏蔽词") or ""
  local editDialog = AlertDialog.Builder(this)
  .setTitle("设置屏蔽词")
  .setView(loadlayout({
    LinearLayout;
    layout_height = "fill";
    layout_width = "fill";
    orientation = "vertical";
    {
      TextView;
      TextIsSelectable = true;
      layout_marginTop = "10dp";
      layout_marginLeft = "10dp",
      layout_marginRight = "10dp",
      Text = '屏蔽后的内容将不会出现 该内容是全局屏蔽词 屏蔽词格式使用空格分割';
      Typeface = 字体("product-Medium");
    },
    {
      EditText;
      layout_width = "match";
      layout_height = "match";
      layout_marginTop = "5dp";
      layout_marginLeft = "10dp",
      layout_marginRight = "10dp",
      id = "edit";
      Text = 屏蔽词;
      Typeface = 字体("product");
    }
  }))
  .setPositiveButton("确定", { onClick = function()
      this.setSharedData("屏蔽词", edit.Text)
      提示("设置成功 重启App生效")
  end })
  .setNegativeButton("取消", nil)
  .show()
end

-- 关注默认栏
clickfunc["设置关注默认选中栏"] = function()
  local startfollow = {"精选", "最新", "想法"}
  local starnum = ({["精选"]=1,["最新"]=2,["想法"]=3})[this.getSharedData("startfollow")] or 1
  local tipalert = AlertDialog.Builder(this)
  .setTitle("请选择关注默认选中栏")
  .setSingleChoiceItems(startfollow, starnum - 1, { onClick = function(_, p)
      starnum = p + 1
  end })
  .setPositiveButton("确定", nil)
  .setNegativeButton("取消", nil)
  .show()
  tipalert.getButton(tipalert.BUTTON_POSITIVE).onClick = function()
    local sel = startfollow[starnum or 1]
    this.setSharedData("startfollow", sel)
    提示("下次启动App生效")
    tipalert.dismiss()
  end
end

-- 自定义字体
clickfunc["自定义网页字体(beta)"] = function()
  local result = get_write_permissions(true)
  if result ~= true then return end
  local path = this.getSharedData("网页自定义字体")
  local editDialog = AlertDialog.Builder(this)
  .setTitle("设置网页自定义字体")
  .setView(loadlayout({
    LinearLayout;
    layout_height = "fill";
    layout_width = "fill";
    orientation = "vertical";
    {
      LinearLayout;
      gravity = "center_vertical";
      layout_width = "fill";
      layout_height = "64dp";
      ripple = "方自适应",
      onClick = function()
        local checked = not font_status.Checked
        font_status.Checked = checked
        font_layout_bottom.Visibility = checked and 0 or 8
      end,
      {
        TextView;
        Typeface = 字体("product");
        textSize = "16sp";
        textColor = textc;
        text = "开启自定义字体";
        gravity = "center_vertical";
        layout_weight = "1";
        layout_height = "-1";
        layout_marginLeft = "16dp";
      },
      {
        MaterialSwitch;
        id = "font_status";
        layout_marginRight = "16dp";
        focusable = false;
        clickable = false;
        Checked = path ~= nil;
      }
    },
    {
      LinearLayout;
      layout_width = "fill";
      layout_height = "wrap";
      orientation = "vertical";
      id = "font_layout_bottom";
      Visibility = (path ~= nil) and 0 or 8,
      {
        TextView;
        TextIsSelectable = true;
        layout_marginTop = "10dp";
        layout_marginLeft = "10dp",
        layout_marginRight = "10dp",
        Text = '部分页面使用网页加载 开启可自定义字体 理论支持绝大多数网页 请输入字体的路径 例如/sdcard/a.ttf 留空则为使用默认App字体 关闭则使用默认网页自带字体';
        Typeface = 字体("product-Medium");
      },
      {
        EditText;
        layout_width = "match";
        layout_height = "match";
        layout_marginTop = "5dp";
        layout_marginLeft = "10dp",
        layout_marginRight = "10dp";
        id = "edit";
        Text = path;
        Typeface = 字体("product");
      }
    }
  }))
  .setPositiveButton("确定", { onClick = function()
      local enable = font_status.Checked
      if enable then
        local text = edit.Text:gsub(" ", "")
        if text ~= "" then
          if File(text).canRead() then
            this.setSharedData("网页自定义字体", text)
            AlertDialog.Builder(this)
            .setTitle("提示")
            .setMessage("软件仅支持ttf格式文件自定义字体（已经是ttf字体可无视）")
            .setCancelable(false)
            .setPositiveButton("我知道了", nil)
            .show()
           else
            提示("无法读取文件，请检查路径")
            return
          end
        end
       else
        this.setSharedData("网页自定义字体", nil)
      end
      提示("设置成功 重启App生效")
  end })
  .setNegativeButton("取消", nil)
  .show()
end

-- WebView切换
clickfunc["切换webview"] = function(_, item)
  local pkg = "com.android.chrome"
  local pm = this.getPackageManager()
  if not pcall(function() pm.getPackageInfo(pkg, 0) end) then
    setSetting("切换webview", false)
    item.status.Checked = false
    adp.notifyDataSetChanged()
    提示("请先安装谷歌浏览器")
    return
  end
  AlertDialog.Builder(this)
  .setTitle("提示")
  .setMessage("切换后将使用谷歌浏览器WebView，请手动下载\n该功能仅提供给无法升级WebView使用")
  .setPositiveButton("我知道了", nil)
  .setCancelable(false)
  .show()
  提示("重启App后生效")
end

local simpleTips = {
  ["使用系统字体"] = "为了更好的浏览体验 推荐重启App",
  ["热榜关闭图片"] = "设置成功 刷新热榜生效",
  ["热榜关闭热度"] = "设置成功 重刷新热榜生效",
  ["自动清理缓存"] = "下次打开软件时生效",
  ["允许加载代码"] = "开启后 将在右上角的功能中增加一个可以执行代码的选项"
}

for k, v in pairs(simpleTips) do
  clickfunc[k] = function() 提示(v) end
end

clickfunc["清理软件缓存"] = function()
  清理内存()
end

clickfunc["关于"] = function()
  newActivity("sub/About/main")
end

clickfunc["主题设置"] = function()
  newActivity("sub/ThemePicker/main")
end

clickfunc["修改推荐地点"] = function()
  zHttp.get("https://api.zhihu.com/feed-root/sections/cityList", head, function(code, content)
    if code == 200 then
      local show_content = ""
      local infos = luajson.decode(content).result_info

      for k, v in ipairs(infos) do
        local city_info_list = v.city_info_list
        local city_key = v.city_key
        for key, value in ipairs(city_info_list) do
          if key == 1 then
            if k > 1 then
              show_content = show_content .. '\n' .. city_key .. '\n'
             else
              show_content = show_content .. city_key .. '\n'
            end
            show_content = show_content .. value.city_name
           else
            show_content = show_content .. " " .. value.city_name
          end
        end
      end

      local dialog = AlertDialog.Builder(this)
      .setTitle("修改城市")
      .setView(loadlayout({
        LinearLayout;
        orientation="vertical";
        Focusable=true;
        FocusableInTouchMode=true;
        {
          EditText;
          hint="输入";
          layout_marginTop="5dp";
          layout_marginLeft="10dp";
          layout_marginRight="10dp";
          layout_width="match_parent";
          layout_gravity="center";
          Typeface=字体("product");
          id="edit";
        };
        {
          ScrollView;
          layout_height="fill";
          fillViewport="true";
          {
            LinearLayout;
            orientation="vertical";
            {
              TextView;
              id="Prompt";
              textSize="15sp";
              layout_marginTop="10dp";
              layout_marginLeft="10dp";
              layout_marginRight="10dp";
              layout_width="match_parent";
              layout_height="match_parent";
              TextIsSelectable=true;
              Typeface=字体("product");
              text=show_content;
            };
          };
        };
      }))
      .setPositiveButton("确定", nil)
      .setNegativeButton("取消", nil)
      .show()

      local positiveButton = dialog.getButton(dialog.BUTTON_POSITIVE)

      positiveButton.onClick = function()
        local checkstr = string.gsub(edit.Text, "%s+", "")
        if checkstr ~= "" and show_content:find(checkstr) then
          zHttp.post("https://api.zhihu.com/feed-root/sections/saveUserCity", '{"city":"'..checkstr..'"}', posthead, function(code, content)
            if code == 200 then
              activity.setResult(100, nil)
              提示("修改成功 你可能需要刷新页面才能看到更改")
             else
              提示("失败 请检查输入内容或联系作者修复")
            end
          end)
         else
          提示("你输入了一个不支持的城市")
        end
      end
     else
      提示("获取城市列表失败")
    end
  end)
end

clickfunc["设置主页底栏排列"] = function()
  local data = {}

  local currentPageItemLayout = {
    LinearLayout;
    gravity="center_vertical";
    layout_width="fill";
    layout_height="50dp";
    id="currentPageItemRoot";
    ripple="方自适应",
    {
      TextView;
      id="currentPageTitle";
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
      id="currentPageRadioButton";
    };
  }

  local sectionHeaderLayout = {
    LinearLayout;
    layout_width="fill";
    layout_height="wrap";
    id="sectionHeaderRoot";
    {
      TextView,
      id="sectionHeaderText",
      layout_margin="16dp";
      layout_marginTop="12dp";
      layout_marginBottom="0dp";
      textColor=primaryc;
      textSize="18sp";
    };
  }

  AlertDialog.Builder(activity)
  .setView(loadlayout({
    LinearLayout;
    orientation="vertical";
    Focusable=true,
    FocusableInTouchMode=true,
    {
      RelativeLayout;
      id="containerLayout";
      layout_width="match_parent";
      layout_height="wrap_content";
      {
        RecyclerView,
        id="recyclerView",
        layout_width="match_parent";
      };
    };
  }))
  .setPositiveButton("确定", function()
    local starthome = ""
    local conf = {}

    for _, v in ipairs(data) do
      if v.header then
        if v.header == "其他" then break end
        continue
      end
      if v.ishome == true then
        starthome = v.title
      end
      table.insert(conf, v.title)
    end

    if #conf < 2 then
      return 提示("必须至少开启两个页")
    end
    if starthome == "" then
      return 提示("必须选择一个主页")
    end

    table.insert(conf, starthome)
    local confStr = table.concat(conf, ",")
    this.setSharedData('home_cof', confStr)
    提示("保存成功 下次启动App生效")
  end)
  .setNegativeButton("取消", nil)
  .show()

  recyclerView.layoutManager = LinearLayoutManager(this)

  local 启动页 = this.getSharedData("home_cof")
  local items = {}
  for item in 启动页:gmatch('[^,]+') do
    table.insert(items, item)
  end
  local starthome = table.remove(items)

  local allpages = { ["推荐"] = true, ["想法"] = true, ["热榜"] = true, ["关注"] = true }

  table.insert(data, { header = "当前" })
  for _, item in ipairs(items) do
    local ishome = (item == starthome)
    allpages[item] = nil
    table.insert(data, { title = item, ishome = ishome })
  end

  table.insert(data, { header = "其他" })
  for key, _ in pairs(allpages) do
    table.insert(data, { title = key, ishome = false })
  end

  adapter = LuaCustRecyclerAdapter(AdapterCreator({
    getItemCount = function()
      return #data
    end,

    getItemViewType = function(pos)
      local item = data[pos + 1]
      local type = item.header and 1 or 0
      item.type = type
      return type
    end,

    onCreateViewHolder = function(parent, type)
      local itemc = type == 0 and currentPageItemLayout or sectionHeaderLayout
      local views = {}
      local holder = LuaCustRecyclerHolder(loadlayout(itemc, views))
      holder.view.setTag(views)
      return holder
    end,

    areContentsTheSame = function(old, new)
      return old.title == new.title
    end,

    areItemsTheSame = function(old, new)
      return old.title == new.title
    end,

    onBindViewHolder = function(holder, position)
      local item = data[position + 1]
      local tag = holder.itemView.tag
      local itemtype = item.type

      switch itemtype
       case 0
        tag.currentPageTitle.text = item.title
        tag.currentPageRadioButton.Checked = item.ishome
        tag.currentPageItemRoot.onClick = function()
          local pos = holder.getBindingAdapterPosition()
          for i, v in ipairs(data) do
            if i - 1 ~= pos then
              v.ishome = false
              adapter.notifyItemChanged(i - 1)
            end
          end
          item.ishome=true
          tag.currentPageRadioButton.Checked=true
        end
       case 1
        tag.sectionHeaderText.text = item.header
      end
    end
  }))

  recyclerView.adapter = adapter

  import "androidx.recyclerview.widget.ItemTouchHelper"
  local itemclass = luajava.bindClass "androidx.recyclerview.widget.ItemTouchHelper$Callback"
  local callback = luajava.override(luajava.bindClass("androidx.recyclerview.widget.ItemTouchHelper$Callback"), {
    getMovementFlags = function(b, c, d)
      local dragFlags = ItemTouchHelper.UP
      local swipeFlags = ItemTouchHelper.LEFT
      return int(itemclass.makeMovementFlags(ItemTouchHelper.RIGHT | ItemTouchHelper.LEFT | ItemTouchHelper.DOWN | ItemTouchHelper.UP, 0))
    end,

    isLongPressDragEnabled = function(a)
      return true
    end,

    isItemViewSwipeEnabled = function()
      return false
    end,

    canDropOver = function(a, recyclerView, current, target)
      local fromPos, toPos = current.getAdapterPosition(), target.getAdapterPosition()
      if toPos == 0 or fromPos == 0 then
        return false
      end
      return true
    end,

    onMove = function(a, recyclerView, viewHolder, target)
      local fromPos, toPos = viewHolder.getAdapterPosition(), target.getAdapterPosition()
      table.swap(data, fromPos, toPos, true)
      recyclerView.adapter.notifyItemMoved(fromPos, toPos)
      return true
    end,

    onSelectedChanged = function(viewHolder, actionState)
    end
  })

  luajava.new(luajava.bindClass("androidx.recyclerview.widget.ItemTouchHelper"), callback).attachToRecyclerView(recyclerView)
end

clickfunc["管理/android/data存储"] = function()
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
  local intent = Intent(Intent.ACTION_GET_CONTENT)
  intent.setType("text/plain");
  intent.addCategory(Intent.CATEGORY_OPENABLE)
  local info = this.getPackageManager().resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
  local packageName = info.activityInfo.packageName;

  intent = Intent()
  intent.setType("*/*");
  local uri=Uri.parse("content://com.android.externalstorage.documents/document/primary%3AAndroid%2Fdata%2F"..activity.getPackageName().."%2Ffiles");
  intent.setData(uri);
  intent.setAction(Intent.ACTION_VIEW);
  local componentName = ComponentName(packageName, "com.android.documentsui.files.FilesActivity");
  intent.setComponent(componentName);
  activity.startActivityForResult(intent,1);
  提示("已跳转"..tostring(activity.getExternalFilesDir(nil)).. "请自行管理")
end

clickfunc["显示报错信息"] = function(holder, item, index)
  local debugMode = getSetting("调式模式")
  if debugMode then
    setSetting("调式模式", false)
    提示("已关闭，重启生效")
   else
    AlertDialog.Builder(this)
    .setTitle("是否要开启?")
    .setMessage("开启后会提示一些错误信息")
    .setPositiveButton("开启", { onClick = function()
        setSetting("调式模式", true)
        提示("成功！重启App生效")
    end })
    .setNeutralButton("取消", { onClick = function()
        holder.status.Checked = false
        adp.notifyDataSetChanged()
    end })
    .show()
  end
end

波纹({fh}, "圆主题")

import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"

local topcard = ShapeAppearanceModel.builder()
.setBottomLeftCornerSize(RelativeCornerSize(0.1))
.setBottomRightCornerSize(RelativeCornerSize(0.1))
.setTopLeftCornerSize(RelativeCornerSize(0.3))
.setTopRightCornerSize(RelativeCornerSize(0.3)).build()

local bottomcard = ShapeAppearanceModel.builder()
.setBottomLeftCornerSize(RelativeCornerSize(0.3))
.setBottomRightCornerSize(RelativeCornerSize(0.3))
.setTopLeftCornerSize(RelativeCornerSize(0.1))
.setTopRightCornerSize(RelativeCornerSize(0.1)).build()

local middlecard = ShapeAppearanceModel.builder()
.setTopLeftCornerSize(RelativeCornerSize(0.1))
.setTopRightCornerSize(RelativeCornerSize(0.1))
.setBottomLeftCornerSize(RelativeCornerSize(0.1))
.setBottomRightCornerSize(RelativeCornerSize(0.1))
.build()

local function buildSimpleCardView(innerlay,isvertical)
  return {
    MaterialCardView,
    id="card",
    strokeWidth=0,
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
    layout_gravity="center",
    {
      LinearLayout,
      orientation=isvertical and "vertical",
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
      innerlay;
    },
  }
end


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

  {--标题 图标 type2
    LinearLayout;
    layout_width="fill";
    layout_height="64dp";
    buildSimpleCardView({
      AppCompatImageView;
      id="rightIcon";
      layout_marginLeft=0;
      layout_width="24dp";
      layout_height="24dp";
      layout_gravity="right|center",
      colorFilter=theme.color.textColorSecondary;
      ImageResource=R.drawable.ic_chevron_right;
      Visibility=8;
    })
  };

  {--标题,switch type3
    LinearLayout;
    gravity="center_vertical";
    layout_width="fill";
    layout_height="64dp";
    buildSimpleCardView({
      MaterialSwitch;
      id="status";
      focusable=false;
      clickable=false;
    });
  },

  {--标题 描述 选框 type4
    LinearLayout;
    gravity="center_vertical";
    layout_width="fill";
    layout_height="100dp";
    buildSimpleCardView({
      Slider;
      id="slider";
      focusable=true;
      clickable=true;
      layout_marginTop="2dp"
    },true)
  };
};

adp = luajava.override(BaseAdapter, {
  getItemViewType = function(_, position)
    -- type下标从0开始
    return int(data[position + 1].type-1)
  end,
  getCount = function(_) return int(#data) end,
  getItemId = function(_, i) return long(i) end,
  getViewTypeCount = function(_) return int(#about_item) end,
  getItem = function(_, i) return data[i + 1] end,
  getView = function(_, position, convertView, parent)
    local succ,result= pcall(function()
      local item = data[position + 1]
      local curr_type = item.type
      local holder

      if convertView == nil then
        holder = {}
        convertView = loadlayout(about_item[curr_type], holder)
        convertView.setTag(holder)
       else
        holder = convertView.getTag()
      end

      for key, val in pairs(item) do
        if key == "type" then continue end
        if luajava.instanceof(holder[key], TextView) then
          holder[key].text = tostring(val)
         elseif type(val) == "table" then
          for subK, subV in pairs(val) do
            holder[key][subK] = subV
          end
        end
      end

      if holder.card then
        if data[position] and data[position].type == 1 then
          holder.card.shapeAppearanceModel = topcard
         elseif data[position + 2] and data[position + 2].type == 1 then
          holder.card.shapeAppearanceModel = bottomcard
         else
          holder.card.shapeAppearanceModel = middlecard
        end


        if holder.slider and item.slider then
          holder.slider.addOnChangeListener(Slider.OnChangeListener {
            onValueChange = function(slider, value, fromUser)
              if fromUser then
                item.slider.value = value
                this.setSharedData(item._key, tostring(value))
                if clickfunc[item.subtitle] then
                  clickfunc[item.subtitle](slider, value, fromUser)
                end
              end
            end
          })
         else
          holder.card.onClick = function()
            if holder.status then
              local newChecked = not holder.status.Checked
              holder.status.Checked = newChecked
              setSetting(item._key or item.subtitle, newChecked)
              if item._onToggle then item._onToggle(holder.status, item) end
            end
            local handler = clickfunc[item.subtitle]
            if handler then handler(holder, item, position) end
          end
        end

      end

      return convertView
    end)
    if not succ then
      local textview = TextView(this)
      textview.text = "界面渲染错误\n"..tostring(result).."\n"
      textview.setTextIsSelectable(true)
      textview.setTextColor(0xFFFF0000)
      convertView = textview
     else
      convertView = result
    end
    return convertView
  end
})

settings_list.setAdapter(adp)
-- 去除默认水波纹
settings_list.setSelector(android.R.color.transparent)