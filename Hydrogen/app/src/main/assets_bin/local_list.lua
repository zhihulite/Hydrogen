require "import"
import "mods.muk"

设置视图("layout/local_list")

设置toolbar(toolbar)

波纹({fh,_more},"圆主题")
_title.Text="已保存的内容"
edgeToedge(nil,nil,function() local layoutParams = mainLay.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  mainLay.setLayoutParams(layoutParams); end)

local_item=获取适配器项目布局("local_item/local_item")


if not 文件是否存在(内置存储文件()) then
  xpcall(function()
    创建文件夹(内置存储文件())
    end,function()
  end)
end
if not 文件是否存在(内置存储文件("Download")) then
  xpcall(function()
    创建文件夹(内置存储文件("Download"))
    end,function()
  end)
end

if Build.VERSION.SDK_INT >=30 then

  if activity.getSharedData("安卓11迁移文件夹0.02")~="true" then
    tishi=AlertDialog.Builder(this)
    .setTitle("提示")
    .setMessage("检测到系统版本大于安卓10 由于安卓的限制 导致无法保存文件在带有特殊字符串的文件夹 但应用私有目录无限制 你必须迁移文件才能使用本功能 请点击下方立即迁移 迁移后 卸载软件或清除软件数据也会删除对应保存的数据 为了应对 你可以在软件设置中手动管理文件")
    .setCancelable(false)
    .setPositiveButton("立即迁移",nil)
    .setNegativeButton("暂不迁移",{onClick=function() tishi.dismiss() end})
    .show()
    tishi.getButton(tishi.BUTTON_POSITIVE).onClick=function()
      local result=get_write_permissions(true)
      if result~=true then
        return false
      end

      local 默认文件夹=Environment.getExternalStorageDirectory().toString().."/Hydrogen"
      local 私有目录=activity.getExternalFilesDir(nil).toString()
      if 文件夹是否存在(默认文件夹) then
        if not 文件夹是否存在(私有目录) then
          创建文件夹(私有目录)
        end
        if not 文件夹是否存在(私有目录.."/Hydrogen") then
          创建文件夹(私有目录.."/Hydrogen")
        end
        mvdir(默认文件夹,私有目录.."/Hydrogen",function()
          activity.setSharedData("安卓11迁移文件夹0.02","true")
          tishi.dismiss()
          提示("迁移成功")
        end)
       else
        activity.setSharedData("安卓11迁移文件夹0.02","true")
        tishi.dismiss()
        提示("无可迁移文件夹")
      end
    end

    tishi.findViewById(android.R.id.message).TextIsSelectable=true
  end
end

notedata={}
noteadp=LuaAdapter(activity,notedata,local_item)
local_listview.setAdapter(noteadp)

tab={"全部","回答","想法","文章"}
for i,v in ipairs(tab) do
  localtab:addTab(v,function()
    noteadp.clear()
    find_type=v
    加载本地列表()
    noteadp.notifyDataSetChanged()
  end,3)
end
localtab:showTab(1)

function 加载本地列表()
  if #luajava.astable(File(内置存储文件("Download")).listFiles())==0 then
    localtab.ids.load.parent.setVisibility(8)
    empty.setVisibility(0)
    return false
  end

  local find_type=find_type

  if find_type =="全部" or find_type==nil then
    find_type="all"
   elseif find_type =="回答" then
    find_type="answer_id"
   elseif find_type=="想法" then
    find_type="pin"
   elseif find_type=="文章" then
    find_type="article"
   elseif find_type=="视频" then
    find_type="video"
  end

  notedata={}
  if find_type == "all" then
    --获取软件存储目录下文件夹列表
    local save_paths=luajava.astable(File(内置存储文件("Download")).listFiles())
    for _,path in ipairs(save_paths) do
      --保存格式为 标题/作者名称 获取标题 转为字符串
      local title_path=tostring(path)
      local _,name=title_path:match("(.+)/(.+)")
      notedata[#notedata+1]={
        timestamp=path.lastModified(),
        标题=name,
        file=path,
      }
    end

    table.sort(notedata,function(a, b)
      return a.timestamp > b.timestamp
    end)
   else

    --获取软件存储目录下文件夹列表
    local save_paths=luajava.astable(File(内置存储文件("Download")).listFiles())
    for _,path in ipairs(save_paths) do
      --保存格式为 标题/作者名称 获取标题 转为字符串
      local title_path=tostring(path)
      --获取作者名称文件夹
      local author_path=luajava.astable(File(title_path).listFiles())
      --获取详情文件夹第一个内容
      local detail_path=tostring(author_path[1]).."/detail.txt"
      local detail_content=读取文件(detail_path)
      local _,name=title_path:match("(.+)/(.+)")
      --查找是否符合
      if detail_content:find(find_type) then
        notedata[#notedata+1]={
          timestamp=path.lastModified(),
          标题=name,
          file=path,
        }
      end
    end
  end

  table.sort(notedata,function(a, b)
    return a.timestamp > b.timestamp
  end)

  noteadp=LuaAdapter(activity,notedata,local_item)
  local_listview.setAdapter(noteadp)
end

加载本地列表()

function checktitle(find_content)
  local oridata=noteadp.getData()
  for i=#oridata,1,-1 do
    if not oridata[i].标题:find(find_content) then
      table.remove(oridata, i)
      noteadp.notifyDataSetChanged()
    end
  end
  提示("搜索完毕 共搜索到"..#noteadp.getData().."条数据")
  if #noteadp.getData()==0 then
    加载本地列表()
  end
end

local_listview.setOnItemClickListener(AdapterView.OnItemClickListener{
  onItemClick=function(id,v,zero,one)
    本地列表(v.Tag.标题.Text)
end})

local_listview.setOnItemLongClickListener(AdapterView.OnItemLongClickListener{
  onItemLongClick=function(id,v,zero,one)
    双按钮对话框("删除","删除该内容？该操作不可撤消！","是的","点错了",function(an)删除文件(内置存储文件("Download/"..v.Tag.标题.Text))
      an.dismiss()
      加载本地列表()
      提示("已删除")end,function(an)an.dismiss()end)
    return true
end})

local item={
  LinearLayout,
  orientation="vertical",
  layout_width="fill",
  {
    TextView,
    id="mytext",
    layout_width="match_parent",
    layout_height="wrap_content",
    textSize="16sp",
    gravity="center_vertical",
    Typeface=字体("product-Bold");
    paddingStart=64,
    paddingEnd=64,
    minHeight=192,
  },
}

function 本地列表(path)
  local gd2 = GradientDrawable()
  gd2.setColor(转0x(backgroundc))--填充
  local radius=dp2px(16)
  gd2.setCornerRadii({radius,radius,radius,radius,0,0,0,0})--圆角
  gd2.setShape(0)--形状，0矩形，1圆形，2线，3环形
  local dann={
    LinearLayout;
    layout_width="-1";
    layout_height="-1";
    {
      LinearLayout;
      orientation="vertical";
      layout_width="-1";
      layout_height="-2";
      Elevation="4dp";
      BackgroundDrawable=gd2;
      {
        CardView;
        layout_gravity="center",
        background=cardedge,
        radius="3dp",
        Elevation="0dp";
        layout_height="6dp",
        layout_width="56dp",
        layout_marginTop="12dp";
      };
      {
        TextView;
        layout_width="-1";
        layout_height="-2";
        textSize="20sp";
        layout_marginTop="24dp";
        layout_marginLeft="24dp";
        layout_marginRight="24dp";
        Text="选择作者";
        Typeface=字体("product-Bold");
        textColor=primaryc;
      };
      {
        ListView;
        padding="8dp",
        layout_width="-1";
        layout_height="-1";
        id="listview",
      };
      {
        LinearLayout;
        orientation="horizontal";
        layout_width="-1";
        layout_height="-2";
        gravity="right|center";
        {
          MaterialButton;
          layout_marginTop="16dp";
          layout_marginLeft="16dp";
          layout_marginRight="16dp";
          layout_marginBottom="16dp";
          textColor=backgroundc;
          text="关闭";
          Typeface=字体("product-Bold");
          id="close_button",
        };
      };
    };
  };

  local tmpview={}
  local bottomSheetDialog = BottomSheetDialog(this)
  bottomSheetDialog.setContentView(loadlayout(dann,tmpview))
  local an=bottomSheetDialog.show()
  tmpview.close_button.onClick=function()
    an.dismiss()
  end;

  local adp=LuaAdapter(activity,item)

  for v,s in pairs(luajava.astable(File(内置存储文件("Download/"..path.."/")).listFiles())) do
    adp.add({
      mytext=s.Name,
    })
  end

  local listview=tmpview.listview
  listview.setAdapter(adp)

  listview.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick=function(id,v,zero,one)
      newActivity("local",{path,v.Tag.mytext.Text})
      an.dismiss()
  end})

  listview.setOnItemLongClickListener(AdapterView.OnItemLongClickListener{
    onItemLongClick=function(id,v,zero,one)
      双按钮对话框("删除","删除该内容？该操作不可撤消！","是的","点错了",function(an)删除文件(内置存储文件("Download/"..path.."/"..v.Tag.mytext.Text))
        an.dismiss()
        --当内容为1个时 删除后该保存内容就没有了意义 所以当删除时连同清理该保存内容
        if id.adapter.getCount()==1 then
          提示("已删除 由于删除后无内容保存 所以已自动关闭")
          删除文件(内置存储文件("Download/"..path))
          --访问全局变量的an
          _G["an"].dismiss()
          加载本地列表()
         else
          id.adapter.remove(zero)
          提示("已删除")
        end
      end,function(an)an.dismiss()end)
      return true
  end})

end

function zip(input,output,callback)
  local function main(input,output)
    -- 不使用 com.androlua.util.ZipUtil 因为不能循环处理目录
    local ZipUtil=luajava.bindClass "com.androlua.ZipUtil"
    ZipUtil.zip(input,output)
  end
  activity.newTask(main,function()
    callback()
  end).execute({input,output})
end

function unzip(filePath,output,callback)
  local function main(filePath,output)
    -- 不使用 com.androlua.util.ZipUtil 因为不能循环处理目录
    local ZipUtil=luajava.bindClass "com.androlua.ZipUtil"
    ZipUtil.unzip(filePath,output)
  end
  activity.newTask(main,function()
    callback()
  end).execute({filePath,output})
end

function mvdir(filePath,output,callback)
  local function main(filePath,output)
    local LuaUtil=luajava.bindClass "com.androlua.LuaUtil"
    local File=luajava.bindClass "java.io.File"
    LuaUtil.copyDir(filePath,output)
    LuaUtil.rmDir(File(filePath))
  end
  activity.newTask(main,function()
    callback()
  end).execute({filePath,output})
end

taskUI(function()
  a=MUKPopu({
    tittle="已保存的内容",
    list={
      {
        src=图标("search"),text="搜索已保存的内容",onClick=function()
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
      {src=图标("email"),text="反馈",onClick=function()
          newActivity("feedback")
      end},
      {src=图标("info"),text="导出/导入",onClick=function()

          local result=get_write_permissions(true)
          if result~=true then
            return false
          end

          local 单选列表={"导出数据","导入数据"}
          local dofun={
            function()
              local path=Environment.getExternalStorageDirectory().toString()
              zip(内置存储文件(""),path,function()
                提示("导出成功,导出文件在"..path.."/Hydrogen.zip")
              end)
            end,
            function()
              local path=Environment.getExternalStorageDirectory().toString().."/Hydrogen.zip"
              local filesdir=activity.getExternalFilesDir(nil).toString()
              if 文件是否存在(path) then
                unzip(path,内置存储文件(""),function()
                  删除文件(path)
                  提示("导入成功 已将导出文件自动删除")
                end)
               else
                return 提示("导入失败 请检查是否导出或误删文件")
              end
          end}
          dialog=AlertDialog.Builder(this)
          .setTitle("请选择")
          .setSingleChoiceItems(单选列表,-1,{onClick=function(v,p)
              dofun[p+1]()
              dialog.dismiss()
          end})
          .setPositiveButton("关闭",nil)
          .show()

      end},
      {src=图标("info"),text="问题",onClick=function()
          提示("文件保存在"..内置存储("Hydrogen/download"))
      end},
    }
  })
end)