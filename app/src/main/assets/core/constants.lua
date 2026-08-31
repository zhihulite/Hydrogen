-- core/constants.lua
-- app常量

local M = {}

-- 配置键 schema：每键一处定义，name 为 Lua 侧常量名，default 为缺省值
-- （nil 表示无默认、按未设置处理），desc 为用途说明。
-- 存储键默认取 name 小写，需要不同存储键时显式写 key 字段
local SETTINGS = {
  -- 浏览设置
  { name = "AUTO_OPEN_CLIPBOARD", default = false, desc = "自动打开剪贴板链接" },
  { name = "AUTO_NIGHT_MODE", default = false, desc = "自动夜间模式" },
  { name = "NIGHT_MODE", default = false, desc = "夜间模式" },
  { name = "OLED_MODE", default = false, desc = "OLED模式" },
  { name = "NO_IMAGE", default = false, desc = "不加载图片" },
  { name = "SMART_NO_IMAGE", default = false, desc = "智能无图模式" },
  { name = "FONT_SIZE", default = 20, desc = "字体大小 sp" },
  { name = "PAGE_MARGIN", default = 12, desc = "页边距 dp" },
  { name = "CARD_GAP", default = 6, desc = "卡片间距 dp" },
  { name = "CARD_PADDING", default = 12, desc = "卡片内边距 dp" },
  { name = "FEED_CACHE", default = 100, desc = "Feed缓存数量" },
  { name = "HOME_TAB_ORDER", default = "推荐,热榜,关注,推荐", desc = "主页标签顺序" },
  { name = "ANSWER_SINGLE_PAGE", default = false, desc = "回答单页模式" },
  { name = "CLOSE_HOT_SEARCH", default = false, desc = "关闭热门搜索" },
  { name = "CODE_WRAP", key = "answer_code_wrap", default = true, desc = "回答页代码块自动换行" },
  { name = "SCROLL_SENSE", key = "answer_scroll_sense", default = 2.5, desc = "左右滑切换回答的倍数阈值" },
  { name = "SWITCH_WEBVIEW", default = false, desc = "切换WebView" },
  { name = "USE_SYSTEM_FONT", default = false, desc = "使用系统字体" },
  { name = "CUSTOM_WEB_FONT", default = nil, desc = "自定义网页字体" },
  { name = "BLOCK_WORDS", default = nil, desc = "屏蔽词列表" },

  -- 主页设置
  { name = "HOT_CLOSE_IMAGE", default = false, desc = "热榜关闭图片" },
  { name = "HOT_CLOSE_HOTNESS", default = false, desc = "热榜关闭热度" },
  { name = "CLOSE_RECOMMEND_ALL_SECTION", default = false, desc = "关闭全站" },
  { name = "FOLLOW_DEFAULT_TAB", default = nil, desc = "关注默认Tab" },

  -- 缓存设置
  { name = "AUTO_CLEAN_CACHE", default = false, desc = "自动清理缓存" },

  -- 页面设置
  { name = "THEME_SETTING", default = "Default", desc = "主题设置" },
  { name = "PARALLEL_WORLD", default = false, desc = "平行世界" },
  { name = "PREDICTIVE_BACK", default = false, desc = "预见性返回手势" },
  { name = "USE_SIMPLE_ANIMATION", default = false, desc = "关闭共享元素动画" },

  -- 用户信息
  { name = "USER_ID", default = nil, desc = "用户ID" },
  { name = "SIGN_IN_DATA", default = nil, desc = "登录凭证JSON" },

  -- 回答页设置
  { name = "VOLUME_SWITCH_TAB", key = "answer_volume_switch", default = false, desc = "音量键切换回答" },
  { name = "SHOW_VIRTUAL_SCROLL", key = "answer_virtual_scroll", default = false, desc = "回答页悬浮滚动按钮" },

  -- 其他
  { name = "DEBUG_MODE", default = false, desc = "调试模式" },
  { name = "ALLOW_LOAD_CODE", default = false, desc = "允许加载代码" },
  { name = "ERUDA", default = false, desc = "Eruda调试工具" },
  { name = "AUTO_CHECK_UPDATE", default = true, desc = "自动检测更新" },
  { name = "UDID", default = nil, desc = "唯一id" },
  { name = "SEARCH_URL_TEMPLATE", default = "https://www.bing.com/search?q=site%3Azhihu.com%20", desc = "搜索引擎模板" },
  { name = "FEED_CACHE_TIP", default = false, desc = "主页重复缓存提示" },
  { name = "IGNORED_VERSION", default = nil, desc = "忽略版本号" },
}

-- 派生导出：SharedDataKeys 供调用方引用存储键，defaults 供 Config.init
M.SharedDataKeys = {}
M.defaults = {}
for _, setting in ipairs(SETTINGS) do
  M.SharedDataKeys[setting.name] = setting.key or setting.name:lower()
  M.defaults[M.SharedDataKeys[setting.name]] = setting.default
end

-- 欢迎页协议：name 同时对应 agreements/<name>.html 与 <name>_agreed 配置项
M.Agreements = {
  { title = "用户协议", name = "user_agreement" },
  { title = "隐私政策", name = "privacy_policy" },
}

-- 请求头身份 key（对应 _G.Headers 的字段，model 经 requestHeadKey 选用）
M.RequestHeadKeys = {
  APP = "app", -- app 接口身份，带 Authorization Bearer
  DEFAULT_HEAD = "defaultHead", -- 网页接口身份，带 cookie
  POST = "post", -- 网页接口身份的 POST 版本，加 json content-type
  POST_APP = "postApp", -- app 接口身份的 POST 版本，加 json content-type
}

-- requestHeadKey 合法值白名单：_G.Headers 的 defaultHead / post 经 __index 懒构建，
-- 按 key 直接取 Headers 值做合法性探测会触发构建副作用，校验一律查本表
M.ValidRequestHeadKeys = {
  [M.RequestHeadKeys.APP] = true,
  [M.RequestHeadKeys.DEFAULT_HEAD] = true,
  [M.RequestHeadKeys.POST] = true,
  [M.RequestHeadKeys.POST_APP] = true,
}

return M
