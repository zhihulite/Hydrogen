require "import"

import "mods.muk"
设置视图("layout/history")
设置toolbar(toolbar)
edgeToedge(nil,nil,function() local layoutParams = mainLay.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  mainLay.setLayoutParams(layoutParams); end)


波纹({fh,_more},"圆主题")

初始化历史记录数据()

history_list.setDividerHeight(0)
local HistoryList = 获取历史记录()
if (#HistoryList==0)then
  history_list.setVisibility(8)
  histab.ids.load.parent.setVisibility(8)
  empty.setVisibility(0)
end



itemc=获取适配器项目布局("history/history")


adp=LuaAdapter(activity,itemc)

history_list.adapter=adp


mytab={"全部","回答","想法","文章","问题","用户","视频"}

import "android.text.SpannableString";
import "android.text.Spanned";
import "android.text.style.RelativeSizeSpan";
import "android.widget.TextView";

import "android.text.style.LineHeightSpan"

--https://itimetraveler.github.io/2017/01/03/%E3%80%90Android%E3%80%91TextView%E4%B8%AD%E4%B8%8D%E5%90%8C%E5%A4%A7%E5%B0%8F%E5%AD%97%E4%BD%93%E5%A6%82%E4%BD%95%E4%B8%8A%E4%B8%8B%E5%9E%82%E7%9B%B4%E5%B1%85%E4%B8%AD%EF%BC%9F/
function getCustomTextPaint(sourcePaint)
  local customPaint = TextPaint(sourcePaint)
  customPaint.setTextSize(dp2px(12))
  return customPaint
end

-- 创建一个自定义的 ReplacementSpan 子类，用于垂直居中文本
CustomVerticalCenterSpan = luajava.override(ReplacementSpan, {
  -- 重写 getSize 方法，计算替换文本的尺寸
  getSize = function(super, paint, text, start, endPos)
    -- 获取子字符串
    local subText = text.subSequence(start, endPos)
    -- 创建一个自定义的 TextPaint 对象，用于测量文本宽度
    local customPaint = getCustomTextPaint(paint)
    -- 返回子字符串的宽度
    return customPaint.measureText(subText.toString())
  end,
  -- 重写 draw 方法，绘制垂直居中的文本
  draw = function(super, canvas, text, start, endPos, x, top, y, bottom, paint)
    -- 获取子字符串
    local subText = text.subSequence(start, endPos)
    -- 创建一个自定义的 TextPaint 对象
    local customPaint = getCustomTextPaint(paint)
    -- 获取自定义 TextPaint 的字体度量信息
    local fontMetrics = customPaint.getFontMetricsInt()
    -- 获取当前布局的行高
    local lineHeight = paint.getFontSpacing() -- 这里简化了行高的获取，实际可能需要从 Layout 对象获取
    -- 行高 = 字体高度 + 额外间距
    -- 文本的基线位置 = top + 额外间距的一半
    local extraSpacing = lineHeight - (fontMetrics.bottom - fontMetrics.top)
    local textY = top + math.floor(extraSpacing / 2) - fontMetrics.ascent
    -- 绘制文本
    canvas.drawText(subText.toString(), x, textY, customPaint)
  end
})

function 合成文本(type, htmlText)
  if find_type and find_type~="全部" then
    return htmlText
  end
  -- 创建一个 SpannableString 对象来存储类型文本
  local typeText = SpannableString(type);
  -- 获取类型文本的长度
  local numCharsToChange = String(type).length();
  -- 设置文本的大小和垂直居中
  typeText.setSpan(CustomVerticalCenterSpan, 0, numCharsToChange, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
  -- 创建一个 SpannableString 对象来组合类型文本和 HTML 文本
  local combinedText = SpannableString(type .. " " .. tostring(htmlText));
  -- 复制类型文本的样式到组合文本的开头
  TextUtils.copySpansFrom(typeText, 0, typeText.length(), Object, combinedText, 0);
  -- 复制 HTML 文本的样式到组合文本的结尾
  TextUtils.copySpansFrom(htmlText, 0, htmlText.length(), Object, combinedText, typeText.length() + 1);
  -- 返回组合后的文本
  return combinedText;
end

function addItemData(item)
  local 类型=item.type
  local 预览内容=item.preview
  local 标题=合成文本(类型,Html.fromHtml(item.title))
  local id=item.id
  local add={}
  add.标题=标题
  add.id内容=类型.."分割"..id
  if 预览内容=="" then
    预览内容="无预览内容"
  end
  add.预览内容=Html.fromHtml(预览内容)
  adp.add(add)
end

function 加载历史记录()
  local find_type=find_type
  if find_type=="全部" or find_type==nil then
    find_type=""
  end
  adp.clear()
  local _,err=pcall(function()
    for _,item ipairs(获取历史记录()) do
      local 类型=item.type
      if 类型:find(find_type) then
        addItemData(item)
      end
    end
  end)
  if _==false then
    提示("获取数据异常 请先清理历史记录")
  end
end

for i,v in ipairs(mytab) do
  histab:addTab(v,function()
    adp.clear()
    find_type=v
    加载历史记录()
    adp.notifyDataSetChanged()
  end,3)
end
histab:showTab(1)

加载历史记录()

function checktitle(str)
  adp.clear()
  for _,item ipairs(获取历史记录()) do
    local 过滤内容=item.toString()
    if 过滤内容:find(str) then
      addItemData(item)
    end
  end
  提示("搜索完毕 共搜索到"..#adp.getData().."条数据")
  if #adp.getData()==0 then
    加载历史记录()
  end
end

history_list.onItemLongClick=function(l,v,c,b)
  local _type, id = v.Tag.id内容.text:match("(.-)分割(.*)")
  双按钮对话框("删除","删除该历史记录？该操作不可撤消！","是的","点错了",function(an)
    MyHistoryManager.remove(id,_type)
    an.dismiss()
    提示("已删除")
  end
  ,function(an)an.dismiss()end)
  return true
end

history_list.onItemClick=function(l,v,c,b)
  nTView=v
  点击事件判断(v.Tag.id内容.text)
end


taskUI(function()
  a=MUKPopu({
    tittle="历史记录",
    list={
      {
        src=图标("search"),text="搜索历史记录",onClick=function()
          InputLayout={
            LinearLayout;
            orientation="vertical";
            Focusable=true,
            FocusableInTouchMode=true,
            {
              EditText;
              hint="输入";
              layout_marginTop="5dp";
              layout_marginLeft="10dp",
              layout_marginRight="10dp",
              layout_width="match_parent";
              layout_gravity="center",
              id="edit";
            };
          };

          AlertDialog.Builder(this)
          .setTitle("请输入")
          .setView(loadlayout(InputLayout))
          .setPositiveButton("确定", {onClick=function() checktitle(edit.text) end})
          .setNegativeButton("取消", nil)
          .show();

      end},
      {
        src=图标("list_alt"),text="清理历史记录",onClick=function()
          双按钮对话框("提示","确定要清理历史记录吗 清除将会重启应用","我知道了","暂不清理",function(an)
            关闭对话框(an)
            清除历史记录()
            提示("已清除,即将重启")
            taskUI(200,function()
              import "android.os.Process"
              local intent =activity.getBaseContext().getPackageManager().getLaunchIntentForPackage(activity.getBaseContext().getPackageName());
              intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
              activity.startActivity(intent);
              Process.killProcess(Process.myPid());
            end)
            end,function(an)
            关闭对话框(an)
          end)

      end},
    }
  })
end)