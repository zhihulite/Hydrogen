-- helpers/screenshot.lua
-- 网页长截图合成：解码 base64、裁掉顶部遮挡区、拼接标题栏并弹出预览

import "android.util.Base64"
import "android.graphics.Bitmap"
import "android.graphics.BitmapFactory"
import "android.graphics.Canvas"
import "android.graphics.Paint"
import "android.graphics.BitmapShader"
import "android.graphics.Matrix"
import "android.graphics.Shader"
import "android.view.View"
import "java.io.ByteArrayInputStream"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

local M = {}

-- 居中缩放后裁成正方形圆形位图
local function toCircleBitmap(original)
  if original == nil then
    return nil
  end
  local size = math.min(original.width, original.height)
  local output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
  local canvas = Canvas(output)
  local paint = Paint(Paint.ANTI_ALIAS_FLAG)
  local shader = BitmapShader(original, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
  local matrix = Matrix()
  local scale = size / math.max(original.width, original.height)
  matrix.setScale(scale, scale)
  if original.width > original.height then
    matrix.postTranslate((size - original.width * scale) / 2, 0)
   else
    matrix.postTranslate(0, (size - original.height * scale) / 2)
  end
  shader.localMatrix = matrix
  paint.shader = shader
  canvas.drawCircle(size / 2, size / 2, size / 2, paint)
  return output
end

-- 把 Drawable 按固有尺寸画进位图再转圆形
local function circleFromDrawable(drawable)
  if not drawable then return nil end
  local w = drawable.intrinsicWidth
  local h = drawable.intrinsicHeight
  if w <= 0 or h <= 0 then return nil end

  local src = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
  local canvas = Canvas(src)
  drawable.setBounds(0, 0, w, h)
  drawable.draw(canvas)
  local circle = toCircleBitmap(src)
  src.recycle()
  return circle
end

--- 解码 WebView 回传的 base64 截图数据
--- base64 解码与 Bitmap 生成放在 IO 线程；onDecoded 在主线程收到非空 Bitmap，
--- 后续裁剪与合成依赖视图高度与布局测量，只能由 onDecoded 在主线程继续。
--- 调用方需自行用 runIfAlive 包裹 onDecoded。
--- @param base64 string base64 图像数据
--- @param onDecoded function 主线程回调，参数为解码出的 Bitmap
function M.decodeBase64(base64, onDecoded)
  if not base64 or #base64 < 30 then
    tip("截图失败：数据为空")
    return
  end

  task(function()
    return BitmapFactory.decodeStream(ByteArrayInputStream(Base64.decode(base64, Base64.DEFAULT)))
    end, function(bmp)
    if not bmp then
      tip("截图解码失败")
      return
    end
    onDecoded(bmp)
  end)
end

--- 裁掉截图顶部、在上方拼接标题栏，弹出预览对话框
--- 依赖视图测量与绘制，必须在主线程调用；传入的 bmp 由本函数回收。
--- @param bmp Bitmap 已解码的网页截图
--- @param opts table cropTop 顶部裁剪像素 / title 标题 / author 作者 / avatar 头像 Drawable
---   / shareUrl 分享附带链接 / fileName 分享文件名 / onDismiss 对话框关闭回调
function M.composeAndPreview(bmp, opts)
  if not bmp then return end
  opts = opts or {}

  local cropTop = opts.cropTop or 0
  if cropTop > 0 and cropTop < bmp.height then
    local cropped = Bitmap.createBitmap(bmp, 0, cropTop, bmp.width, bmp.height - cropTop)
    bmp.recycle()
    bmp = cropped
  end

  local width = bmp.width

  local headerIds = {}
  local headerLayout = loadlayout(Layouts.pages.answer.screenshot_header, headerIds)
  headerIds.title.text = opts.title or ""
  headerIds.author.text = opts.author or ""

  local avatar = circleFromDrawable(opts.avatar)
  if avatar then
    headerIds.avatar.imageBitmap = avatar
  end

  -- 标题栏不在视图树内，绘制前须按截图宽度自行测量取得实际高度
  local widthSpec = View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY)
  local heightSpec = View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
  headerLayout.measure(widthSpec, heightSpec)
  local headerHeight = headerLayout.measuredHeight

  local result = Bitmap.createBitmap(width, bmp.height + headerHeight, Bitmap.Config.ARGB_8888)
  local canvas = Canvas(result)
  headerLayout.layout(0, 0, width, headerHeight)
  headerLayout.draw(canvas)
  canvas.drawBitmap(bmp, 0, headerHeight, nil)
  bmp.recycle()

  local previewIds = {}
  local previewLayout = loadlayout(Layouts.pages.answer.screenshot_preview, previewIds)
  Helpers.Image.load(previewIds.iv, result)

  local builder = MaterialAlertDialogBuilder(activity)
  .setTitle("预览")
  .setView(previewLayout)
  .setPositiveButton("确认并分享", function()
    Helpers.UI.shareBitmap(result, opts.fileName or ("screenshot_" .. os.time() .. ".jpg"), opts.shareUrl)
  end)
  .setNegativeButton("取消", function()
    result.recycle()
  end)

  if opts.onDismiss then
    builder.setOnDismissListener({ onDismiss = opts.onDismiss })
  end

  builder.show()
end

return M