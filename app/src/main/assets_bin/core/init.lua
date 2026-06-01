-- core/init.lua
-- core 导出

local M = {}

-- 基础模块
local extensions = require("extensions.init")
local helpers = require("helpers.init")
local services = require("services.init")

_G.Layouts = require("layout.init")
_G.Extensions = {}
_G.Helpers = {}
_G.Services = {}

_G.Extensions.Config = extensions.config
_G.Helpers.Static = helpers.static
_G.Extensions.Class = extensions.class
_G.Helpers.Image = helpers.image
_G.Extensions.Crypto = extensions.crypto
_G.Helpers.MaterialWidgets = helpers.material_widgets
_G.Helpers.ZhihuParser = helpers.zhihu_parser
_G.Helpers.Resources = helpers.resources
_G.Helpers.UI = helpers.ui
_G.Extensions.File = extensions.file
-- 初始化
_G.Extensions.File.init()
_G.Services.Permission = services.permission
-- 初始化
_G.Services.Permission.init()
_G.Helpers.BottomDialog = helpers.bottom_dialog

_G.json = require("json")
_G.Constants = require("core.constants")
_G.AppTheme = require("core.app_theme")
_G.NetWork = services.api.network
-- 初始化
_G.AppTheme.init()
_G.AppInfo = require("core.app_info")
_G.HistoryService = require("services.cache.history")

--常用函数
_G.tip = helpers.ui.tip
_G.dp2px = helpers.ui.dp2px
_G.sp2px = helpers.ui.sp2px
_G.px2sp = helpers.ui.px2sp
_G.px2dp = helpers.ui.px2dp
local Html = luajava.bindClass("android.text.Html")
_G.fromHtml = function(text)
  return Html.fromHtml(text)
end

-- 路由
_G.Router = require("core.router")
require("pages.init").registerToRouter(Router)

-- 配置配置默认值
Extensions.Config.init(Constants.defaults)

-- 设备ID
local udid = Extensions.Config.getString(Constants.SharedDataKeys.UDID)
if not udid or udid == "" then
  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
  local id = {}
  for i = 1, 35 do
    local idx = math.random(1, #chars)
    table.insert(id, chars:sub(idx, idx))
  end
  udid = table.concat(id) .. "="
  Extensions.Config.set(Constants.SharedDataKeys.UDID, udid)
end
_G.DEVICE_ID = udid

-- 工具函数
function table.merge(t1, t2)
  local result = {}
  if t1 then
    for k, v in pairs(t1) do result[k] = v end
  end
  if t2 then
    for k, v in pairs(t2) do result[k] = v end
  end
  return result
end

function table.clone(t)
  local result = {}
  for k, v in pairs(t) do
    if type(v) == "table" then
      result[k] = table.clone(v)
     else
      result[k] = v
    end
  end
  return result
end

function table.size(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

-- 请求头
_G.buildHeaders = function()
  -- base 专用请求头（只带 cookie，不带 Authorization）
  local baseHeaders = {
    ["x-udid"] = _G.DEVICE_ID,
    ["User-Agent"] = "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36",
    ["Accept"] = "application/json, text/plain, */*",
  }

  local cookieManager = luajava.bindClass("android.webkit.CookieManager").instance
  local cookie = cookieManager.getCookie("https://www.zhihu.com/")
  if cookie then
    baseHeaders["cookie"] = cookie
  end

  -- app 专用请求头（只带 Authorization，不带 cookie）
  local appHeaders = {
    ["x-udid"] = _G.DEVICE_ID,
    ["User-Agent"] = "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36",
    ["Accept"] = "application/json, text/plain, */*",
    ["x-api-version"] = "3.1.8",
    ["x-app-za"] = "OS=Android&VersionName=10.12.0&VersionCode=21210",
    ["x-app-version"] = "10.12.0",
    ["x-app-bundleid"] = "com.zhihu.android",
    ["user-agent"] = "com.zhihu.android/Futureve/10.12.0",
  }

  local sign_in_data = Extensions.Config.getString(Constants.SharedDataKeys.SIGN_IN_DATA)
  if sign_in_data then
    local token = json.decode(sign_in_data).access_token
    appHeaders["Authorization"] = "Bearer " .. token
  end

  -- 构建各种请求头
  _G.Headers = {
    defaultHead = baseHeaders,
    app = appHeaders,
    post = table.merge(baseHeaders, {
      ["content-type"] = "application/json",
    }),
    postApp = table.merge(appHeaders, {
      ["content-type"] = "application/json",
    }),
  }
end
buildHeaders()

-- 屏幕信息
local metrics = activity.resources.displayMetrics
_G.Screen = {
  width = metrics.widthPixels,
  height = metrics.heightPixels,
  density = metrics.density,
  isTablet = metrics.widthPixels / metrics.density >= 600,
}

-- 字体
import "android.graphics.Typeface"
if Extensions.Config.getBool(Constants.SharedDataKeys.USE_SYSTEM_FONT) then
  _G.Fonts = {
    regular = Typeface.create("sans-serif", Typeface.NORMAL),
    medium = Typeface.create("sans-serif-medium", Typeface.NORMAL),
    bold = Typeface.create("sans-serif", Typeface.BOLD),
  }
 else
  _G.Fonts = {
    regular = Helpers.Static.font("product"),
    medium = Helpers.Static.font("product-Medium"),
    bold = Helpers.Static.font("product-Bold"),
  }
end

local colors = AppTheme.colors
-- 参考 https://github.com/material-components/material-components-android/blob/master/docs/theming/Typography.md
_G.AppTextStyle = {
  -- ========== Display 超大展示文字 ==========
  -- 用于：空状态页、欢迎页、大数字展示（如倒计时、计数器）
  -- 对应 MD3: textAppearanceDisplayLarge
  displayLarge = {
    size = sp2px(57),
    lineHeight = sp2px(64),
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceDisplayMedium
  displayMedium = {
    size = sp2px(45),
    lineHeight = sp2px(52),
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceDisplaySmall
  displaySmall = {
    size = sp2px(36),
    lineHeight = sp2px(44),
    font = Fonts.regular,
    color = colors.onSurface
  },

  -- ========== Headline 页面级大标题 ==========
  -- 用于：详情页标题、文章标题、主要区块标题
  -- 对应 MD3: textAppearanceHeadlineLarge
  headlineLarge = {
    size = sp2px(32),
    lineHeight = sp2px(40),
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceHeadlineMedium
  headlineMedium = {
    size = sp2px(28),
    lineHeight = sp2px(36),
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceHeadlineSmall
  headlineSmall = {
    size = sp2px(24),
    lineHeight = sp2px(32),
    font = Fonts.regular,
    color = colors.onSurface
  },

  -- ========== Title 中等重要性标题 ==========
  -- 用于：卡片标题、对话框标题、列表项主文字、次级页面标题
  -- 对应 MD3: textAppearanceTitleLarge
  titleLarge = {
    size = sp2px(22),
    lineHeight = sp2px(28),
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceTitleMedium
  titleMedium = {
    size = sp2px(16),
    lineHeight = sp2px(24),
    font = Fonts.medium,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceTitleSmall
  titleSmall = {
    size = sp2px(14),
    lineHeight = sp2px(20),
    font = Fonts.medium,
    color = colors.onSurface
  },

  -- ========== Body 正文/描述文字 ==========
  -- 用于：长文本正文、卡片描述、列表项副文字
  -- 对应 MD3: textAppearanceBodyLarge
  bodyLarge = {
    size = sp2px(16),
    lineHeight = sp2px(24),
    font = Fonts.regular,
    color = colors.onSurface
  },
  -- 对应 MD3: textAppearanceBodyMedium
  bodyMedium = {
    size = sp2px(14),
    lineHeight = sp2px(20),
    font = Fonts.regular,
    color = colors.onSurfaceVariant
  },
  -- 对应 MD3: textAppearanceBodySmall
  bodySmall = {
    size = sp2px(12),
    lineHeight = sp2px(16),
    font = Fonts.regular,
    color = colors.onSurfaceVariant
  },

  -- ========== Label 标签/辅助文字 ==========
  -- 用于：按钮文字、Tab标签、设置页分段标题、表单字段标签、提示文字
  -- 对应 MD3: textAppearanceLabelLarge
  labelLarge = {
    size = sp2px(14),
    lineHeight = sp2px(20),
    font = Fonts.medium,
    color = colors.primary
  },
  -- 对应 MD3: textAppearanceLabelMedium
  labelMedium = {
    size = sp2px(12),
    lineHeight = sp2px(16),
    font = Fonts.medium,
    color = colors.onSurfaceVariant
  },
  -- 对应 MD3: textAppearanceLabelSmall
  labelSmall = {
    size = sp2px(11),
    lineHeight = sp2px(16),
    font = Fonts.medium,
    color = colors.primary
  }
}

_G.AppCardStyle = {
  -- 基础卡片样式
  basic = {
    marginLeft = dp2px(12), -- 左边距12dp
    marginRight = dp2px(12), -- 右边距12dp
    marginTop = dp2px(6), -- 上边距6dp
    marginBottom = dp2px(0) -- 下边距0dp
  },
  -- 子卡片样式（嵌套卡片）
  child = {
    marginLeft = dp2px(8), -- 左边距8dp
    marginRight = dp2px(8), -- 右边距8dp
    -- 增大marginTop，增加视觉差
    marginTop = dp2px(8), -- 上边距8dp
    marginBottom = dp2px(0) -- 下边距0dp
  }
}

return M