require "import"
import "mods.muk"
import "androidx.core.content.ContextCompat"
import "android.content.pm.PackageManager"
import "java.util.ArrayList"
import "com.google.zxing.BarcodeFormat"
import "com.journeyapps.barcodescanner.BarcodeCallback"
import "com.journeyapps.barcodescanner.BarcodeResult"
import "com.journeyapps.barcodescanner.DefaultDecoderFactory"
import "com.journeyapps.barcodescanner.DecoratedBarcodeView"

设置视图("layout/scan")
edgeToedge(nil,nil,function() end)

local cameraPermission = "android.permission.CAMERA"
local hasHandledResult = false

local function tryStartScan()
  if hasHandledResult then
    return
  end

  local hasPermission = ContextCompat.checkSelfPermission(activity, cameraPermission) == PackageManager.PERMISSION_GRANTED
  if not hasPermission then
    提示("请授予相机权限后重试")
    activity.finish()
    return
  end

  local formats = ArrayList()
  formats.add(BarcodeFormat.QR_CODE)
  barcodeScannerView.getBarcodeView().setDecoderFactory(DefaultDecoderFactory(formats))

  barcodeScannerView.decodeSingle(BarcodeCallback{
    barcodeResult = function(result)
      if hasHandledResult or result == nil then
        return
      end

      local text = tostring(result.getText() or "")
      if text == "" then
        提示("未识别到内容，请重试")
        task(300, tryStartScan)
        return
      end

      hasHandledResult = true
      barcodeScannerView.pause()

      if text:match("^https?://") then
        if 检查链接(text, true) then
          检查链接(text)
         else
          newActivity("browser", {text})
        end
        activity.finish()
        return
      end

      双按钮对话框("扫码结果", text, "复制", "关闭", function(an)
        关闭对话框(an)
        复制文本(text)
        提示("已复制扫码内容")
        activity.finish()
      end, function(an)
        关闭对话框(an)
        activity.finish()
      end)
    end
  })

  barcodeScannerView.resume()
end

function onResume()
  if not hasHandledResult then
    tryStartScan()
  end
end

function onPause()
  barcodeScannerView.pause()
end

function onDestroy()
  barcodeScannerView.pauseAndWait()
end
