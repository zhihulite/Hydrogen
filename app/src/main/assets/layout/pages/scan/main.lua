-- layout/pages/scan/main.lua
-- 扫描页面主布局（FrameLayout 叠放：全屏取景预览 + 悬浮工具栏）

import "android.widget.FrameLayout"
import "com.journeyapps.barcodescanner.DecoratedBarcodeView"
import "com.google.android.material.appbar.MaterialToolbar"

local colors = AppTheme.colors

return {
  FrameLayout,
  layout_width = "fill",
  layout_height = "fill",
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
  -- 悬浮工具栏：叠在取景预览之上，背景透明不遮挡画面
  {
    MaterialToolbar,
    id = "toolbar",
    layout_width = "fill",
    layout_height = "wrap",
    layout_gravity = "top",
    backgroundColor = "#00000000",
  },
}