require "import"
import "mods.muk"

collections_id=...


设置视图("layout/collections")
edgeToedge(nil,nil,function() local layoutParams = toolbar.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  toolbar.setLayoutParams(layoutParams); end)
collections_base=require "model.collections":new(collections_id)

task(1, function()
  collections_base:getData(function(tab)
    if not tab then return end
    _title.Text=tab.title

    local isfollow=tab.creator.id~=this.getSharedData("idx")

    if isfollow then
      local mview=pop.list[3]
      mview.onClick=function(text)
        if text=="关注" then
          zHttp.post("https://api.zhihu.com/collections/"..collections_id.."/followers","",posthead,function(code,json)
            if code==200 then
              mview.src=图标("close")
              mview.text="取关"
              提示("已关注")
              a=MUKPopu(pop)
            end
          end)
         else
          zHttp.delete("https://api.zhihu.com/collections/"..collections_id.."/followers/"..activity.getSharedData("idx"),head,function(code,json)
            if code==200 then
              提示("已取关")
              mview.src=图标("add")
              mview.text="关注"
              a=MUKPopu(pop)
            end
          end)
        end
      end
      table.remove(pop.list,2)
      if tab.is_following then
        mview.src=图标("close")
        mview.text="取关"
       else
        mview.src=图标("add")
        mview.text="关注"
      end
      a=MUKPopu(pop)
    end
  end)
end)

collection_pagetool=collections_base:initpage(collection_recy,collectionsr)

task(1, function()
  if collection_pagetool then collection_pagetool:refer() end
end)


波纹({fh,_more},"圆主题")

collection_item=获取适配器项目布局("collections/collections")

pop={
  tittle="收藏",
  list={

    {src=图标("email"),text="反馈",onClick=function()
        newActivity("feedback")
    end},

    {src=图标("close"),text="删除收藏夹",onClick=function()
        if not(collections_id) then
          return 提示("本地收藏不支持此功能")
        end
        双按钮对话框("删除收藏夹","删除收藏夹？该操作不可撤消！","是的","点错了",function(an)
          an.dismiss()
          zHttp.delete("https://api.zhihu.com/collections/"..collections_id,head,function(code,json)
            if code==200 then
              提示("已删除")
            end
          end)
        end,function(an)an.dismiss()end)
    end},
    {
      src=图标("close"),text="举报",onClick=function()
        local url="https://www.zhihu.com/report?id="..collections_id.."&type=favlist"
        newActivity("browser",{url.."&source=android&ab_signature=","举报"})
      end
    },
  }
}

a=MUKPopu(pop)