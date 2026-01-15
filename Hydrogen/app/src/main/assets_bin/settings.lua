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
  return tonumber(this.getSharedData(key)) or default_value
end

local data = {}
local function addItem(item)
  table.insert(data, item)
end

local settings_config = {
  { type="title", title="浏览设置" },
  { type="card", subtitle="搜索设置" },
  { type="toggle", subtitle="自动打开剪贴板上的知乎链接", key="自动打开剪贴板上的知乎链接" },
  { type="toggle", subtitle="夜间模式追随系统", key="Setting_Auto_Night_Mode" },
  { type="toggle", subtitle="夜间模式", key="Setting_Night_Mode" },
  { type="toggle", subtitle="OLED纯黑", key="OLED" },
  { type="toggle", subtitle="不加载图片", key="不加载图片" },
  { type="toggle", subtitle="智能无图模式", key="智能无图模式" },
  { type="slider", subtitle="字体大小", key="font_size", from=10, to=30, format="%.0f sp" },
  { type="slider", subtitle="推荐缓存", key="feed_cache", from=0, to=180, format="%.0f 条" },
  { type="toggle", subtitle="回答单页模式", key="回答单页模式" },
  { type="toggle", subtitle="关闭热门搜索", key="关闭热门搜索" },
  { type="toggle", subtitle="代码块自动换行", key="代码块自动换行" },
  { type="slider", subtitle="左右滑动倍数阈值", key="scroll_sense", from=0.5, to=5, step=0.1, format="%.1f" },
  { type="toggle", subtitle="切换webview", key="切换webview" },
  { type="toggle", subtitle="使用系统字体", key="使用系统字体" },
  { type="card", subtitle="自定义网页字体(beta)" },
  { type="card", subtitle="设置屏蔽词" },

  { type="title", title="主页设置" },
  { type="toggle", subtitle="热榜关闭图片", key="热榜关闭图片" },
  { type="toggle", subtitle="热榜关闭热度", key="热榜关闭热度" },
  { type="toggle", subtitle="关闭推荐全站", key="关闭全站" },
  { type="card", subtitle="修改主页推荐地点tab" },
  { type="card", subtitle="设置关注默认选中栏" },
  { type="card", subtitle="设置主页底栏排列" },

  { type="title", title="缓存设置" },
  { type="toggle", subtitle="自动清理缓存", key="自动清理缓存" },
  { type="card", subtitle="清理软件缓存" },

  { type="title", title="页面设置" },
  { type="card", subtitle="主题设置", arrow=true },
  { type="toggle", subtitle="平行世界", key="平行世界" },
  { type="toggle", subtitle="预见性返回手势", key="预见性返回手势" },

  { type="title", title="其他" },
  { type="card", subtitle="关于", arrow=true },
  { type="card", subtitle="管理/android/data存储", arrow=true },
  { type="toggle", subtitle="音量键切换", key="音量键选择tab" },
  { type="toggle", subtitle="显示虚拟滑动按键", key="显示虚拟滑动按键" },
  { type="toggle", subtitle="显示报错信息", key="调式模式" },
  { type="toggle", subtitle="允许加载代码", key="允许加载代码" },
  { type="toggle", subtitle="启用内部 WebView eruda 调试", key="eruda" },
  { type="toggle", subtitle="自动检测更新", key="自动检测更新" },
}

for _, item in ipairs(settings_config) do
  if item.type == "title" then
    table.insert(data, { type = 1, title = item.title })
  elseif item.type == "card" then
    table.insert(data, { type = 2, subtitle = item.subtitle, rightIcon = { Visibility = item.arrow and 0 or 8 } })
  elseif item.type == "toggle" then
    table.insert(data, { type = 3, subtitle = item.subtitle, status = { Checked = getSetting(item.key) }, _key = item.key })
  elseif item.type == "slider" then
    table.insert(data, {
      type = 4, subtitle = item.subtitle, _key = item.key,
      slider = {
        valueFrom = item.from, value = getNumberSetting(item.key, item.from), valueTo = item.to, stepSize = item.step or 1,
        LabelFormatter = { getFormattedValue = function(v) return string.format(item.format, v) end }
      }
    })
  end
end

local function showEditDialog(title, message, key, default_val, hint)
  AlertDialog.Builder(this)
  .setTitle(title)
  .setView(loadlayout({
    LinearLayout, orientation="vertical",
    { TextView, text=message, Typeface=字体("product-Medium"), layout_margin="16dp", layout_marginBottom="8dp" },
    { EditText, id="edit", text=this.getSharedData(key) or default_val, hint=hint, Typeface=字体("product"), layout_marginLeft="16dp", layout_marginRight="16dp", layout_marginBottom="16dp" }
  }))
  .setPositiveButton("确定", { onClick = function()
      this.setSharedData(key, edit.Text)
      提示("设置成功")
  end })
  .setNegativeButton("取消", nil)
  .show()
end

local clickfunc = {}

clickfunc["搜索设置"] = function()
  showEditDialog("设置搜索引擎", '请使用?q=类似物为结尾，如下\n知乎搜索页面 "https://www.zhihu.com/search?type=content&q="\n bing "  https://www.bing.com/search?q=site%3Azhihu.com%20"', "搜索引擎", "https://www.bing.com/search?q=site%3Azhihu.com%20")
end

clickfunc["夜间模式"] = function()
  设置主题(); activity.recreate()
end
clickfunc["夜间模式追随系统"] = clickfunc["夜间模式"]

clickfunc["字体大小"] = function()
  if font_tip then return end
  font_tip = true
  AlertDialog.Builder(this)
  .setTitle("提示").setMessage("更改字号后推荐重启App获得更好的体验")
  .setPositiveButton("立即重启", { onClick = function()
      local intent = activity.getPackageManager().getLaunchIntentForPackage(activity.getPackageName())
      intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
      activity.startActivity(intent)
      import "android.os.Process"
      Process.killProcess(Process.myPid())
  end })
  .setNegativeButton("我知道了", nil).show()
end

clickfunc["设置屏蔽词"] = function()
  showEditDialog("设置屏蔽词", "屏蔽后的内容将不会出现 该内容是全局屏蔽词 屏蔽词格式使用空格分割", "屏蔽词", "", "输入屏蔽词")
end

clickfunc["设置关注默认选中栏"] = function()
  local options = {"精选", "最新", "想法"}
  local selected = ({["精选"]=0,["最新"]=1,["想法"]=2})[this.getSharedData("startfollow")] or 0
  AlertDialog.Builder(this)
  .setTitle("请选择关注默认选中栏")
  .setSingleChoiceItems(options, selected, { onClick = function(_, p) selected = p end })
  .setPositiveButton("确定", { onClick = function()
      this.setSharedData("startfollow", options[selected+1])
      提示("下次启动App生效")
  end })
  .setNegativeButton("取消", nil).show()
end

clickfunc["自定义网页字体(beta)"] = function()
  if get_write_permissions(true) ~= true then return end
  local path = this.getSharedData("网页自定义字体")
  local layout = {
    LinearLayout, orientation="vertical",
    {
      LinearLayout, gravity="center_vertical", layout_height="64dp", ripple="方自适应",
      onClick = function() font_status.Checked = not font_status.Checked; font_layout.Visibility = font_status.Checked and 0 or 8 end,
      { TextView, text="开启自定义字体", textSize="16sp", layout_weight="1", layout_marginLeft="16dp" },
      { MaterialSwitch, id="font_status", Checked = (path ~= nil), focusable=false, clickable=false, layout_marginRight="16dp" }
    },
    {
      LinearLayout, id="font_layout", orientation="vertical", Visibility = (path and 0 or 8),
      { TextView, text='请输入字体的路径 例如/sdcard/a.ttf', layout_margin="10dp" },
      { EditText, id="edit", text=path, layout_margin="10dp" }
    }
  }
  AlertDialog.Builder(this).setTitle("设置网页自定义字体").setView(loadlayout(layout))
  .setPositiveButton("确定", { onClick = function()
      if font_status.Checked then
        local text = edit.Text:gsub(" ", "")
        if text ~= "" and File(text).canRead() then
          this.setSharedData("网页自定义字体", text)
          提示("设置成功 重启生效")
         else
          提示("路径无效或无法读取")
        end
       else
        this.setSharedData("网页自定义字体", nil)
        提示("设置成功")
      end
  end }).setNegativeButton("取消", nil).show()
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

clickfunc["修改主页推荐地点tab"] = function()
  zHttp.get("https://api.zhihu.com/feed-root/sections/cityList", head, function(code, content)
    if code ~= 200 then return 提示("获取城市列表失败") end
    local infos = luajson.decode(content).result_info
    local cities = {}
    for _, v in ipairs(infos) do
      local names = {}
      for _, city in ipairs(v.city_info_list) do table.insert(names, city.city_name) end
      table.insert(cities, v.city_key .. "\n" .. table.concat(names, " "))
    end
    local show_content = table.concat(cities, "\n\n")

    local dialog = AlertDialog.Builder(this).setTitle("修改城市").setView(loadlayout({
      LinearLayout, orientation="vertical", Focusable=true, FocusableInTouchMode=true,
      { EditText, id="edit", hint="输入城市名", layout_width="match_parent", layout_margin="16dp", Typeface=字体("product") },
      { ScrollView, layout_height="wrap", { TextView, text=show_content, layout_margin="16dp", TextIsSelectable=true, Typeface=字体("product") } }
    })).setPositiveButton("确定", nil).setNegativeButton("取消", nil).show()

    dialog.getButton(dialog.BUTTON_POSITIVE).onClick = function()
      local city = edit.Text:gsub("%s+", "")
      if city ~= "" and show_content:find(city) then
        zHttp.post("https://api.zhihu.com/feed-root/sections/saveUserCity", '{"city":"'..city..'"}', posthead, function(c, content)
          if c == 200 then 提示("修改成功，需刷新主页") else 提示("修改失败") end
        end)
        dialog.dismiss()
       else
        提示("不支持的城市")
      end
    end
  end)
end

clickfunc["设置主页底栏排列"] = function()
  local page_data = {}
  local config = this.getSharedData("home_cof")
  local items = {}
  for item in config:gmatch('[^,]+') do table.insert(items, item) end
  local starthome = table.remove(items)
  local allpages = { ["推荐"]=true, ["想法"]=true, ["热榜"]=true, ["关注"]=true }

  table.insert(page_data, { header = "当前" })
  for _, item in ipairs(items) do
    allpages[item] = nil
    table.insert(page_data, { title = item, ishome = (item == starthome) })
  end
  table.insert(page_data, { header = "其他" })
  for k in pairs(allpages) do table.insert(page_data, { title = k, ishome = false }) end

  local layout = {
    LinearLayout, orientation="vertical",
    { RecyclerView, id="recyclerView", layout_width="match_parent" }
  }

  local dialog = AlertDialog.Builder(this).setView(loadlayout(layout))
  .setPositiveButton("确定", function()
    local selected, conf = nil, {}
    for _, v in ipairs(page_data) do
      if v.title then
        table.insert(conf, v.title)
        if v.ishome then selected = v.title end
      elseif v.header == "其他" then break end
    end
    if #conf < 2 or not selected then return 提示("需至少开启两页且选一个主页") end
    table.insert(conf, selected)
    this.setSharedData('home_cof', table.concat(conf, ","))
    提示("保存成功，下次启动生效")
  end).setNegativeButton("取消", nil).show()

  recyclerView.layoutManager = LinearLayoutManager(this)
  local adapter = LuaCustRecyclerAdapter(AdapterCreator({
    getItemCount = function() return #page_data end,
    getItemViewType = function(pos) return page_data[pos+1].header and 1 or 0 end,
    onCreateViewHolder = function(parent, type)
      local item_lay = (type == 1) and {
        TextView, id="sectionHeaderText", layout_margin="16dp", textColor=primaryc, textSize="18sp"
      } or {
        LinearLayout, gravity="center_vertical", layout_height="50dp", ripple="方自适应", id="itemRoot",
        { TextView, id="title", textColor=textc, layout_weight="1", layout_marginLeft="16dp", textSize="16sp" },
        { RadioButton, id="radio", focusable=false, clickable=false, layout_marginRight="16dp" }
      }
      local views = {}
      local holder = LuaCustRecyclerHolder(loadlayout(item_lay, views))
      holder.view.setTag(views)
      return holder
    end,
    onBindViewHolder = function(holder, position)
      local item = page_data[position+1]
      local tag = holder.itemView.tag
      if item.header then
        tag.sectionHeaderText.text = item.header
       else
        tag.title.text = item.title
        tag.radio.Checked = item.ishome
        tag.itemRoot.onClick = function()
          for _, v in ipairs(page_data) do v.ishome = false end
          item.ishome = true
          holder.getBindingAdapter().notifyDataSetChanged()
        end
      end
    end
  }))
  recyclerView.adapter = adapter

  import "androidx.recyclerview.widget.ItemTouchHelper"
  local callback = luajava.override(ItemTouchHelper.Callback, {
    getMovementFlags = function() return ItemTouchHelper.Callback.makeMovementFlags(ItemTouchHelper.UP | ItemTouchHelper.DOWN, 0) end,
    canDropOver = function(_, _, current, target) return target.getAdapterPosition() > 0 end,
    onMove = function(_, _, vh, target)
      local from, to = vh.getAdapterPosition()+1, target.getAdapterPosition()+1
      table.swap(page_data, from, to, true)
      adapter.notifyItemMoved(from-1, to-1)
      return true
    end
  })
  ItemTouchHelper(callback).attachToRecyclerView(recyclerView)
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
  local resolve_intent = Intent(Intent.ACTION_GET_CONTENT).setType("text/plain").addCategory(Intent.CATEGORY_OPENABLE)
  local info = this.getPackageManager().resolveActivity(resolve_intent, PackageManager.MATCH_DEFAULT_ONLY)
  
  if not info or not info.activityInfo then
    return 提示("无法找到系统文件管理器，请手动管理存储空间")
  end
  
  local packageName = info.activityInfo.packageName
  local target_intent = Intent()
  target_intent.setType("*/*")
  local uri = Uri.parse("content://com.android.externalstorage.documents/document/primary%3AAndroid%2Fdata%2F"..activity.getPackageName().."%2Ffiles")
  target_intent.setData(uri)
  target_intent.setAction(Intent.ACTION_VIEW)
  local componentName = ComponentName(packageName, "com.android.documentsui.files.FilesActivity")
  target_intent.setComponent(componentName)
  
  local success, err = pcall(function() activity.startActivityForResult(target_intent, 1) end)
  if success then
    提示("已跳转，请自行管理")
   else
    提示("启动失败：" .. tostring(err))
  end
end

clickfunc["显示报错信息"] = function(holder, item)
  local is_on = getSetting("调式模式")
  提示(is_on and "已开启调试模式，重启生效" or "已关闭调试模式，重启生效")
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