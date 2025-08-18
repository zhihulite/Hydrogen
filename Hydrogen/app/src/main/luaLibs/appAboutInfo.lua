appInfo={
  name=R.string.app_name,
  message="一个基于androlua+开发的第三方安卓知乎客户端",
  iconResource=R.mipmap.ic_launcher,
  browserUrl="https://huajiqaq.github.io/myhydrogen/",
  clickable=true,
}

--检查更新
function onUpdate()
  if ischeck==true then
    return MyToast("正在检测更新中")
  end
  ischeck=true
  local update_api="https://gitee.com/api/v5/repos/huaji110/huajicloud/contents/zhihu_hydrogen.html?access_token=abd6732c1c009c3912cbfc683e10dc45"
  Http.get(update_api,function(code,content)
    if code==200 then
      ischeck=false
      local content_json=luajson.decode(content)
      local content=base64dec(content_json.content)
      updateversioncode=tonumber(content:match("updateversioncode%=(.+),updateversioncode"))
      if updateversioncode > versionCode
        then
        local updateversionname=content:match("updateversionname%=(.+),updateversionname")
        local update_message="发现新版本"..updateversionname.."("..updateversioncode..")"
        updateinfo=content:match("updateinfo%=(.+),updateinfo")
        local editDialog=AlertDialog.Builder(this)
        .setTitle("发现新版本")
        .setMessage(update_message)
        .setPositiveButton("立即更新", {onClick=function()
            --在mods.muk中 已经导入所以可以直接用
            浏览器打开(updateurl)
        end})
        .setNegativeButton("暂不更新", nil)
        .show()
        updateurl=tostring(content:match("updateurl%=(.+),updateurl"))
       else
        MyToast("已是最新版本")
      end
     else
      MyToast("检测更新失败 请检查网络连接")
    end
  end)
end

--开发者们
developers={
  {
    name="没想到一个名字",
    qq=1906327347,
    message="很棒的开发者",
    url="mqqwpa://im/chat?chat_type=wpa&uin=1906327347" },
  {
    name="dingyi",
    qq=2187778735,
    message="软件初期奠定",
    url="mqqwpa://im/chat?chat_type=wpa&uin=2187778735" },
  {
    name="ZL",
    qq=3543515846,
    message="引诱苦手",
    url="mqqwpa://im/chat?chat_type=wpa&uin=3543515846" },
  {
    name="orz12",
    qq=0,
    avatar="https://avatars.githubusercontent.com/u/17450420?v=4",
    message="布局优化",
    url="https://gitee.com/orz12" },
  {
    name="0xdeadc0de",
    message="提交PR 修复BUG",
    qq=0,
    avatar="https://avatars.githubusercontent.com/u/26507452?v=4",
    url="https://github.com/1582421598" },
  {
    name="NullCola",
    message="绘制矢量图标",
    qq=0,
    avatar="https://cdn5.telesco.pe/file/dIqKSocvTeoZyC6H62pJklUCeE-CdACKaKdoOnYAh4NEqsN8j3eGPjfIapUf4g12wPfuR436kvf4FpgUd7RWb98pXDO-sIEVo3vjGSn1HpicBdLghGPA8Cojhq4kQ7MfAtYLB1DtNsGygXP2uiAUkY5tMhpK6oTLYM4MhBlQqs0LfuZf3mlShf1Gc4gPCk1AcZ9AOZMVqq9UXy_lObNlfvjvWg32L5Oe5SXOd89xdeoIYZh6CIF3WxWX63AZoybG-Uw3UclcmYNit1FDyc3GHIWVFvlY3Fx8qiFUDH18GIW-6dTDDhPlVhMBRUcjDD-U7Qrlw3FT-H2aSjsouzfhBA.jpg",
    url="https://t.me/NullCola" },
    
}

--启用开源许可
openSourceLicenses=true

moreItem={
  {
    SettingsLayUtil.ITEM_NOSUMMARY;
    title="更新日志";
    icon=R.drawable.ic_information_outline;
    browserUrl="https://huajiqaq.github.io/myhydrogen/update.html"
  },
  {
    SettingsLayUtil.ITEM_NOSUMMARY;
    title="提交bug";
    icon=R.drawable.ic_information_outline;
    func=function(view) -- 执行的函数
      newActivity("feedback")
    end,
  },
  {
    SettingsLayUtil.ITEM_NOSUMMARY;
    title="开源地址";
    icon=R.drawable.ic_github;
    browserUrl="https://gitee.com/huajicloud/Hydrogen/"
  },
  {
    SettingsLayUtil.ITEM_NOSUMMARY;
    title="TG群聊";
    icon=R.drawable.ic_github;
    browserUrl="https://t.me/Hydrogen_fzhihu"
  },
}

--[[格式：
{
  {
    name="群名称"; -- 群名称
    qqGroup=708199076; -- 群号
    contextMenuEnabled=true; -- 启用ContextMenu
  },
  {
    name="百度", -- 显示的名称
    url="http://www.baidu.com" -- 跳转连接
    browserUrl="http://www.baidu.com" -- 浏览器打开链接
    func=function(view) -- 执行的函数
    end,
  },
  --以此类推
}
]]

--[[
moreItem={
  {--交流群
    SettingsLayUtil.ITEM_NOSUMMARY;
    title=R.string.jesse205_qqGroup;
    icon=R.drawable.ic_account_group_outline;
    newPage="newApp";
    qqGroup=708199076;
    contextMenuEnabled=true;
    menus={
      {
        title="Edde 综合群",
        qqGroup=708199076,
      },
    };
  },
  {--频道
    SettingsLayUtil.ITEM_NOSUMMARY;
    title=R.string.jesse205_qqChannel;
    icon=R.drawable.ic_qq_channel;
    newPage="newApp";
    url="https://pd.qq.com/s/n51c4k";
  },
  {--支持
    SettingsLayUtil.ITEM_NOSUMMARY;
    title=R.string.jesse205_supportProject;
    icon=R.drawable.ic_wallet_giftcard;
    contextMenuEnabled=true;
    menus={
      {
        title="更多软件",
        url="https://jesse205.github.io/",
      },
    };
  },
}]]

--感谢名单
--[[
thanks={
  难忘的旋律={"PhotoView"},
  frrrrrits={"AnimeonGo（为Edde系列应用优化提供了重要参考）"}
}
]]

--版权信息
--copyright="Copyright (c) 2022, Jesse205"