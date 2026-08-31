-- pages/fragment/scan/scan_fragment.lua
-- 扫描画面 Fragment

import "java.util.ArrayList"
import "android.graphics.Color"
import "com.google.zxing.BarcodeFormat"
import "com.journeyapps.barcodescanner.BarcodeCallback"
import "com.journeyapps.barcodescanner.DefaultDecoderFactory"

local BaseFragment = require("pages.base.base_fragment")

local ScanFragment = Extensions.Class(BaseFragment, {"scan"})

function ScanFragment:ctor()
  self.hasHandledResult = false
  self.barcodeView = nil
end

function ScanFragment:onCreate(params)
  self.hasHandledResult = false
end

function ScanFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.scan.main, self.views)
end

function ScanFragment:initViews()
  local views = self.views
  self.barcodeView = views.barcode_scanner_view

  Helpers.UI.setupToolbar(views.toolbar, { title = "扫一扫" })

  -- 取景画面明暗随环境变化，工具栏标题与返回图标用纯白保证可见
  views.toolbar.titleTextColor = Color.WHITE
  local navIcon = views.toolbar.navigationIcon
  if navIcon then
    navIcon.tint = Color.WHITE
  end

  -- 工具栏悬浮于全屏取景预览之上，仅工具栏自身适配状态栏 inset，预览区域不受挤压
  self:setupEdgeToEdge({
    top = { views.toolbar }
  })

  Services.Permission.request("android.permission.CAMERA", self:runIfAlive(function(granted)
    if granted then
      self:startScan()
     else
      tip("请授予相机权限后重试")
      Router.back()
    end
    end), {
    title = "相机权限",
    message = "扫码功能需要使用相机"
  })
end

function ScanFragment:startScan()
  if self.hasHandledResult then return end

  local formats = ArrayList()
  formats.add(BarcodeFormat.QR_CODE)
  self.barcodeView.barcodeView.decoderFactory = DefaultDecoderFactory(formats)

  self.barcodeView.decodeSingle(BarcodeCallback({
    barcodeResult = self:runIfAlive(function(result)
      if self.hasHandledResult or result == nil then return end

      local text = tostring(result.text or "")
      if text == "" then
        tip("未识别到内容，请重试")
        self:startScan()
        return
      end

      self.hasHandledResult = true
      self.barcodeView.pause()

      if text:find("^https?://") then
        self:handleUrl(text)
       else
        Helpers.BottomDialog.confirm("扫码结果：\n" .. text,
        self:runIfAlive(function() Helpers.UI.copyText(text) Router.back() end),
        self:runIfAlive(function() Router.back() end)
        )
      end
    end)
  }))

  self.barcodeView.resume()
end

function ScanFragment:handleUrl(url)
  Router.back()
  Helpers.UI.runDelayed(120, function()
    Helpers.ZhihuParser.goUrl(url)
  end)
end

function ScanFragment:onResume()
  if not self.hasHandledResult and self.barcodeView then
    self:startScan()
  end
end

function ScanFragment:onPause()
  if self.barcodeView then
    self.barcodeView.pause()
  end
end

function ScanFragment:onDestroy()
  if self.barcodeView then
    self.barcodeView.pauseAndWait()
    self.barcodeView = nil
  end
end

return ScanFragment