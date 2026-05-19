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

local MainActivity = Extensions.Class(BaseActivity, {"main"})
MainActivity:chainUp("onDestroy")

local _transition_name = "shared_element"

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
  local metrics = activity.getResources().getDisplayMetrics()
  local widthDp = metrics.widthPixels / metrics.density
  return widthDp >= 600
end

function MainActivity:refreshIcon()
  local packageName = activity.getPackageName()
  local launchIntent = activity.getPackageManager().getLaunchIntentForPackage(packageName)
  if launchIntent then
    local componentName = launchIntent.getComponent()
    if componentName then
      local packageManager = activity.getPackageManager()
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
    local pm = activity.getPackageManager()
    local installed = pcall(function() return pm.getPackageInfo(webviewPackageName, 0) end)
    if not installed then
      Extensions.Config.set(Constants.SharedDataKeys.SWITCH_WEBVIEW, false)
      tip("检测不到谷歌浏览器，已自动关闭切换WebView")
      return
    end
    import "com.norman.webviewup.lib.WebViewUpgrade"
    import "com.norman.webviewup.lib.source.UpgradePackageSource"
    if WebViewUpgrade.getUpgradeWebViewPackageName() ~= webviewPackageName then
      local upgradeSource = UpgradePackageSource(activity.getApplicationContext(), webviewPackageName)
      WebViewUpgrade.upgrade(upgradeSource)
    end
  end
end

function MainActivity:setupSmartNoImage()
  if Extensions.Config.getBool(Constants.SharedDataKeys.SMART_NO_IMAGE) then
    _G.onStart = function()
      if self.noImageReminded then return end
      local connMgr = activity.getSystemService(Context.CONNECTIVITY_SERVICE)
      local info = connMgr.getActiveNetworkInfo()
      if not info then return end
      local netType = info.getType()
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
    activity.getSupportFragmentManager().enablePredictiveBack(false)
   else
    activity.getSupportFragmentManager().enablePredictiveBack(true)
  end
end

import "androidx.core.view.ViewCompat"
import "com.google.android.material.transition.MaterialSharedAxis"
import "com.google.android.material.transition.MaterialContainerTransform"
import "com.google.android.material.transition.MaterialArcMotion"
import "androidx.transition.TransitionSet"

function MainActivity:setupFragmentLoader()
  local selfRef = self
  local function fragmentLoader(data)
    local targetContainer = selfRef.isParallelWorld and selfRef.rightContainer or selfRef.leftContainer
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
    local fragment = fragmentModule:getFragment(data.params)
    if not fragment then
      print("获取 Fragment 实例失败")
      return false
    end

    local transaction = activity.getSupportFragmentManager().beginTransaction()

    -- 获取共享元素视图
    local sharedView = data.sharedElement

    -- 如果没有开启使用简单动画，并且有共享元素，添加容器变换动画
    if Extensions.Config.getBool(Constants.SharedDataKeys.USE_SIMPLE_ANIMATION) == false and sharedView then
      selfRef:setupSharedElementTransition(transaction, fragment, fragmentModule, sharedView)
     else
      -- 设置默认动画（进入和返回）
      selfRef:setupDefaultTransition(fragment, fragmentModule)
    end

    transaction.add(targetContainer.getId(), fragment, data.name)
    if not data.noBackStack then
      transaction.addToBackStack(data.name)
    end
    transaction.commit()

    if data.name == "right" then
      selfRef.currentRightFragment = fragmentModule
     else
      selfRef.currentLeftFragment = fragmentModule
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

    fragment.setEnterTransition(defaultAxis)
    fragment.setReturnTransition(defaultAxis)
    fragment.postponeEnterTransition()
    fragment.startPostponedEnterTransition()
  end)
end

-- 设置共享元素转场（容器变换 + Z轴）
function MainActivity:setupSharedElementTransition(transaction, fragment, fragmentModule, sharedView)
  -- 设置源视图名称
  ViewCompat.setTransitionName(sharedView, _transition_name)

  -- 获取窗口圆角
  local radii = self:getWindowCornerRadii()
  local targetShape = self:buildTargetShape(radii)

  -- 容器变换
  local containerTransform = MaterialContainerTransform(activity, true)
  .setStartView(sharedView)
  .setEndShapeAppearanceModel(targetShape)
  .setPathMotion(MaterialArcMotion())
  .setScrimColor(0x99000000)

  -- 覆盖默认动画，设置完整转场
  fragmentModule:setOnViewCreatedCallback(function(container)
    ViewCompat.setTransitionName(container, _transition_name)

    self:setupEnterTransition(fragment, container, containerTransform)
    self:setupReturnTransition(fragment, container, sharedView)
    fragment.startPostponedEnterTransition()
  end)
end

-- 设置进入转场
function MainActivity:setupEnterTransition(fragment, container, containerTransform)
  local axisForward = MaterialSharedAxis(MaterialSharedAxis.Z, true)
  .addTarget(container)

  local forward = TransitionSet()
  .setOrdering(TransitionSet.ORDERING_TOGETHER)
  .addTransition(containerTransform)
  .addTransition(axisForward)

  fragment.setEnterTransition(forward)
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

  fragment.setExitTransition(axisBackward)
  fragment.setReturnTransition(backward)
end

-- 获取窗口圆角
function MainActivity:getWindowCornerRadii()
  local radii = {0, 0, 0, 0}
  pcall(function()
    local insets = activity.getWindow().getDecorView().getRootWindowInsets()
    if insets then
      radii[1] = insets.getRoundedCorner(0).getRadius()
      radii[2] = insets.getRoundedCorner(1).getRadius()
      radii[3] = insets.getRoundedCorner(2).getRadius()
      radii[4] = insets.getRoundedCorner(3).getRadius()
    end
  end)

  if radii[1] == 0 then
    local defaultVal = tonumber(dp2px(16, true))
    for i = 1, 4 do radii[i] = defaultVal end
  end
  return radii
end

-- 构建目标形状
function MainActivity:buildTargetShape(radii)
  local ShapeAppearanceModel = luajava.bindClass("com.google.android.material.shape.ShapeAppearanceModel")
  return ShapeAppearanceModel.builder()
  .setTopLeftCornerSize(radii[1])
  .setTopRightCornerSize(radii[2])
  .setBottomRightCornerSize(radii[3])
  .setBottomLeftCornerSize(radii[4])
  .build()
end

function MainActivity:initLayout()
  self.root_view = loadlayout(Layouts.pages.main.main, self.views)
end

function MainActivity:initViews()
  self.leftContainer = self.views.leftContainer
  self.rightContainer = self.views.rightContainer

  self.leftContainer.setId(View.generateViewId())
  self.rightContainer.setId(View.generateViewId())

  self:updateParallelWorld()
  Router.go("home", nil , { noBackStack = true })

  self:setupTalkBack()

end

function MainActivity:updateParallelWorld()
  local parallelEnabled = Extensions.Config.getBool(Constants.SharedDataKeys.PREDICTIVE_BACK)
  local newParallel = isTablet() and parallelEnabled

  if newParallel == self.isParallelWorld then
    return
  end

  self.isParallelWorld = newParallel
  if self.isParallelWorld then
    self.rightContainer.setVisibility(View.VISIBLE)
   else
    self.rightContainer.setVisibility(View.GONE)
    if self.currentRightFragment then
      local transaction = activity.getSupportFragmentManager().beginTransaction()
      transaction.remove(self.currentRightFragment:getFragment())
      transaction.commit()
      self.currentRightFragment = nil
    end
  end
end

function MainActivity:onConfigurationChanged(newConfig)
  self:updateParallelWorld()
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
  local clipText = tostring(cm.getPrimaryClip().getItemAt(0).getText())
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


function MainActivity:setupTalkBack()
  local accessibilityManager = activity.getSystemService(Context.ACCESSIBILITY_SERVICE)
  if not accessibilityManager.isTouchExplorationEnabled() then return end

  local containers = { self.leftContainer, self.rightContainer }

  local function getFragmentsInContainer(container)
    local fm = activity.getSupportFragmentManager()
    local fragments = fm.getFragments()
    local result = {}

    for i = 0, fragments.size() - 1 do
      local fragment = fragments.get(i)
      if fragment and fragment.getView() then
        local parent = fragment.getView().getParent()
        if parent == container then
          table.insert(result, fragment)
        end
      end
    end
    return result
  end

  local function doUpdateAccessibility()
    for _, container in ipairs(containers) do
      if container and container.getVisibility() == View.VISIBLE then
        local fragmentsInContainer = getFragmentsInContainer(container)

        -- 最后一个（最上层）可触摸，其他完全禁用
        for i, fragment in ipairs(fragmentsInContainer) do
          local view = fragment.getView()
          if view then
            if i == #fragmentsInContainer then
              view.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_AUTO)
              view.setFocusable(true)
              view.setClickable(true)
              view.requestFocus()
              view.sendAccessibilityEvent(AccessibilityEvent.TYPE_VIEW_FOCUSED)
             else
              view.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS)
              view.setFocusable(false)
              view.setClickable(false)
            end
          end
        end
      end
    end
  end

  local debouncedUpdate = Helpers.UI.debounce(doUpdateAccessibility, 100)

  activity.getSupportFragmentManager().addOnBackStackChangedListener({
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