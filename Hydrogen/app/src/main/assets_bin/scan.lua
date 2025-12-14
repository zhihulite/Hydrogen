require "import"
import "mods.muk"
import "androidx.activity.result.ActivityResultLauncher"
import "com.journeyapps.barcodescanner.DecoratedBarcodeView"
import "com.journeyapps.barcodescanner.camera.CameraSettings"
import "com.journeyapps.barcodescanner.ScanOptions"
import "com.journeyapps.barcodescanner.ScanContract"
import "com.journeyapps.barcodescanner.DecoderFactory"

设置视图("layout/scan")
edgeToedge(nil,nil,function() end)

import "androidx.activity.result.ActivityResultLauncher"
barcodeLauncher = ActivityResultLauncher{ScanContract, function(v) print(v) end}

HyCameraSettings=CameraSettings()
.setAutoFocusEnabled(true)

HyCameraOptions=ScanOptions()
.setDesiredBarcodeFormats({"QR_CODE"})
.setPrompt("")
.setBeepEnabled(false)

barcodeLauncher.launch(HyCameraOptions)