require "import"
-- 新增 使用自定义toolbar
useCustomAppToolbar=true
import "jesse205"
local normalkeys=jesse205.normalkeys
normalkeys.appInfo=true
normalkeys.openSourceLicenses=true
normalkeys.developers=true
--normalkeys.moreItem=true
normalkeys.copyright=true
normalkeys.onUpdate=true

import "android.graphics.Typeface"
import "android.text.Spannable"
import "android.text.SpannableString"
import "android.text.style.ForegroundColorSpan"
import "android.text.style.StyleSpan"

import "com.jesse205.layout.util.SettingsLayUtil"
import "com.jesse205.app.dialog.ImageDialogBuilder"
import "appAboutInfo"
import "agreements"

import "com.google.android.material.appbar.AppBarLayout"
import "com.google.android.material.appbar.MaterialToolbar"
import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.core.widget.NestedScrollView"

local luapath=File(luajava.luadir).getParentFile().getParentFile().toString()
package.path = package.path..";"..luapath.."/?.lua"
require("mods.muk")

设置视图("layout")
设置toolbar(toolbar)
设置toolbar属性(toolbar,R.string.jesse205_about)
edgeToedge(mainLay,recyclerView)
loadlayout2("iconLayout")
loadlayout2("portraitCardParentView")
portraitCardParent.addView(iconLayout)

adapterEvents=SettingsLayUtil.adapterEvents
packageInfo=activity.getPackageManager().getPackageInfo(getPackageName(),0)

--获取QQ头像链接
function getUserAvatarUrl(qq,size)
  if qq then
    return ("http://q.qlogo.cn/headimg_dl?spec=%s&img_type=jpg&dst_uin=%s"):format(size or 640,qq)
  end
end

--QQ交流
function chatOnQQ(qqNumber)
  local uri=Uri.parse("mqqwpa://im/chat?chat_type=wpa&uin="..qqNumber)
  if not(pcall(activity.startActivity,Intent(Intent.ACTION_VIEW,uri))) then
    MyToast(R.string.jesse205_noQQ)
  end
end

--加入QQ交流群
function joinQQGroup(groupNumber)
  local uri=Uri.parse(("mqqapi://card/show_pslcard?src_type=internal&version=1&uin=%s&card_type=group&source=qrcode"):format(groupNumber))
  if not(pcall(activity.startActivity,Intent(Intent.ACTION_VIEW,uri))) then
    MyToast(R.string.jesse205_noQQ)
  end
end

function callItem(parent,view,data)
  if data.url then
    openUrl(data.url)
   elseif data.browserUrl then
    newActivity("browser",{data.browserUrl})
   elseif data.qqGroup then--QQ群
    joinQQGroup(data.qqGroup)
   elseif data.qq then
    chatOnQQ(data.qq)
   elseif data.click then
    data.click()
   elseif data.contextMenuEnabled then
    if parent and view then
      parent.showContextMenuForChild(view)
    end
  end
end

function onItemClick(view,views,key,data)
  if callItem(recyclerView,view,data) then
   elseif key=="version" then
    if onUpdate then
      onUpdate()
    end
   elseif key=="html" then
    newActivity("sub/HtmlFileViewer/main",{{title=data.title,path=data.path}})
   elseif key=="openSourceLicenses" then
    newActivity("sub/OpenSourceLicenses/main")
   elseif key=="thanks" then
    local items={}
    for index,content in pairs(data.thanks) do
      local text=SpannableString(index..": "..table.concat(content,"、"))
      local indexLength=utf8.len(index)
      text.setSpan(ForegroundColorSpan(theme.color.colorAccent),0,indexLength,Spannable.SPAN_EXCLUSIVE_INCLUSIVE)
      text.setSpan(StyleSpan(Typeface.BOLD),0,indexLength,Spannable.SPAN_EXCLUSIVE_INCLUSIVE)
      table.insert(items,text)
    end
    AlertDialog.Builder(this)
    .setTitle(R.string.jesse205_thanksList)
    .setItems(items,nil)
    .setPositiveButton(android.R.string.ok,nil)
    .show()
   elseif key=="more" then
    if not(data.func) then
      return
    end
    if type(data.func)~="function" then
      MyToast("当前点击事件不是function")
    end
    data.func()
  end
end

function onConfigurationChanged(config)
  screenConfigDecoder:decodeConfiguration(config)
end

--插入大软件图标
if appInfo then
  local content=appInfo
  local iconResource=content.iconResource
  iconView.setBackgroundResource(iconResource)
  nameView.setText(content.name)
  messageView.setText(content.message)
  if content.clickable then
    iconCard.clickable=true
    iconCard.onClick=lambda view: callItem(appIconGroup,view,content)
  end
  local pain=nameView.getPaint()
  pain.setTypeface(content.typeface or Typeface.defaultFromStyle(Typeface.BOLD))
  if content.nameColor then
    nameView.setTextColor(content.nameColor)
  end
end

data={
  {--软件图标
    -1;
  };
  {--关于软件
    SettingsLayUtil.TITLE;
    title=R.string.jesse205_about_full;
  };
  {--软件版本
    SettingsLayUtil.ITEM;
    title=R.string.jesse205_nowVersion_app;
    --    summary=("%s (%s)"):format(BuildConfig.VERSION_NAME,BuildConfig.VERSION_CODE);
    summary=("%s(%s)"):format(BuildConfig.VERSION_NAME,versionCode);
    icon=R.drawable.ic_information_outline;
    key="version";
  };
  {--Jesse205Library版本
    SettingsLayUtil.ITEM;
    title=R.string.jesse205_nowVersion_jesse205Library;
    summary=("%s (%s)"):format(jesse205._VERSION,jesse205._VERSIONCODE);
    icon=R.drawable.ic_information_outline;
  };
}

--插入协议
if agreements then
  local fileBasePath=activity.getLuaPath("agreements/%s.html")
  for index,content in ipairs(agreements) do
    content[1]=SettingsLayUtil.ITEM_NOSUMMARY
    content.path=fileBasePath:format(content.name)
    content.key="html"
    content.newPage=true
    table.insert(data,content)
  end
end

--开发信息
if developers or openSourceLicenses or thanks then
  table.insert(data,{
    SettingsLayUtil.TITLE;
    title=R.string.jesse205_developerInfo;
  })

  --插入开发者
  if developers then
    for index,content in ipairs(developers) do
      table.insert(data,{
        SettingsLayUtil.ITEM_AVATAR;
        title="@"..content.name;
        summary=content.message;
        icon=content.avatar or getUserAvatarUrl(content.qq,content.imageSize);
        url=content.url,
        qq=content.qq;
        key="developer";
        newPage="newApp";
      })
    end
  end

  --插入开源许可
  if openSourceLicenses then
    table.insert(data,{
      SettingsLayUtil.ITEM_NOSUMMARY;
      title=R.string.jesse205_openSourceLicense;
      icon=R.drawable.ic_github;
      key="openSourceLicenses";
      newPage=true;
    })
  end
  --插入感谢名单
  if thanks then
    table.insert(data,{
      SettingsLayUtil.ITEM;
      title=R.string.jesse205_thanksList;
      summary=R.string.jesse205_ranking_random;
      icon=R.drawable.ic_emoticon_happy_outline;
      key="thanks";
      thanks=thanks;
    })
  end
end



if moreItem or copyright then
  --更多内容
  table.insert(data,{
    SettingsLayUtil.TITLE;
    title=R.string.jesse205_moreContent;
  })
  if moreItem then
    for index=1,#moreItem do
      local content=moreItem[index]
      content.key="more"
      table.insert(data,content)
    end
  end
  if copyright then--版权信息
    table.insert(data,{
      SettingsLayUtil.ITEM;
      title=R.string.jesse205_copyright;
      summary=copyright;
      icon=R.drawable.ic_copyright;
      key="copyright";
    })
  end
end


adapter=LuaCustRecyclerAdapter(AdapterCreator({
  getItemCount=function()
    return adapterEvents.getItemCount(data)
  end,
  getItemViewType=function(position)
    return adapterEvents.getItemViewType(data,position)
  end,
  onCreateViewHolder=function(parent,viewType)
    if viewType==-1 then
      local holder=LuaCustRecyclerHolder(portraitCardParent)
      return holder
     else
      return adapterEvents.onCreateViewHolder(onItemClick,nil,parent,viewType)
    end
  end,
  onBindViewHolder=function(holder,position)
    if position~=0 then
      adapterEvents.onBindViewHolder(data,holder,position)
    end
  end,
}))

recyclerView.setAdapter(adapter)
layoutManager=LinearLayoutManager()
recyclerView.setLayoutManager(layoutManager)
activity.registerForContextMenu(recyclerView)
recyclerView.onCreateContextMenu=function(menu,view,menuInfo)
  local data=data[menuInfo.position+1]
  if data and data.contextMenuEnabled then
    local key=data.key
    if data.contextMenuEnabled then--多个QQ群
      menu.setHeaderTitle(data.title)
      local menusList=data.menus
      for index,content in ipairs(menusList) do
        menu.add(0,index,0,content.title)
      end
      menu.setCallback({
        onMenuItemSelected=function(menu,item)
          local id=item.getItemId()
          local menuData=menusList[id]
          callItem(nil,nil,menuData)
        end
      })
    end
  end
end


screenConfigDecoder=ScreenFixUtil.ScreenConfigDecoder({
  fillParentViews={topCard},
  onDeviceChanged = function(device, oldDevice)
    if device=="pc" then
      local linearParams=iconCard.getLayoutParams()
      linearParams.height=-2
      linearParams.width=-2
      iconCard.setLayoutParams(linearParams)
     elseif oldDevice=="pc" then
      local linearParams=iconCard.getLayoutParams()
      linearParams.height=-1
      linearParams.width=-1
      iconCard.setLayoutParams(linearParams)
    end
  end
})

onConfigurationChanged(activity.getResources().getConfiguration())