require "import"
import "mods.muk"
设置视图("layout/simple")
波纹({fh,_more},"圆主题")
edgeToedge(nil,nil,function() local layoutParams = topbar.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  topbar.setLayoutParams(layoutParams); end)

title,people_id=...
_title.text=title

if title:find("关注") then
  类型="followees"
 elseif title:find("粉丝") then
  类型="followers"
 elseif title:find("点赞")
  类型="voter"
 else
  类型="block_all"
end

peopeo_list_item=获取适配器项目布局("people/people_list")

people_list_base=require "model.people_list":new(people_id,类型)
people_list_pagetool=people_list_base:initpage(simple_recy,simplesr)

taskUI(function()
  if people_list_pagetool then people_list_pagetool:refer() end
end)

taskUI(function()
  if 类型:find("block") then
    a=MUKPopu({
      tittle=_title.text,
      list={
        {src=图标("format_align_left"),text="全部黑名单",onClick=function()
            people_list_pagetool
            :setUrlItem(people_list_base:getUrl("block_all"))
            :clearItem()
            :refer()
        end},
        {src=图标("notes"),text="瓦力黑名单",onClick=function()
            people_list_pagetool
            :setUrlItem(people_list_base:getUrl("block_walle"))
            :clearItem()
            :refer()
        end},
      }
    })
   else
    a=MUKPopu({
      tittle=_title.text,
      list={

      }
    })
  end
end)