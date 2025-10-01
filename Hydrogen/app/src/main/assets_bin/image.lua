require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "mods.muk"
import "androidx.viewpager2.widget.ViewPager2"
import "com.dingyi.adapter.BaseViewPage2Adapter"
import "android.view.*"
import "com.nwdxlgzs.view.photoview.PhotoView"
import "androidx.viewpager2.widget.ViewPager2$OnPageChangeCallback"
import "com.bumptech.glide.Glide"
import "com.bumptech.glide.request.RequestOptions"
import "com.bumptech.glide.request.RequestListener"
import "com.bumptech.glide.load.engine.DiskCacheStrategy"
activity.setContentView(loadlayout("layout/image"))


波纹({download},"方自适应")

全屏()

local ls= this.getSharedData("imagedata")
function onDestroy()
  this.setSharedData("imagedata",nil)
end
local views={}

mls=luajson.decode(ls)

local now=mls[tostring(table.size(mls)-1)]

now_count.text=((now)+1)..""

all_count.text=(table.size(mls)-1)..""

local t=BaseViewPage2Adapter(this)

local base=
{
  FrameLayout,
  layout_height="-1",
  layout_width="-1",
  layoutTransition=LayoutTransition()
  .enableTransitionType(LayoutTransition.CHANGING),

  {
    PhotoView,
    id="ph",
    visibility=8,
    layout_height="-1",
    layout_width="-1",
  },
  {
    LinearLayout,
    layout_height="-1",
    layout_width="-1",
    gravity="center",
    id="pg",
    {
      ProgressBar,
      ProgressBarBackground=转0x(primaryc),
    },
  },
}

for i=0,table.size(mls)-2 do
  views[i]={}
  views[i].ids={}
  t.add(loadlayout(base,views[i].ids))

end

picpage.adapter=t

lastBitmap=""

picpage.registerOnPageChangeCallback(OnPageChangeCallback{--除了名字变，其他和PageView差不多

  onPageSelected=function(i)--选中的页数
    now_count.text=(i+1)..""

    local parent=views[i].ids
    if parent.ph.getDrawable()==nil then

      local url=mls[tostring(i)]
      if url:find("zhimg.com") then
        if url:find("%.webp?") then
          url=url:gsub("%.webp%?", ".jpg?")
         elseif url:find("%.png?") then
          url=url:gsub("%.png%?", ".jpg?")
        end
        url=url:gsub("qhd", "r")
        url=url:gsub("fhd", "r")
        url=url:gsub("720w", "r")
      end
      if url:sub(1,3)=="v2-"
        url="https://pic1.zhimg.com/100/"..url.."_r.jpg"
      end
      mls[tostring(i)]=url
      Glide
      .with(activity)
      .asDrawable()--强制gif支持
      .load(url)
      .diskCacheStrategy(DiskCacheStrategy.NONE)
      .listener(RequestListener{
        onResourceReady=function(a,b,c,d)
          parent.pg.visibility=8
          parent.ph.visibility=0
          return false
        end
      })
      .into(parent.ph)

      parent.pg.Visibility=8
      parent.ph.Visibility=0

    end
  end,

})


picpage.setCurrentItem(now)


ripple.onClick=function()
  local result=get_write_permissions(true)
  if result~=true then
    return false
  end
  local url=mls[""..picpage.getCurrentItem()]
  import "android.webkit.URLUtil"
  local 文件名=URLUtil.guessFileName(url,nil,nil)
  Http.download(url,Environment.getExternalStorageDirectory().toString().."/Pictures/Hydrogen/"..文件名,function(code,msg)
    if code==200 then
      提示("已保存到"..msg)
     else
      提示("保存失败")
    end
  end)
end