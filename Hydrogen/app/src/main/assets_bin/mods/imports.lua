require "import"

import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.view.animation.*"
import "android.view.animation.Animation$AnimationListener"
import "android.view.animation.AccelerateDecelerateInterpolator"
import "android.view.inputmethod.InputMethodManager"
import "android.animation.*"
import "views.MyTab"
import "android.webkit.CookieSyncManager"
import "android.webkit.CookieManager"
import "android.content.Context"



import "com.androlua.LuaWebView$JsInterface"

import "android.net.*"

import "android.text.*"
import "android.text.style.*"
import "android.content.*"
import "android.content.res.*"
import "android.content.pm.PackageManager"
import "android.content.pm.ApplicationInfo"
import "android.content.ContentResolver"

import "android.graphics.*"
import "android.graphics.Matrix"
import "android.graphics.Bitmap"
import "android.graphics.BitmapFactory"
import "android.graphics.Typeface"
import "android.graphics.drawable.*"
import "android.graphics.PorterDuff"
import "android.graphics.PorterDuffColorFilter"

import "android.renderscript.*"
import "android.renderscript.Element"
import "android.renderscript.Allocation"
import "android.renderscript.ScriptIntrinsicBlur"
import "android.renderscript.RenderScript"

import "java.lang.Math"

import "java.security.*"

import "java.io.*"
import "java.io.File"
import "java.io.InputStream"

import "java.util.*"

import "java.net.URL"

import "android.content.res.ColorStateList"
import "android.content.pm.PackageManager"
import "android.content.Intent"
import "android.net.Uri"
import "android.util.Base64"

import "androidx.*"
import "androidx.appcompat.*"
import "androidx.core.app.*"

import "android.webkit.WebSettings"
import "android.webkit.MimeTypeMap"

import "android.provider.Settings"

import "android.Manifest"

import "android.animation.Animator"
import "android.animation.ValueAnimator"
import "android.animation.LayoutTransition"

import "androidx.core.content.ContextCompat"
import "com.google.android.material.card.MaterialCardView"



--0.53 去除MyLauAdapter以及屏蔽词

import "com.hydrogen.view.NoScrollListView"
import "com.hydrogen.view.NoScrollGridView"

import "com.google.android.material.appbar.*"
import "androidx.core.widget.NestedScrollView"

import "me.everything.android.ui.overscroll.*"
import "androidx.core.view.ViewCompat"
import "com.google.android.material.shape.RoundedCornerTreatment"
import "com.google.android.material.shape.TriangleEdgeTreatment"
import "com.google.android.material.shape.ShapeAppearanceModel"
import "com.google.android.material.shape.RelativeCornerSize"

MaterialContainerTransform=luajava.bindClass("com.google.android.material.transition.MaterialContainerTransform")
--
if tostring(this.getSharedData("预见性返回手势"))=="false"
function MaterialContainerTransform(a,b) 
return luajava.override(luajava.bindClass("com.google.android.material.transition.MaterialContainerTransform"),{isSeekingSupported=function() return false end},a,b)
end
end
MyLuaFileFragment=luajava.bindClass("com.hydrogen.MyLuaFileFragment")
MaterialSharedAxis=luajava.bindClass("com.google.android.material.transition.MaterialSharedAxis")
MaterialArcMotion=luajava.bindClass("com.google.android.material.transition.MaterialArcMotion")
WindowInsetsCompat = luajava.bindClass "androidx.core.view.WindowInsetsCompat"
