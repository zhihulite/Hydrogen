require "import"
import "mods.muk"
 设置视图("layout/simple")
波纹({fh,_more},"圆主题")
edgeToedge(nil,nil,function() local layoutParams = topbar.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  topbar.setLayoutParams(layoutParams); end)


波纹({fh,_more},"圆主题")

_title.text="推荐关注收藏夹"


collection_recommend_item=获取适配器项目布局("collections/collection_recommend")


collection_recommend_pagetool=require "model.collection_recommend":new(id)
:initpage(simple_recy,simplesr)

taskUI(function()
  a=MUKPopu({
    tittle=_title.text,
    list={

    }
  })
end)