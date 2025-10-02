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
import "android.graphics.Bitmap"
import "android.os.Environment"
import "java.io.File"
import "java.io.FileOutputStream"
import "java.lang.System"
import "android.content.FileProvider"
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

-- 长按分享图片功能
ripple.onLongClick=function()
  -- 获取当前显示的图片View
  local currentIndex = picpage.getCurrentItem()
  local currentView = views[currentIndex].ids.ph
  
  -- 检查是否有图片
  if currentView.getDrawable() == nil then
    提示("图片尚未加载完成")
    return true
  end
  
  -- 将图片转换为Bitmap
  local bitmap = currentView.getDrawable().getBitmap()
  if bitmap == nil then
    提示("无法获取图片数据")
    return true
  end
  
  -- 分享图片
  shareImage(bitmap)
  return true
end

-- 分享图片函数
function shareImage(bitmap)
  -- 在缓存文件夹内创建临时文件保存图片
  local dir = this.getExternalCacheDir().toString()
  local fileName = "shared_image_" .. System.currentTimeMillis() .. ".jpg"
  local file = File(dir, fileName)
  
  -- 保存Bitmap到文件
  local fos = FileOutputStream(file)
  bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fos)
  fos.flush()
  fos.close()
  
  -- 获取文件的Uri（使用FileProvider）
  local authority = this.getPackageName() .. ".FileProvider"
  local contentUri = FileProvider.getUriForFile(this, authority, file)
  
  -- 创建分享Intent
  local shareIntent = Intent()
  shareIntent.setAction(Intent.ACTION_SEND)
  shareIntent.putExtra(Intent.EXTRA_STREAM, contentUri)
  shareIntent.setType("image/jpeg")
  shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
  
  -- 启动分享选择器
  this.startActivity(Intent.createChooser(shareIntent, "分享图片"))
end
