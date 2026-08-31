-- core/constants.lua
-- app常量

local M = {}

M.SharedDataKeys = {
  -- 浏览设置
  AUTO_OPEN_CLIPBOARD = "auto_open_clipboard",
  AUTO_NIGHT_MODE = "auto_night_mode",
  NIGHT_MODE = "night_mode",
  OLED_MODE = "oled_mode",
  NO_IMAGE = "no_image",
  SMART_NO_IMAGE = "smart_no_image",
  FONT_SIZE = "font_size",
  FEED_CACHE = "feed_cache",
  HOME_TAB_ORDER = "home_tab_order",
  ANSWER_SINGLE_PAGE = "answer_single_page",
  CLOSE_HOT_SEARCH = "close_hot_search",
  CODE_WRAP = "code_wrap",
  SCROLL_SENSE = "scroll_sense",
  SWITCH_WEBVIEW = "switch_webview",
  USE_SYSTEM_FONT = "use_system_font",
  CUSTOM_WEB_FONT = "custom_web_font",
  BLOCK_WORDS = "block_words",

  -- 主页设置
  HOT_CLOSE_IMAGE = "hot_close_image",
  HOT_CLOSE_HOTNESS = "hot_close_hotness",
  CLOSE_RECOMMEND_ALL_SECTION = "close_recommend_all_section",
  FOLLOW_DEFAULT_TAB = "follow_default_tab",

  -- 缓存设置
  AUTO_CLEAN_CACHE = "auto_clean_cache",

  -- 页面设置
  THEME_SETTING = "theme_setting",
  PARALLEL_WORLD = "parallel_world",
  PREDICTIVE_BACK = "predictive_back",
  USE_SIMPLE_ANIMATION = "use_simple_animation",

  -- 用户信息
  USER_ID = "user_id",
  SIGN_IN_DATA = "sign_in_data",
  -- 其他
  VOLUME_SWITCH_TAB = "volume_switch_tab",
  SHOW_VIRTUAL_SCROLL = "show_virtual_scroll",
  DEBUG_MODE = "debug_mode",
  ALLOW_LOAD_CODE = "allow_load_code",
  ERUDA = "eruda",
  AUTO_CHECK_UPDATE = "auto_check_update",
  UDID = "udid",
  SEARCH_URL_TEMPLATE = "search_url_template",
  FEED_CACHE_TIP = "feed_cache_tip",
  IGNORED_VERSION = "ignored_version",
}

M.defaults = {
  -- 浏览设置
  [M.SharedDataKeys.AUTO_OPEN_CLIPBOARD] = false, -- 自动打开剪贴板
  [M.SharedDataKeys.AUTO_NIGHT_MODE] = false, -- 自动夜间模式
  [M.SharedDataKeys.NIGHT_MODE] = false, -- 夜间模式
  [M.SharedDataKeys.OLED_MODE] = false, -- OLED模式
  [M.SharedDataKeys.NO_IMAGE] = false, -- 不加载图片
  [M.SharedDataKeys.SMART_NO_IMAGE] = false, -- 智能无图模式
  [M.SharedDataKeys.FONT_SIZE] = 20, -- 字体大小
  [M.SharedDataKeys.FEED_CACHE] = 100, -- Feed缓存数量
  [M.SharedDataKeys.HOME_TAB_ORDER] = "推荐,热榜,关注,推荐", -- 主页标签顺序
  [M.SharedDataKeys.ANSWER_SINGLE_PAGE] = false, -- 回答单页模式
  [M.SharedDataKeys.CLOSE_HOT_SEARCH] = false, -- 关闭热门搜索
  [M.SharedDataKeys.CODE_WRAP] = true, -- 代码块自动换行
  [M.SharedDataKeys.SCROLL_SENSE] = 2.5, -- 左右滑动倍数阈值
  [M.SharedDataKeys.SWITCH_WEBVIEW] = false, -- 切换WebView
  [M.SharedDataKeys.USE_SYSTEM_FONT] = false, -- 使用系统字体
  [M.SharedDataKeys.CUSTOM_WEB_FONT] = nil, -- 自定义网页字体
  [M.SharedDataKeys.BLOCK_WORDS] = nil, -- 屏蔽词列表

  -- 主页设置
  [M.SharedDataKeys.HOT_CLOSE_IMAGE] = false, -- 热榜关闭图片
  [M.SharedDataKeys.HOT_CLOSE_HOTNESS] = false, -- 热榜关闭热度
  [M.SharedDataKeys.CLOSE_RECOMMEND_ALL_SECTION] = false, -- 关闭全站
  [M.SharedDataKeys.FOLLOW_DEFAULT_TAB] = nil, -- 关注默认Tab

  -- 缓存设置
  [M.SharedDataKeys.AUTO_CLEAN_CACHE] = false, -- 自动清理缓存

  -- 页面设置
  [M.SharedDataKeys.THEME_SETTING] = "Default", -- 主题设置
  [M.SharedDataKeys.PARALLEL_WORLD] = false, -- 平行世界
  [M.SharedDataKeys.PREDICTIVE_BACK] = false, -- 预见性返回手势
  [M.SharedDataKeys.USE_SIMPLE_ANIMATION] = false, -- 默认关闭，保留共享元素动画

  -- 用户信息
  [M.SharedDataKeys.USER_ID] = nil, -- 用户ID
  [M.SharedDataKeys.SIGN_IN_DATA] = nil, -- 登录凭证JSON

  -- 其他
  [M.SharedDataKeys.VOLUME_SWITCH_TAB] = false, -- 音量键切换Tab
  [M.SharedDataKeys.SHOW_VIRTUAL_SCROLL] = false, -- 显示虚拟滑动按键
  [M.SharedDataKeys.DEBUG_MODE] = false, -- 调试模式
  [M.SharedDataKeys.ALLOW_LOAD_CODE] = false, -- 允许加载代码
  [M.SharedDataKeys.ERUDA] = false, -- Eruda调试工具
  [M.SharedDataKeys.AUTO_CHECK_UPDATE] = true, -- 自动检测更新
  [M.SharedDataKeys.UDID] = nil, -- 唯一id
  [M.SharedDataKeys.SEARCH_URL_TEMPLATE] = "https://www.bing.com/search?q=site%3Azhihu.com%20", -- 搜索引擎模板
  [M.SharedDataKeys.FEED_CACHE_TIP] = false, -- 主页重复缓存提示
  [M.SharedDataKeys.IGNORED_VERSION] = nil, -- 忽略版本号
}

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
