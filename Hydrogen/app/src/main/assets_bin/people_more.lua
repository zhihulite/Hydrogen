require "import"
import "mods.muk"

import "com.google.android.material.tabs.TabLayout"

波纹({fh,_more},"圆主题")


id,title=...

taskUI(function()
  a=MUKPopu({
    tittle=title,
    list={
    },
  })
end)


--判断是否为收藏夹
if title:find("收藏") then

 设置视图("layout/followed_collections")
  _title.text=title
  设置toolbar(toolbar)

  collection_pagetool=require "model.home_collection"
  :new()
  :initpage(collection_vpg,CollectiontabLayout)
  :setUrls({
    "https://api.zhihu.com/people/"..id.."/collections_v2?offset=0&limit=20",
    "https://api.zhihu.com/people/"..id.."/following_collections?offset=0"
  })

  if title:find("关注") then
    collection_vpg.setCurrentItem(2)
   else
    collection_pagetool:refer()
  end

  return
end

--不是就使用通用的布局
设置视图("layout/simple")

_title.text=title

simple_item=获取适配器项目布局("simple/card")

home_pagetool=require "model.people_more"
:new(id,title)
:initpage(simple_recy,simplesr)
:refer()