local Utils = {}

local function webview下载文件(链接, UA, 相关信息, 类型, 大小)
  local result=get_write_permissions(true)
  if result~=true then
    return false
  end
  大小=string.format("%0.2f",大小/1024/1024).."MB"
  if 相关信息:match('filename="(.-)"') then
    文件名=urlDecode(相关信息:match('filename="(.-)"'))
   else
    import "android.webkit.URLUtil"
    文件名=URLUtil.guessFileName(链接,nil,nil)
  end
  local Download_layout={
    LinearLayout;
    orientation="vertical";
    id="Download_father_layout",
    {
      TextView;
      id="namehint",
      layout_marginTop="10dp";
      text="下载文件名",
      layout_marginLeft="10dp",
      layout_marginRight="10dp",
      layout_width="match_parent";
      textColor=WidgetColors,
      layout_gravity="center";
    };
    {
      EditText;
      id="nameedit",
      Text=文件名;
      layout_marginLeft="10dp",
      layout_marginRight="10dp",
      layout_width="match_parent";
      layout_gravity="center";
    };
  };

  AlertDialog.Builder(this)
  .setTitle("下载文件")
  .setMessage("文件类型："..类型.."\n".."文件大小："..大小)
  .setView(loadlayout(Download_layout))
  .setNeutralButton("复制",{onClick=function(v)
      复制文本(链接)
      提示("复制下载链接成功")
  end})
  .setPositiveButton("下载",{onClick=function(v)
      下载文件(链接,nameedit.Text)
  end})
  .setNegativeButton("取消",nil)
  .show()
end

local function mergeTables(table1, table2, names)
  -- 遍历table1的所有键值对
  for key, value in pairs(table1) do
    local shouldMerge = false

    -- 检查当前键是否在names中
    for _, nameKey in ipairs(names) do
      if key == nameKey then
        shouldMerge = true
        break
      end
    end

    if shouldMerge then
      local orivalue=table2[key] or function() end
      table2[key] = function (...)
        orivalue(...)
        return value(...)
      end
     else
      table2[key] = value
    end
  end
end

function Utils:initSettings()
  self.webview
  .getSettings()
  .setAppCacheEnabled(true)
  .setCacheMode(WebSettings.LOAD_DEFAULT)
  --开启 DOM 存储功能
  .setDomStorageEnabled(true)
  --开启 数据库 存储功能
  .setDatabaseEnabled(true)
  self.webview.BackgroundColor=转0x("#00000000",true);

  return self

end

function Utils:initNoImageMode()
  if 无图模式 then
    self.webview.getSettings().setBlockNetworkImage(true)
   else
    self.webview.getSettings().setBlockNetworkImage(false)
  end
  return self
end

function Utils:initDownloadListener()
  self.webview.setDownloadListener({
    onDownloadStart=function(链接, UA, 相关信息, 类型, 大小)
      webview下载文件(链接, UA, 相关信息, 类型, 大小)
  end})
  return self
end

function Utils:setUA(UA)
  self.webview.getSettings().setUserAgentString(UA)
  return self
end

function Utils:setZhiHuUA()
  local UA="ZhihuHybrid com.zhihu.android/Futureve/9.13.0 "..self.webview.getSettings().getUserAgentString()
  self.webview.getSettings().setUserAgentString(UA)
  return self
end

function Utils:initWebViewClient(callback)

  callback=callback or {}

  local names = {"onPageStarted","shouldInerceptRequest"}

  local function 网页字体设置(view)
    if this.getSharedData("网页自定义字体")==nil then
      return
    end
    local js=获取js("font")
    加载js(view,js)
  end

  local function 拦截加载(view,url)
    local 提示=function(text)
      this.runOnUiThread(Runnable{
        run=function()
          提示(text)
        end
      });
    end
    if this.getSharedData("网页自定义字体")==nil then
      return
    end
    local 自定义字体路径=this.getSharedData("网页自定义字体")
    if 自定义字体路径=="" then
      自定义字体路径=srcLuaDir.."/res/product.ttf";
    end
    if url:find("myappfont") then
      local FileInputStream=luajava.bindClass"java.io.FileInputStream"
      local fis
      _=pcall(function() fis= FileInputStream(自定义字体路径) end)
      if _==false then
        this.setSharedData("网页自定义字体",nil)
        提示("当前自定义字体文件不可读 已自动清空")
      end
      local WebResourceResponse=luajava.bindClass "android.webkit.WebResourceResponse"
      return WebResourceResponse(
      "application/x-font-ttf",
      "utf-8",
      fis)
    end

  end

  local mycallback={
    onPageStarted=function(view,url,favicon)
      view.evaluateJavascript(获取js("imgload"),{onReceiveValue=function(b)end})
      网页字体设置(view)

      加载js(view,获取js("waitdoc"))

      if url:find("zhihu.com/search") then
        加载js(view,'window.open=function() { return false }')
      end

      加载js(view,获取js("native"))

    end,
    shouldInterceptRequest=拦截加载
  }

  mergeTables(callback, mycallback, names)

  self.webview.setWebViewClient(mycallback)

  --设置网页图片点击事件，
  local z=JsInterface{
    execute=function(b)
      if b~=nil and #b>1 then
        --newActivity传入字符串过大会造成闪退 暂时通过setSharedData解决
        this.setSharedData("imagedata",b)
        activity.newActivity("image")
      end
    end
  }

  self.webview.addJSInterface(z,"androlua")

  return self
end

local LuaWebChrome=luajava.bindClass "com.lua.LuaWebChrome"

function Utils:initChromeClient(callback)

  callback=callback or {}

  local names = {"onShowCustomView", "onHideCustmView", "onJsAlert", "onJsConfirm", "onJsPrompt","onJsBeforeUnload"}

  local rootview
  if thisFragment then
    rootview=thisFragment.getView()
   else
    rootview=activity.getDecorView()
  end

  local mycallback={
    onShowCustomView=function(view,url)
      全屏模式=true
      web_video_view=view
      savedScrollY= self.webview.getScrollY()
      self.webview.setVisibility(8)
      rootview.addView(web_video_view)
    end,
    onHideCustomView=function(view,url)
      全屏模式=false
      self.webview.setVisibility(0)
      rootview.removeView(web_video_view)
      Handler().postDelayed(Runnable({
        run=function()
          self.webview.scrollTo(0, savedScrollY);
        end,
      }),200)
    end,
    onJsAlert=function(view, url, message, result)
      local dialog=AlertDialog.Builder(this)
      .setTitle(url)
      .setMessage(message)
      .setPositiveButton(android.R.string.ok, {onClick=function() result.confirm(); end})
      .setCancelable(false)
      .create()
      .show();
      dialog.findViewById(android.R.id.message).setTextIsSelectable(true)
      return true;
    end,
    onJsConfirm=function(view, url, message, result)
      local dialog=AlertDialog.Builder(this)
      .setTitle(url)
      .setMessage(message)
      .setPositiveButton(android.R.string.ok, {onClick=function() result.confirm() end})
      .setNegativeButton(android.R.string.cancel, {onClick=function() result.cancel() end})
      .setCancelable(false)
      .create()
      .show();
      dialog.findViewById(android.R.id.message).setTextIsSelectable(true)
      return true;
    end,
    onJsPrompt=function(view, url, message, defaultValue,result)
      local edittext=EditText(this)
      edittext.text=defaultValue
      local dialog=AlertDialog.Builder(this)
      .setTitle(url)
      .setView(edittext)
      .setMessage(message)
      .setPositiveButton(android.R.string.ok, {onClick=function() result.confirm() end})
      .setNegativeButton(android.R.string.cancel, {onClick=function() result.cancel() end})
      .setCancelable(false)
      .create()
      .show();
      dialog.findViewById(android.R.id.message).setTextIsSelectable(true)
      return true;
    end,
    onJsBeforeUnload=function(view, url, message, result)
      AlertDialog.Builder(this)
      .setTitle(url)
      .setMessage(message)
      .setPositiveButton(android.R.string.ok, {onClick=function() result.confirm() end})
      .setNegativeButton(android.R.string.cancel, {onClick=function() result.cancel() end})
      .setCancelable(false)
      .create()
      .show();
      return true;
    end,
  }

  local function setProgress(p)
    ValueAnimator.ofFloat({web_progressbar.getWidth(),activity.getWidth()/100*p})
    .setDuration(500)
    .addUpdateListener{
      onAnimationUpdate=function(a)
        local x=a.getAnimatedValue()
        local linearParams = web_progressbar.getLayoutParams()
        linearParams.width =x
        web_progressbar.setLayoutParams(linearParams)
      end
    }.start()

  end

  if web_progressbar then
    mycallback.onProgressChanged=function(view,p)
      setProgress(p)
      if p==100 then
        setProgress(100)
        Handler().postDelayed(Runnable({
          run=function()
            web_progressbar.Visibility=4
            local linearParams=web_progressbar.getLayoutParams()
            linearParams.width =0
            web_progressbar.setLayoutParams(linearParams)
          end,
        }),500)
       else
        web_progressbar.Visibility=0
      end
    end
    table.insert(names,"onProgressChanged")
  end

  mergeTables(callback, mycallback, names)
  self.webview.setWebChromeClient(LuaWebChrome(LuaWebChrome.IWebChrine(mycallback)))

  return self
end

return function(webview)
  webview.setProgressBarEnabled(false)
  webview.setFindListener{
    onFindResultReceived=function(
      --当前匹配列表项的序号（从0开始）
      activeMatchOrdinal,
      --所有匹配关键词的个数
      numberOfMatches,
      --有没有查找完成
      isDoneCounting)

      if numberOfMatches==0 then
        return 提示("未查找到该关键词")
      end

      local 状态
      if isDoneCounting then
        状态="成功"
       else
        状态="失败"
      end

      提示("查找"..状态.." 已查找第"..activeMatchOrdinal+1 .."个 ".."共有"..numberOfMatches-activeMatchOrdinal-1 .."个待查找")
  end}

  --解决部分机型文字缩放无效的bug
  webview.getSettings().setTextZoom(100*(tonumber(this. getSharedData("font_size") or 20)/20));
  local child=table.clone(Utils)
  child.webview=webview

  return child
end