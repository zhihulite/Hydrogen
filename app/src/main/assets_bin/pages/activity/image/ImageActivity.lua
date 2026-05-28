-- pages/activity/image/ImageActivity.lua
-- 图片浏览器 Activity（全屏沉浸 + CoordinatorLayout 自动适配 + 点击切换底栏）

require("initApp")

import "androidx.viewpager2.widget.ViewPager2"
import "com.hydrogen.adapter.LuaPager2Adapter"
import "com.bumptech.glide.Glide"
import "com.bumptech.glide.load.engine.DiskCacheStrategy"
import "android.graphics.Bitmap"
import "android.os.Environment"
import "java.io.File"
import "java.io.FileOutputStream"
import "java.lang.System"
import "android.content.Intent"
import "android.content.FileProvider"
import "android.view.View"
import "android.webkit.URLUtil"

local BaseActivity = require("pages.base.BaseActivity")

local ImageActivity = Extensions.Class(BaseActivity)

function ImageActivity:ctor()
  self.imageUrls = {}
  self.currentIndex = 0
  self.totalCount = 0
  self.adapter = nil
  self.pageViews = {}
  self.bottomBarVisible = true
end

function ImageActivity:onCreate(params)
  local imageData = activity.getSharedData("imagedata")
  if imageData then
    local ok, decoded = pcall(json.decode, imageData)
    if ok then
      self.imageUrls = decoded
    end
  end

  self.currentIndex = tonumber(activity.getSharedData("imageindex")) or 0
  self.totalCount = #self.imageUrls

  if self.totalCount == 0 then
    tip("没有可显示的图片")
    activity.finish()
    return
  end

  self:setupEdgeToEdge({})
  self:setFullScreen()
end

function ImageActivity:initLayout()
  self.root_view = loadlayout(Layouts.pages.image.main, self.views)
end

function ImageActivity:initViews()
  self:updatePageInfo()
  self:setupViewPager()

  self.views.download_btn.onClick = function() self:downloadCurrentImage() end
  self.views.download_btn.onLongClick = function()
    self:shareCurrentImage()
    return true
  end
end

function ImageActivity:setupViewPager()
  local viewPager = self.views.view_pager
  self.adapter = LuaPager2Adapter()
  self.pageViews = {}

  for i = 0, self.totalCount - 1 do
    local page = { ids = {} }
    local pageView = loadlayout(Layouts.pages.image.page_item, page.ids)
    self.pageViews[i] = page
    self.adapter.add(pageView)
  end

  viewPager.adapter = self.adapter
  viewPager.offscreenPageLimit = 1
  viewPager.registerOnPageChangeCallback(luajava.override(ViewPager2.OnPageChangeCallback, {
    onPageSelected = function(super, position)
      self.currentIndex = position
      self:updatePageInfo()
      self:loadImage(position)
    end
  }))

  viewPager.setCurrentItem(self.currentIndex, false)
end

function ImageActivity:loadImage(index)
  local imgidx = index + 1
  if not self.imageUrls[imgidx] or not self.pageViews[index] then return end

  local views = self.pageViews[index].ids
  if views.photo_view.drawable ~= nil then return end

  local url = self:processImageUrl(self.imageUrls[imgidx])
  views.loading_container.visibility = View.VISIBLE

  -- 设置 PhotoView 点击事件
  views.photo_view.onClick = function()
    self:toggleBottomBar()
  end

  Glide.with(activity)
  .load(url)
  .diskCacheStrategy(DiskCacheStrategy.ALL)
  .listener(luajava.createProxy("com.bumptech.glide.request.RequestListener", {
    -- 这两个回调在 Activity 销毁后仍可能执行
    onResourceReady = self:runIfAlive(function(resource, model, target, dataSource, isFirstResource)
      if not self.pageViews or not self.pageViews[index] then return end
      local v = self.pageViews[index].ids
      if v then
        v.loading_container.visibility = View.GONE
        v.photo_view.visibility = View.VISIBLE
      end
      return false
    end),
    onLoadFailed = self:runIfAlive(function(e, model, target, isFirstResource)
      if not self.pageViews or not self.pageViews[index] then return end
      local v = self.pageViews[index].ids
      if v then
        v.loading_container.visibility = View.GONE
        v.photo_view.visibility = View.VISIBLE
      end
      tip("图片加载失败")
      return false
    end)
  }))
  .into(views.photo_view)
end

function ImageActivity:processImageUrl(url)
  if not url then return "" end
  if url:find("zhimg.com") then
    if url:find("%.webp%?") then url = url:gsub("%.webp%?", ".jpg?")
     elseif url:find("%.png%?") then
      url = url:gsub("%.png%?", ".jpg?")
    end
    url = url:gsub("qhd", "r"):gsub("fhd", "r"):gsub("720w", "r")
  end
  return url
end

function ImageActivity:updatePageInfo()
  if self.totalCount > 0 then
    -- 使用 post 防止部分情况下文本绘制出现问题
    self.views.main_container.post(self:runIfAlive(function()
      self.views.now_count.text = tostring(self.currentIndex + 1)
      self.views.all_count.text = tostring(self.totalCount)
    end))
  end
end

function ImageActivity:toggleBottomBar()
  self.bottomBarVisible = not self.bottomBarVisible
  self.views.bottom_bar.visibility = self.bottomBarVisible and View.VISIBLE or View.GONE
  self.views.download_btn.visibility = self.bottomBarVisible and View.VISIBLE or View.GONE
end


function ImageActivity:shareCurrentImage()
  local currentIndex = self.currentIndex
  if not self.pageViews[currentIndex] then
    tip("没有可分享的图片")
    return
  end

  local photoView = self.pageViews[currentIndex].ids.photo_view
  local drawable = photoView.drawable
  if not drawable then
    tip("图片尚未加载完成")
    return
  end

  local url = self:processImageUrl(self.imageUrls[currentIndex + 1])
  local fileName, mimeType = Extensions.File.getFileNameAndType(url)
  fileName = "shared_" .. fileName

  local GifDrawableClass = luajava.bindClass("com.bumptech.glide.load.resource.gif.GifDrawable")

  if luajava.instanceof(drawable, GifDrawableClass) then
    -- GIF：克隆后获取完整字节
    local cloned = drawable.constantState.newDrawable().mutate()
    local buffer = cloned.buffer
    local bytes = luajava.newArray(luajava.bindClass("java.lang.Byte").TYPE, buffer.capacity())
    local dup = buffer.duplicate()
    dup.clear()
    dup.get(bytes)
    dup.clear()
    Helpers.UI.shareBytes(bytes, fileName, mimeType)
   else
    -- 静态图：直接获取 bitmap 分享
    local bitmap = drawable.bitmap
    if bitmap then
      Helpers.UI.shareBitmap(bitmap, fileName)
     else
      tip("无法获取图片数据")
    end
  end
end


function ImageActivity:downloadCurrentImage()
  local url = self.imageUrls[self.currentIndex + 1]
  if not url then return end
  url = self:processImageUrl(url)
  Extensions.File.downloadFile(url)
end

function ImageActivity:setFullScreen()
  if Build.VERSION.SDK_INT < 21 then return end

  local window = activity.window
  window.decorView.setSystemUiVisibility(
  View.SYSTEM_UI_FLAG_LAYOUT_STABLE
  | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
  | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
  | View.SYSTEM_UI_FLAG_FULLSCREEN
  | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
  | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
  )
end

function ImageActivity:onDestroy()
  activity.setSharedData("imagedata", nil)
  activity.setSharedData("imageindex", nil)

  if self.pageViews then
    for _, page in pairs(self.pageViews) do
      if page.ids and page.ids.photo_view then
        page.ids.photo_view.imageDrawable = nil
      end
    end
  end
  self.pageViews = nil
  self.imageUrls = nil
end

return ImageActivity