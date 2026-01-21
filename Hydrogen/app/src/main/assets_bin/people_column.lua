require "import"
import "mods.muk"
设置视图("layout/simple")

波纹({fh,_more},"圆主题")


id, pre_data = ...
if type(pre_data) == "table" then
  _title.text = pre_data.title or pre_data.name or "专栏"
elseif type(pre_data) == "string" then
  _title.text = pre_data
else
  _title.text="专栏"
end

peple_column_item=获取适配器项目布局("people/people_column")

people_list_column_base=require "model.people_column":new(id)
:initpage(simple_recy,simplesr)

task(1,function()
  a=MUKPopu({
    tittle=_title.text,
    list={

    }
  })
end)