require "import"
import "mods.muk"


设置视图("layout/feedback")
设置toolbar(toolbar)
设置toolbar属性(toolbar,"反馈")
波纹({fh,_more},"圆主题")
波纹({send},"圆自适应")
edgeToedge(nil,nil,function() local layoutParams = toolbar.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  toolbar.setLayoutParams(layoutParams); end)


help_item={
  {--标题 内容 type1
    LinearLayout;
    layout_width="fill";
    layout_height="wrap";
    orientation="vertical";
    {
      TextView;
      layout_marginTop="12dp";
      layout_marginBottom="0dp";
      gravity="center_vertical";
      Typeface=字体("product-Bold");
      textColor=primaryc;
      layout_marginLeft="16dp";
      id="title";
      textSize=标题文字大小;
      lineHeight=标题行高;
    };
    {
      TextView;
      Typeface=字体("product");
      textColor=textc;
      layout_marginRight="16dp",
      layout_marginLeft="16dp",
      layout_margin="8dp";
      id="content";
      textSize=内容文字大小;
      lineHeight=内容行高;
    };
  };

  {--分割线 type2
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

  {--按钮 type3
    LinearLayout;
    layout_width="-1";
    layout_height="-1";
    orientation="vertical";
    gravity="right|bottom";
    clickable=true;
    {
      CardView;
      layout_height="56dp",
      radius="28dp";
      layout_margin="16dp";
      layout_marginRight="32dp";
      layout_marginBottom="32dp";
      CardBackgroundColor=primaryc;
      elevation="0";
      translationZ="4dp";
      alpha=1;
      id="post";
      {
        LinearLayout;
        Visibility=0,
        id="send",
        gravity="center",
        orientation="horizontal",
        {
          ImageView;
          src=图标("send");
          layout_height="24dp";
          layout_width="24dp";
          layout_margin="16dp";
          layout_marginRight="12dp";
          colorFilter=backgroundc,
        };
        {
          TextView;
          layout_marginRight="16dp";
          textColor=backgroundc,
          id="title";
          textSize=标题文字大小,
        };
      };
      {
        ProgressBar;
        id="progress",
        ProgressBarBackground=backgroundc,
        Visibility=8,
        layout_height="-1";
        layout_width="-1";
        padding="12dp",
      };
    };
  }

};


data = {
  {__type=1,title="提示", content="以下是一些常见问题 如果没有你的问题 请滑动到最底部 点击「仍要反馈问题」"},
  {__type=1,title="权限", content="Hydrogen仅会申请本地存储权限，用于保存本地收藏以及一文文章，如您用不到上述功能，您可以选择不授予。"},
  {__type=1,title="声明", content="Hydrogen 并无商业行为，仅作为个人兴趣业余开发。此应用并非破解，仅仅是一个简化后的浏览容器，相关付费内容仍需对应平台会员身份/购买。相关资源、文章版权归 知乎 原公司及原创作者所有。从未收集任何用户隐私，应用内所有内容直接请求官方接口，所有操作产生的数据都保留在用户本地。"},
  {__type=1,title="视频无法播放？页面无法加载？", content="请尝试升级你的Webview 如果无法升级你可手动安装Chrome 然后在软件设置点击切换webview 即可切换使用谷歌浏览器的WebView而并非系统WebView"},
  {__type=1,title="软件有点卡？", content="没错是这样的"},
  {__type=1,title="为什么出现乱码？", content="知乎已封禁你当前设备登录该账号 出现这种情况只能等主动解除"},
  {__type=1,title="为什么显示不全？", content="这是知乎api对于未登录用户的限制 未登录不可查看全文 于2024年5月开始实施 详情可自行搜索"},
  {__type=1,title="软件安不安全？", content="通过网页登录不会存储你的账号信息，所有数据均直接请求于官方接口"},
  {__type=1,title="为什么刷新出重复内容", content="向上滑为刷新以前的内容 向下为加载更多内容  如果向下遇到很多重复内容 建议卸载本app 这个问题我无法解决"},
  {__type=3,title="仍要反馈问题",send={
      onClick=function(send)
        send.setVisibility(8)
        --在listview的写法
        local progress=获取listview顶部布局(send).Tag.progress
        progress.setVisibility(0)
        taskUI(300,function()
          send.setVisibility(0) progress.setVisibility(8)
          local 单选列表={"使用Gitee Issues反馈","使用Github Issues反馈","使用QQ反馈"}
          local dofun={
            function()
              浏览器打开("https://gitee.com/huajicloud/Hydrogen/issues")
            end,
            function()
              浏览器打开("https://github.com/zhihulite/Hydrogen/issues")
            end,
            function()
              local uri=Uri.parse("mqqwpa://im/chat?chat_type=wpa&uin=3543515846")
              if not(pcall(activity.startActivity,Intent(Intent.ACTION_VIEW,uri))) then
                提示("你没安装QQ")
               else
                提示("跳转成功 请使用QQ反馈Bug")
              end
          end}
          dialog=AlertDialog.Builder(this)
          .setTitle("请选择反馈方式")
          .setSingleChoiceItems(单选列表,-1,{onClick=function(v,p)
              dofun[p+1]()
              dialog.dismiss()
          end})
          .setPositiveButton("关闭",nil)
          .show()
        end)
      end
  }}
}


adp=LuaMultiAdapter(this,data,help_item)

for k, v in ipairs(data) do
  if v.__type == 1 then
    table.insert(data, k + 1, {__type = 2})
  end
end


help_list.setAdapter(adp)



function onOptionsItemSelected()
  activity.finish()
end
