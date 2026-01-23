require "import"
import "android.app.*"
import "andoid.os.*"
import "android.widget.*"
import "android.view.*"
import "mods.muk"
import "com.google.android.material.textfield.TextInputLayout"
import "com.google.android.material.textfield.TextInputEditText"


import "com.google.android.material.chip.ChipGroup"
import "com.google.android.material.chip.Chip"
MDC_R=luajava.bindClass"com.google.android.material.R"


设置视图("layout/search")
if activity.getSharedData("searchv1") ==nil then
  双按钮对话框("新搜索提示","由于知乎自带搜索限制过多，现可以在应用内透过搜索引擎搜索知乎站点内容\n您可以在设置中更改搜索引擎（默认必应）或回归知乎自带搜索","去设置","知道了",function(an)
    activity.setSharedData("searchv1","x")
    newActivity("settings")
    关闭对话框(an)
    end,function(an)
    activity.setSharedData("searchv1","x")
    关闭对话框(an)
  end)
end

初始化搜索历史记录数据()

function 搜索(text)
  local search_text=text or search_view.getQuery().toString();
  if #(tostring(search_text):gsub(" ",""))<1 then
    提示("请输入您要搜索的内容")
   else
    -- UI 优化：跳转前隐藏键盘
    local imm = this.getSystemService(Context.INPUT_METHOD_SERVICE)
    imm.hideSoftInputFromWindow(search_view.getWindowToken(), 0)
    
    if this.getSharedData("搜索引擎")==nil
      this.setSharedData("搜索引擎","https://www.zhihu.com/search?type=content&q=")
    end
    search_eg=this.getSharedData("搜索引擎")
    newActivity("browser",{search_eg..urlEncode(search_text)})
    保存搜索历史记录(search_text)
  end
end

edgeToedge(nil,nil,function() local layoutParams = topbar.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  topbar.setLayoutParams(layoutParams); end)
import "com.google.android.material.card.MaterialCardView"

波纹({_back,search,_delete},"圆主题")

if this.getSharedData("关闭热门搜索")=="true" then
  热门搜索布局.Visibility=8
 else
  itemc=获取适配器项目布局("search/search")
  adp=LuaAdapter(activity,itemc)
  search_list.adapter=adp
  local url = "https://api.zhihu.com/search/top_search"
  zHttp.get(url,head,function(code,content)
    if code==200 then
      local data=luajson.decode(content)
      for k,v in ipairs(data.top_search.words) do
        taskUI(50,function()adp.add{id内容=v.query,标题=v.display_query}end)
      end
     else
      提示("获取热门搜索失败 "..content)
    end
  end)
  search_list.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick=function(parent,v,pos,id)
      搜索(v.Tag.id内容.Text)
    end
  })
end

search_view.setOnQueryTextListener(SearchView.OnQueryTextListener{
  onQueryTextSubmit=function(str)
    搜索()
  end,
  onQueryTextChange=function(str)
  end
})


array_adp=ArrayAdapter(activity,android.R.layout.simple_list_item_1)
suggest_list.setAdapter(array_adp)
suggest_list.onItemClick=function(l,v,p,s)--列表点击事件
  搜索(tostring(v.Text))
  taskUI(300,function()
    search_editor.text=""
  end)
end

local androidxR=luajava.bindClass "androidx.appcompat.R"
search_editor=search_view.findViewById(androidxR.id.search_src_text)
search_editor.addTextChangedListener{
  onTextChanged=function(s)
    if #(tostring(search_editor.text):gsub("\n",""):gsub(" ",""))<1 then
      未搜索布局.Visibility=0
      搜索布局.Visibility=8
     else
      未搜索布局.Visibility=8
      搜索布局.Visibility=0
      local url = "https://www.zhihu.com/api/v4/search/suggest?q="..urlEncode(tostring(s))
      array_adp.clear()
      zHttp.get(url,head,function(code,content)
        if code==200 then
          local data=luajson.decode(content)
          for k,v in ipairs(data.suggest) do
            taskUI(50,function()array_adp.add(v.query)end)
          end
         else
          提示("获取搜索关键词失败 "..content)
        end
      end)
    end
  end
}

search.onClick=function()
  搜索()
end

_delete.onClick=function()
  清除搜索历史记录()
  chipgroup.removeAllViews()
end

local function createchip(text,id)
  return loadlayout2({
    Chip_Input;
    layout_width="wrap_content";
    layout_height="wrap_content";
    text=text;
    checkable=false;
    EnsureMinTouchTargetSize=false,
    OnCloseIconClickListener=function(view)
      MySearchHistoryManager.remove(id)
      view.getParent().removeView(view)
    end,
    onClick=function()
      搜索(text)
    end
  })
end

function 加载搜索记录列表()
  search_history=获取搜索历史记录()
  chipgroup.removeAllViews()
  for _,item ipairs(search_history) do
    local text=item.value
    local id=item.id
    chipgroup.addView(createchip(text,id))
  end
end

加载搜索记录列表()

search_view.setFocusable(true);
search_view.requestFocus();
search_view.postDelayed(Runnable{
  run=function()
    local imm= this.getSystemService(Context.INPUT_METHOD_SERVICE);
    imm.toggleSoftInput(InputMethodManager.SHOW_IMPLICIT, InputMethodManager.HIDE_NOT_ALWAYS);
    --imm.showSoftInput(search_view, InputMethodManager.SHOW_IMPLICIT);
  end
}, 100);

function onStart()
  加载搜索记录列表()
end