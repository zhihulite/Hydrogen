require "import"
import "android.widget.*"
import "android.view.*"
import "mods.muk"
import "android.text.method.LinkMovementMethod"
import "com.google.android.material.bottomsheet.*"
import "android.view.inputmethod.InputMethodManager"
import "com.google.android.material.textfield.TextInputLayout"
import "com.google.android.material.textfield.TextInputEditText"
import "com.google.android.material.chip.ChipGroup"
import "com.google.android.material.chip.Chip"
import "com.google.android.material.floatingactionbutton.FloatingActionButton"

comment_id, comment_type, 保存路径, 父回复id = ...
设置视图("layout/comment")

local function initLocalComments(is_chat)
  internetnet.setVisibility(8)
  local list_view = is_chat and localcomment or local_comment_list
  list_view.setVisibility(0)
  
  local item_lay = 获取适配器项目布局("comment/comments_reply")
  local sadapter = LuaAdapter(activity, item_lay)
  local_comment_list.setAdapter(sadapter) -- 这里的逻辑在原代码中有些混淆，统一使用 local_comment_list 承载
  if is_chat then local_comment_list.setVisibility(0); localcomment.setVisibility(0) end

  local function addComment(name, content, id, has_replies)
    local span = content:find("http") and setstyle(Html.fromHtml(content)) or Html.fromHtml(content)
    sadapter.add{
      标题 = name,
      预览内容 = {
        text = span,
        MovementMethod = LinkMovementMethod.getInstance(),
        onLongClick = function(v)
          activity.getSystemService(Context.CLIPBOARD_SERVICE).setText(v.Text)
          提示("复制文本成功")
        end
      },
      提示内容 = { Visibility = has_replies and 0 or 8 },
      id内容 = id
    }
  end

  if is_chat then
    local file = io.open(comment_id, "r")
    if file then
      local author, content = nil, ""
      for line in file:lines() do
        if line:find('author="') then
          author = line:match('author="([^"]+)"')
          content = ""
         else
          content = content .. line
          local e = content:find('"', 10)
          if e then
            addComment(author, content:sub(9, e - 1))
            author, content = nil, ""
          end
        end
      end
      file:close()
    end
    _title.text = "对话列表"
   else
    local files = luajava.astable(File(保存路径.."/fold/").listFiles())
    for _, f in ipairs(files) do
      local raw = 读取文件(tostring(f))
      local name = raw:match('author="([^"]*)"')
      local content = raw:match('content="(.-)"')
      local has_more = raw:find("author", raw:find("author") + 1)
      addComment(name, content, f.Name, has_more ~= nil)
    end
    _title.text = "保存的评论 "..#sadapter.getData().."条"
  end

  local_comment_list.setOnItemClickListener(AdapterView.OnItemClickListener{
    onItemClick = function(id, v, zero, one)
      if v.Tag.提示内容.getVisibility() == 0 then
        if is_chat then 提示("当前已在该对话列表内")
        else newActivity("comment", {保存路径.."/fold/"..v.Tag.id内容.text, "local_chat"}) end
      end
    end
  })
end

if not comment_type:find("local") then
  comment_base = require "model.comment":new(comment_id, comment_type)
  local comment_item = 获取适配器项目布局("comment/comment")
  comment_pagetool = comment_base:initpage(comment_recy, commentsr, comment_item)
  
  send.onClick = function()
    发送评论(comment_type == "comments" and comment_id or "", comment_type == "comments" and "回复该子评论")
  end
  _title.text = "对话列表"
 else
  initLocalComments(comment_type == "local_chat")
end

comment_recy.addOnScrollListener(RecyclerView.OnScrollListener{
  onScrolled = function(v, s, j) 
    mainLay.backgroundColor = v.canScrollVertically(-1) and 转0x(barc) or 转0x(backgroundc)
  end
})

edgeToedge(mainLay, {send, comment_recy})
波纹({fh, _more}, "圆主题")

task(1, function()
  local menu_list = {
    {src=图标("format_align_left"), text="按时间顺序", onClick=function()
        comment_pagetool:setUrlItem(comment_base:getUrlByType("ts")):clearItem():refer(nil,nil,true)
    end},
    {src=图标("notes"), text="按默认顺序", onClick=function()
        comment_pagetool:setUrlItem(comment_base:getUrlByType("score")):clearItem():refer(nil,nil,true)
    end}
  }
  a = MUKPopu({ tittle = "评论", list = menu_list })
end)