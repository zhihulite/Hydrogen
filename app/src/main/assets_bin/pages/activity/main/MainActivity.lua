-- pages/activity/main/MainActivity.lua
-- 主页面

import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.CornerFamily"
import "android.content.pm.PackageManager"
import "android.content.Context"
import "android.net.ConnectivityManager"
import "androidx.fragment.app.FragmentManager"
import "android.view.accessibility.AccessibilityEvent"

local BaseActivity = require("pages.base.BaseActivity")

local MainActivity = Extensions.Class(BaseActivity, { "main" })

local _transition_name = "shared_element"

local TAG_LAST_TIME = Helpers.Resources.app.id.tag_last_time
local TAG_LAST_NAME = Helpers.Resources.app.id.tag_last_name


function MainActivity:ctor()
  self.leftContainer = nil
  self.rightContainer = nil
  self.currentLeftFragment = nil
  self.currentRightFragment = nil
  self.isParallelWorld = false
  self.noImageReminded = false
  self.lastClipboardText = nil
end

local function isTablet()
  local metrics = activity.resources.displayMetrics
  local widthDp = metrics.widthPixels / metrics.density
  return widthDp >= 600
end

function MainActivity:refreshIcon()
  local packageName = activity.packageName
  local launchIntent = activity.packageManager.getLaunchIntentForPackage(packageName)
  if launchIntent then
    local componentName = launchIntent.component
    if componentName then
      local packageManager = activity.packageManager
      packageManager.clearPackagePreferredActivities(packageName)
      packageManager.setComponentEnabledSetting(componentName,
      PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
      packageManager.setComponentEnabledSetting(componentName,
      PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
    end
  end
end

function MainActivity:setupWebViewSwitch()
  local webviewPackageName = "com.android.chrome"
  if Extensions.Config.getString(Constants.SharedDataKeys.SWITCH_WEBVIEW) == "true" then
    local pm = activity.packageManager
    local installed = pcall(function() return pm.getPackageInfo(webviewPackageName, 0) end)
    if not installed then
      Extensions.Config.set(Constants.SharedDataKeys.SWITCH_WEBVIEW, false)
      tip("检测不到谷歌浏览器，已自动关闭切换WebView")
      return
    end
    import "com.norman.webviewup.lib.WebViewUpgrade"
    import "com.norman.webviewup.lib.source.UpgradePackageSource"
    if WebViewUpgrade.upgradeWebViewPackageName ~= webviewPackageName then
      local upgradeSource = UpgradePackageSource(activity.applicationContext, webviewPackageName)
      WebViewUpgrade.upgrade(upgradeSource)
    end
  end
end

function MainActivity:setupSmartNoImage()
  if Extensions.Config.getBool(Constants.SharedDataKeys.SMART_NO_IMAGE) then
    _G.onStart = function()
      if self.noImageReminded then return end
      local connMgr = activity.getSystemService(Context.CONNECTIVITY_SERVICE)
      local info = connMgr.activeNetworkInfo
      if not info then return end
      local netType = info.type
      local isWifiConn = netType == ConnectivityManager.TYPE_WIFI and info.isConnected()
      local isMobileConn = netType == ConnectivityManager.TYPE_MOBILE and info.isConnected()
      local noImage = Extensions.Config.getBool(Constants.SharedDataKeys.NO_IMAGE)

      if isWifiConn and noImage then
        Helpers.BottomDialog.confirm(
        "当前在WiFi下，是否关闭不加载图片？",
        function()
          Extensions.Config.set(Constants.SharedDataKeys.NO_IMAGE, false)
          tip("关闭不加载图片成功")
        end,
        function()
          self.noImageReminded = true
        end
        )
       elseif isMobileConn and not noImage then
        Helpers.BottomDialog.confirm(
        "当前在流量下，是否开启不加载图片？",
        function()
          Extensions.Config.set(Constants.SharedDataKeys.NO_IMAGE, true)
          tip("开启不加载图片成功")
        end,
        function()
          self.noImageReminded = true
        end
        )
      end
    end
  end
end

function MainActivity:onCreate(params)
  self:refreshIcon()
  self:setupWebViewSwitch()
  self:setupSmartNoImage()
  self:setupFragmentLoader()
  self:setupVolumeController()
  if Extensions.Config.getBool(Constants.SharedDataKeys.AUTO_CLEAN_CACHE) then
    Helpers.UI.clearAppCache()
  end
  if Extensions.Config.getBool(Constants.SharedDataKeys.AUTO_CHECK_UPDATE) then
    AppInfo.showUpdateDialog(false)
  end
  if Extensions.Config.getBool(Constants.SharedDataKeys.PREDICTIVE_BACK) == false then
    activity.supportFragmentManager.enablePredictiveBack(false)
   else
    activity.supportFragmentManager.enablePredictiveBack(true)
  end

  -- 等待一会处理启动 Intent 的 url，防止 view 还没加载。
  Helpers.UI.runDelayed(500, self:runIfAlive(function()
    local intentDataUrl = params.intentDataUrl
    if (intentDataUrl) then Helpers.ZhihuParser.goUrl(intentDataUrl) end
  end))
end

import "androidx.core.view.ViewCompat"
import "com.google.android.material.transition.MaterialSharedAxis"
import "com.google.android.material.transition.MaterialContainerTransform"
import "com.google.android.material.transition.MaterialArcMotion"
import "androidx.transition.TransitionSet"

-- 获取目标容器（根据时间戳和名称智能切换）
function MainActivity:getTargetContainer(name)
  if not self.isParallelWorld then
    return self.leftContainer
  end

  -- 如果当前容器正在显示同名页面，则复用该容器
  local leftName = self.leftContainer.getTag(TAG_LAST_NAME)
  local rightName = self.rightContainer.getTag(TAG_LAST_NAME)

  if name and rightName == name then
    return self.rightContainer
   elseif name and leftName == name then
    return self.leftContainer
  end

  -- 平行世界模式：根据时间戳选择较旧的容器
  local leftTime = tonumber(self.leftContainer.getTag(TAG_LAST_TIME)) or 0
  local rightTime = tonumber(self.rightContainer.getTag(TAG_LAST_TIME)) or 0

  if leftTime > rightTime then
    return self.rightContainer -- 左侧更新，选右侧
   else
    return self.leftContainer -- 右侧更新或相等，选左侧
  end
end

-- 更新容器时间戳
function MainActivity:updateContainerTime(container, name)
  container.setTag(TAG_LAST_TIME, os.time())
  container.setTag(TAG_LAST_NAME, name)
end

function MainActivity:setupFragmentLoader()
  local function fragmentLoader(data)
    -- 智能选择目标容器
    local targetContainer = self:getTargetContainer(data.name)
    if not targetContainer then
      print("容器不存在")
      return false
    end

    local filePath = data.path:gsub("%.", "/")
    local FragmentClass = nil
    local ok, err = xpcall(function()
      FragmentClass = require(filePath)
      end, function(e)
      return debug.traceback(e)
    end)

    if not ok then
      print("加载 Fragment 失败: " .. filePath)
      print("错误详情: " .. tostring(err))
      tip("加载页面失败，请查看日志")
      return false
    end

    local fragmentModule = FragmentClass()
    local fragment = fragmentModule:getFragment(data.paramsKey)
    if not fragment then
      print("获取 Fragment 实例失败")
      return false
    end

    local transaction = activity.supportFragmentManager.beginTransaction()

    -- 获取共享元素视图
    local sharedView = data.sharedElement

    -- 如果没有开启使用简单动画，并且有共享元素，添加容器变换动画
    if Extensions.Config.getBool(Constants.SharedDataKeys.USE_SIMPLE_ANIMATION) == false and sharedView then
      self:setupSharedElementTransition(transaction, fragment, fragmentModule, sharedView)
     else
      -- 设置默认动画（进入和返回）
      self:setupDefaultTransition(fragment, fragmentModule)
    end

    -- 可能需要 replace 才生效
    transaction.add(targetContainer.id, fragment, data.name)
    if not data.noBackStack then
      transaction.addToBackStack(data.name)
    end
    transaction.commit()

    -- 更新容器时间戳
    self:updateContainerTime(targetContainer, data.name)

    -- 更新当前 Fragment 引用
    if targetContainer == self.rightContainer then
      self.currentRightFragment = fragmentModule
     else
      self.currentLeftFragment = fragmentModule
    end

    return true
  end
  Router.setFragmentLoader(fragmentLoader)
end

-- 设置默认动画（Z轴，无共享元素时使用）
function MainActivity:setupDefaultTransition(fragment, fragmentModule)
  fragmentModule:setOnViewCreatedCallback(function(container)
    local defaultAxis = MaterialSharedAxis(MaterialSharedAxis.Z, true)
    .addTarget(container)

    fragment.enterTransition = defaultAxis
    fragment.returnTransition = defaultAxis
    fragment.postponeEnterTransition()
    fragment.startPostponedEnterTransition()
  end)
end

-- 简单不易重复的ID生成器
local function generate_id()
  -- 使用时间戳(精确到毫秒) + 随机数
  local timestamp = os.time() * 1000 + math.random(0, 999)
  local random = math.random(100, 999)
  return timestamp * 1000 + random
end

-- 设置共享元素转场（容器变换 + Z轴）
function MainActivity:setupSharedElementTransition(transaction, fragment, fragmentModule, sharedView)

  -- 覆盖默认动画，设置完整转场
  fragmentModule:setOnViewCreatedCallback(function(container)
    -- 设置源视图名称
    -- 可能需要 replace 才生效
    local sharedViewName = _transition_name .. generate_id()
    ViewCompat.setTransitionName(sharedView, sharedViewName)
    transaction.addSharedElement(sharedView, sharedViewName)
    local sharedViewName = _transition_name .. generate_id()
    ViewCompat.setTransitionName(container, sharedViewName)
    transaction.addSharedElement(container, sharedViewName)

    self:setupEnterTransition(fragment, container, sharedView)
    self:setupReturnTransition(fragment, container, sharedView)
    fragment.startPostponedEnterTransition()
  end)
end

-- 设置进入转场
function MainActivity:setupEnterTransition(fragment, container, sharedView)
  -- 容器变换
  local containerTransform = MaterialContainerTransform(activity, true)
  .setStartView(sharedView)
  .setPathMotion(MaterialArcMotion())
  .setScrimColor(0x99000000)


  local axisForward = MaterialSharedAxis(MaterialSharedAxis.Z, true)
  .addTarget(container)

  local forward = TransitionSet()
  .setOrdering(TransitionSet.ORDERING_TOGETHER)
  .addTransition(containerTransform)
  .addTransition(axisForward)

  fragment.enterTransition = forward
  -- 可能需要 replace 才生效
  fragment.sharedElementEnterTransition = forward
end

-- 设置返回转场
function MainActivity:setupReturnTransition(fragment, container, sharedView)
  local containerBackward = MaterialContainerTransform(activity, false)
  .setStartView(container)
  .setEndView(sharedView)
  .setPathMotion(MaterialArcMotion())
  .setScrimColor(0x99000000)
  .addTarget(sharedView)

  local axisBackward = MaterialSharedAxis(MaterialSharedAxis.Z, false)
  .addTarget(container)

  local backward = TransitionSet()
  .setOrdering(TransitionSet.ORDERING_TOGETHER)
  .addTransition(containerBackward)
  .addTransition(axisBackward)

  fragment.returnTransition = backward
  -- 可能需要 replace 才生效
  fragment.sharedElementReturnTransition = backward
end

function MainActivity:initLayout()
  self.root_view = loadlayout(Layouts.pages.main.main, self.views)
end

function MainActivity:initViews()
  self.leftContainer = self.views.leftContainer
  self.rightContainer = self.views.rightContainer

  self.leftContainer.id = View.generateViewId()
  self.rightContainer.id = View.generateViewId()

  self:updateParallelWorld()
  Router.go("home", nil, { noBackStack = true })

  self:setupTalkBack()

end

function MainActivity:updateParallelWorld()
  local parallelEnabled = Extensions.Config.getBool(Constants.SharedDataKeys.PARALLEL_WORLD)
  local newParallel = isTablet() and parallelEnabled
  if newParallel == self.isParallelWorld then
    return
  end

  self.isParallelWorld = newParallel

  -- 延迟执行，等布局完成
  local decorView = activity.window.decorView
  decorView.postDelayed(function()
    local screenWidth = decorView.width

    -- 获取 DecorView 的左右 padding
    local paddingLeft = decorView.paddingLeft
    local paddingRight = decorView.paddingRight

    local leftLp = self.leftContainer.layoutParams
    local rightLp = self.rightContainer.layoutParams

    if self.isParallelWorld then
      -- 并排模式：各占一半，减去 padding
      local halfWidth = (screenWidth - paddingLeft - paddingRight) / 2
      leftLp.width = halfWidth
      rightLp.width = halfWidth
      self.rightContainer.visibility = View.VISIBLE
     else
      -- 普通模式：左边全屏，右边隐藏
      leftLp.width = -1
      rightLp.width = 0
      self.rightContainer.setVisibility(View.GONE)
      if self.currentRightFragment then
        local transaction = activity.supportFragmentManager.beginTransaction()
        transaction.remove(self.currentRightFragment:getFragment())
        transaction.commit()
        self.currentRightFragment = nil
      end
    end

    self.leftContainer.layoutParams = leftLp
    self.rightContainer.layoutParams = rightLp
  end, 50)
end

function MainActivity:onConfigurationChanged(newConfig)
  self:updateParallelWorld()
  -- 配置变化时重新应用夜间模式，确保主题实时生效
  AppTheme.applyNightMode()
end

function MainActivity:setupVolumeController()
  _G.VolumeController = {
    activeFragment = nil,
    setActive = function(fragment)
      _G.VolumeController.activeFragment = fragment
    end,
    onVolumeUp = function()
      local fragment = _G.VolumeController.activeFragment
      if fragment and fragment.onVolumeUp then
        return fragment:onVolumeUp()
      end
      return false
    end,
    onVolumeDown = function()
      local fragment = _G.VolumeController.activeFragment
      if fragment and fragment.onVolumeDown then
        return fragment:onVolumeDown()
      end
      return false
    end
  }
end

import "android.view.KeyEvent"
function MainActivity:onKeyDown(keyCode, event)
  if keyCode == KeyEvent.KEYCODE_VOLUME_UP then
    local handled = _G.VolumeController.onVolumeUp()
    return handled or false
   elseif keyCode == KeyEvent.KEYCODE_VOLUME_DOWN then
    local handled = _G.VolumeController.onVolumeDown()
    return handled or false
  end
  return false
end

function MainActivity:checkClipboard()
  if not Extensions.Config.getBool(Constants.SharedDataKeys.AUTO_OPEN_CLIPBOARD) then return end
  local cm = activity.getSystemService(Context.CLIPBOARD_SERVICE)
  if not cm.hasPrimaryClip() then return end
  local clipText = tostring(cm.primaryClip.getItemAt(0).text)
  if not clipText or clipText == "" then return end

  local result = Helpers.ZhihuParser.parse(clipText)
  if not result then return end

  if self.lastClipboardText == clipText then return end
  self.lastClipboardText = clipText

  Helpers.BottomDialog.show({
    title = "打开知乎链接？",
    content = clipText,
    positiveText = "打开",
    negativeText = "取消",
    onPositive = function()
      Helpers.ZhihuParser.goFrom(result)
    end
  })
end

function MainActivity:onResume()
  self:checkClipboard()
end

function MainActivity:handleIntent(intent)
  if not intent then return end

  local uri = intent.data
  if not uri then return end

  local url = uri.toString()
  if url then
    print("获取到 URL:", url)
    Helpers.ZhihuParser.goUrl(url)
  end
end

function MainActivity:onNewIntent(intent)
  if not intent then return end

  local action = intent.action
  if action ~= Intent.ACTION_VIEW and action ~= Intent.ACTION_EDIT then
    return
  end

  self:handleIntent(intent)
end

function MainActivity:setupTalkBack()
  local accessibilityManager = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)
  if not accessibilityManager.isTouchExplorationEnabled() then return end

  local containers = { self.leftContainer, self.rightContainer }

  local function getFragmentsInContainer(container)
    local fm = activity.supportFragmentManager
    local fragments = fm.fragments
    local result = {}

    for i = 0, fragments.size() - 1 do
      local fragment = fragments.get(i)
      if fragment and fragment.view then
        local parent = fragment.view.parent()
        if parent == container then
          table.insert(result, fragment)
        end
      end
    end
    return result
  end

  local function doUpdateAccessibility()
    for _, container in ipairs(containers) do
      if container and container.visibility == View.VISIBLE then
        local fragmentsInContainer = getFragmentsInContainer(container)

        -- 最后一个（最上层）可触摸，其他完全禁用
        for i, fragment in ipairs(fragmentsInContainer) do
          local view = fragment.view
          if view then
            if i == #fragmentsInContainer then
              view.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_AUTO
              view.focusable = true
              view.clickable = true
              view.requestFocus()
              view.sendAccessibilityEvent(AccessibilityEvent.TYPE_VIEW_FOCUSED)
             else
              view.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
              view.focusable = false
              view.clickable = false
            end
          end
        end
      end
    end
  end

  local debouncedUpdate = Helpers.UI.debounce(doUpdateAccessibility, 100)

  activity.supportFragmentManager.addOnBackStackChangedListener({
    onBackStackChanged = function()
      debouncedUpdate()
    end
  })

  doUpdateAccessibility()
end

function MainActivity:onDestroy()
  -- 清空 Router 的 fragmentLoader
  Router.setFragmentLoader(nil)

  -- 清空 Fragment 引用
  self.currentLeftFragment = nil
  self.currentRightFragment = nil
  self.leftContainer = nil
  self.rightContainer = nil
  self.views = nil
end

return MainActivity