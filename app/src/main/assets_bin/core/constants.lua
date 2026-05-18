-- core/constants.lua
-- app常量

local M = {}

M.SharedDataKeys = {
  -- 浏览设置
  AUTO_OPEN_CLIPBOARD = "自动打开剪贴板上的知乎链接",
  AUTO_NIGHT_MODE = "Setting_Auto_Night_Mode",
  NIGHT_MODE = "Setting_Night_Mode",
  OLED_MODE = "OLED",
  NO_IMAGE = "不加载图片",
  SMART_NO_IMAGE = "智能无图模式",
  FONT_SIZE = "font_size",
  FEED_CACHE = "feed_cache",
  HOME_TAB_ORDER = "home_cof",
  ANSWER_SINGLE_PAGE = "回答单页模式",
  CLOSE_HOT_SEARCH = "关闭热门搜索",
  CODE_WRAP = "代码块自动换行",
  SCROLL_SENSE = "scroll_sense",
  SWITCH_WEBVIEW = "切换webview",
  USE_SYSTEM_FONT = "使用系统字体",
  CUSTOM_WEB_FONT = "自定义网页字体(beta)",
  BLOCK_WORDS = "屏蔽词",

  -- 主页设置
  HOT_CLOSE_IMAGE = "热榜关闭图片",
  HOT_CLOSE_HOTNESS = "热榜关闭热度",
  CLOSE_RECOMMEND_ALL_SECTION = "关闭全站",
  FOLLOW_DEFAULT_TAB = "设置关注默认选中栏",
  HOME_BOTTOM_BAR = "设置主页底栏排列",

  -- 缓存设置
  AUTO_CLEAN_CACHE = "自动清理缓存",

  -- 页面设置
  THEME_SETTING = "theme",
  PARALLEL_WORLD = "平行世界",
  PREDICTIVE_BACK = "预见性返回手势",
  USE_SIMPLE_ANIMATION = "使用简洁动画",

  -- 用户信息
  USER_ID = "idx",
  SIGN_IN_DATA = "signdata",
  -- 其他
  VOLUME_SWITCH_TAB = "音量键选择tab",
  SHOW_VIRTUAL_SCROLL = "显示虚拟滑动按键",
  DEBUG_MODE = "调式模式",
  ALLOW_LOAD_CODE = "允许加载代码",
  ERUDA = "eruda",
  AUTO_CHECK_UPDATE = "自动检测更新",
  UDID = "udid",
  SEARCH_URL_TEMPLATE = "搜索引擎",
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
  [M.SharedDataKeys.CUSTOM_WEB_FONT] = "", -- 自定义网页字体
  [M.SharedDataKeys.BLOCK_WORDS] = "", -- 屏蔽词列表

  -- 主页设置
  [M.SharedDataKeys.HOT_CLOSE_IMAGE] = false, -- 热榜关闭图片
  [M.SharedDataKeys.HOT_CLOSE_HOTNESS] = false, -- 热榜关闭热度
  [M.SharedDataKeys.CLOSE_RECOMMEND_ALL_SECTION] = false, -- 关闭全站
  [M.SharedDataKeys.FOLLOW_DEFAULT_TAB] = nil, -- 关注默认Tab
  [M.SharedDataKeys.HOME_BOTTOM_BAR] = "", -- 主页底栏排列

  -- 缓存设置
  [M.SharedDataKeys.AUTO_CLEAN_CACHE] = false, -- 自动清理缓存

  -- 页面设置
  [M.SharedDataKeys.THEME_SETTING] = "Default", -- 主题设置
  [M.SharedDataKeys.PARALLEL_WORLD] = false, -- 平行世界
  [M.SharedDataKeys.PREDICTIVE_BACK] = false, -- 预见性返回手势
  [M.SharedDataKeys.USE_SIMPLE_ANIMATION] = false, -- 默认关闭，保留共享元素动画

  -- 用户信息
  [M.SharedDataKeys.USER_ID] = "", -- 用户ID
  [M.SharedDataKeys.SIGN_IN_DATA] = "", -- 登录凭证JSON

  -- 其他
  [M.SharedDataKeys.VOLUME_SWITCH_TAB] = false, -- 音量键切换Tab
  [M.SharedDataKeys.SHOW_VIRTUAL_SCROLL] = false, -- 显示虚拟滑动按键
  [M.SharedDataKeys.DEBUG_MODE] = false, -- 调试模式
  [M.SharedDataKeys.ALLOW_LOAD_CODE] = false, -- 允许加载代码
  [M.SharedDataKeys.ERUDA] = false, -- Eruda调试工具
  [M.SharedDataKeys.AUTO_CHECK_UPDATE] = true, -- 自动检测更新
  [M.SharedDataKeys.UDID] = "", -- 唯一id
  [M.SharedDataKeys.SEARCH_URL_TEMPLATE] = "https://www.bing.com/search?q=site%3Azhihu.com%20", -- 搜索引擎模板
  [M.SharedDataKeys.FEED_CACHE_TIP] = false, -- 主页重复缓存提示
  [M.SharedDataKeys.IGNORED_VERSION] = nil, -- 忽略版本号
}

return M
