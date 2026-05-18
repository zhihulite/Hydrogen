-- layout/pages/scan/main.lua
-- 扫描页面主布局

import "androidx.appcompat.widget.LinearLayoutCompat"
import "com.journeyapps.barcodescanner.DecoratedBarcodeView"

local colors = AppTheme.getColors()

return {
  LinearLayoutCompat,
  layout_width = "fill",
  layout_height = "fill",
  orientation = "vertical",
  id = "main_container",
  backgroundColor = colors.background,
  {
    DecoratedBarcodeView,
    id = "barcode_scanner_view",
    layout_width = "fill",
    layout_height = "fill",
    StatusText="请将条码放入扫描框内",
    clipToPadding = false,
  },
}