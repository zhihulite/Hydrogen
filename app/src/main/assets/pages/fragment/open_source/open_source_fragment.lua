-- pages/fragment/open_source/open_source_fragment.lua
-- 开源许可页面 Fragment

import "android.content.Intent"

local BaseFragment = require("pages.base.base_fragment")
local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
local SafeLinearLayoutManager = luajava.bindClass("com.hydrogen.SafeLinearLayoutManager")

local OpenSourceFragment = Extensions.Class(BaseFragment)

local licenses = {
  { name = "AndroidX AppCompat", license = "Apache 2.0", message = "Android 兼容库", url = "https://developer.android.com/jetpack/androidx" },
  { name = "AndroidX Core", license = "Apache 2.0", message = "Android 核心库", url = "https://developer.android.com/jetpack/androidx" },
  { name = "AndroidX Transition", license = "Apache 2.0", message = "过渡动画库", url = "https://developer.android.com/jetpack/androidx" },
  { name = "AndroidX Fragment", license = "Apache 2.0", message = "Fragment 库", url = "https://developer.android.com/jetpack/androidx" },
  { name = "AndroidX ViewPager2", license = "Apache 2.0", message = "滑动页面库", url = "https://developer.android.com/jetpack/androidx" },
  { name = "AndroidX SwipeRefresh", license = "Apache 2.0", message = "下拉刷新库", url = "https://developer.android.com/jetpack/androidx" },
  { name = "AndroidX Activity", license = "Apache 2.0", message = "Activity 扩展库", url = "https://developer.android.com/jetpack/androidx" },
  { name = "AndroidX SplashScreen", license = "Apache 2.0", message = "启动画面库", url = "https://developer.android.com/jetpack/androidx" },
  { name = "AndroidX WebKit", license = "Apache 2.0", message = "WebView 扩展库", url = "https://developer.android.com/jetpack/androidx" },
  { name = "Material Design Components", license = "Apache 2.0", message = "Material Design 组件库", url = "https://github.com/material-components/material-components-android" },
  { name = "Glide", license = "Apache 2.0", message = "图片加载库", url = "https://github.com/bumptech/glide" },
  { name = "PhotoView", license = "Apache 2.0", message = "图片缩放库", url = "https://github.com/Baseflow/PhotoView" },
  { name = "WebViewUpgrade", license = "Apache 2.0", message = "WebView 内核更新库", url = "https://github.com/JonaNorman/WebViewUpgrade" },
  { name = "ZXing Embedded", license = "Apache 2.0", message = "二维码扫描库", url = "https://github.com/journeyapps/zxing-android-embedded" },
  { name = "ZXing Core", license = "Apache 2.0", message = "二维码核心库", url = "https://github.com/zxing/zxing" },
  { name = "LuaJVM", license = "MIT", message = "LuaJVM 脚本框架 (基础运行时)", url = "https://github.com/zhihulite/luajvm" },
}

function OpenSourceFragment:ctor()
  self.adapter = nil
  self.items = licenses
end

function OpenSourceFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.open_source.main, self.views)
end

function OpenSourceFragment:initViews()
  local views = self.views
  self:setupEdgeToEdge({
    top = { views.main_container },
    bottom = { views.recycler_view },
  })

  Helpers.UI.setupToolbar(views.toolbar,{ title = "开源许可" })

  self:initListView()
end

function OpenSourceFragment:initListView()
  local views = self.views
  if not views.recycler_view then return end
  self.adapter = SimpleRecyclerAdapter.new({
    items = self.items,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate(Layouts.pages.open_source.item)
    end,
    onBind = function(views, item, position, holder)
      views.name.text = item.name
      views.license.text = item.license

      if item.message and item.message ~= "" then
        views.message.text = item.message
        views.message.visibility = View.VISIBLE
       else
        views.message.visibility = View.GONE
      end

      if views.card then
        views.card.onClick = function()
          if item.url then
            Helpers.UI.openUrl(item.url)
          end
        end
      end
    end
  })

  views.recycler_view.adapter = self.adapter
  views.recycler_view.layoutManager = SafeLinearLayoutManager(activity)
end

function OpenSourceFragment:onDestroy()
  if self.adapter then
    self.adapter = nil
  end
end

return OpenSourceFragment