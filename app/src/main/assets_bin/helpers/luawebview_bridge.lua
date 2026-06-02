-- helpers/luawebview_bridge.lua
-- webview bridge

local M = {}

local moduleCache = {}

local function colorToHex(colorInt)
  if type(colorInt) ~= "number" then
    return "#FFFFFFFF"
  end
  local rgb = 0xFFFFFF & colorInt
  return string.format("#%06X", rgb)
end

local function getDefaultSettings()
  local colors = AppTheme.colors
  local background_color = colors.surface or 0xFFFFFFFF
  local hexColor = colorToHex(background_color)
  return {
    dark_mode = AppTheme.isEffectiveNight(),
    custom_font = Extensions.Config.has(Constants.SharedDataKeys.CUSTOM_WEB_FONT),
    background_color = hexColor,
    debug = Extensions.Config.getBool(Constants.SharedDataKeys.ERUDA) or false,
    image_viewer = true,
    answer_code_scroll = true,
    scroll_restore = true,
    fade_animation = true,
    video_answer = true,
    md_copy = true,
    enable_mhtml_convert = false,
  }
end

function M.getModuleCode(modulePath)
  if moduleCache[modulePath] then
    return moduleCache[modulePath]
  end

  local code = Helpers.Static.getJSContent(modulePath)
  if code then
    moduleCache[modulePath] = code
  end

  return code or ""
end

function M.getMergedModulesJS()
  local modules = {
    'core/style-manager',
    'core/fetch-manager',
    'utils/dom-helper',
    'utils/zhihu-bridge',
    'features/custom-font',
    'features/image-viewer',
    'features/fade-animation',
    'features/dark-mode',
    'features/content-background',
    'features/scroll-restore',
    'features/markdown-copy',
    'features/mhtml-convert',
    'features/video-answer',
    'features/zhihu-style-fix',
    'features/screenshot',
    'features/scroll-exposure-tracker',
    'pages/answer',
    'pages/pin',
    'pages/messages',
    'pages/setting',
    'pages/drama',
    'pages/notification',
    'pages/ask',
    'pages/add-column',
    'pages/zvideo',
    'pages/special',
    'pages/sign_in',
    'pages/report',
    "loader"
  }

  local codes = {}
  for _, path in ipairs(modules) do
    local code = M.getModuleCode(path)
    if code and code ~= "" then
      table.insert(codes, code)
    end
  end

  local debug = false
  if debug then
    local cacheDir = activity.cacheDir
    local path = cacheDir.path .. "/megred.js"
    Extensions.File.write(path, table.concat(codes, "\n"))
    print("luawebview_bridge [debug] megred.js 保存到: " .. path)
  end
  return table.concat(codes, "\n")
end

function M.addBridge(webView, userSettings)
  local defaultSettings = getDefaultSettings()

  local messageListener = nil

  local bridge = luajava.createProxy("com.hydrogen.view.LuaWebView$Bridge", {
    execute = function(action, data)
      if action == "getConfig" then
        -- 用户配置优先
        local merged = {}
        for k, v in pairs(userSettings or {}) do
          merged[k] = v
        end
        for k, v in pairs(defaultSettings) do
          if merged[k] == nil then
            merged[k] = v
          end
        end

        return json.encode(merged)
       elseif action == "loadJSModule" then
        -- data 为模块名，如 "eruda", "turndown"
        local code = M.getModuleCode("libs/" .. data)
        if code and code ~= "" then
          activity.runOnUiThread(function()
            webView.evaluateJavascript(code, nil)
          end)
        end
        return ""
       elseif action == "log" then
        print("[JS]", data)
        return ""
       elseif action == "toast" then
        tip(data)
        return ""
       elseif action == "openImages" then
        local decoded = json.decode(data)
        local index = table.remove(decoded)
        Router.go("image", { data = decoded, index = index})
        return ""
       elseif action == "screenshotError" then
        tip("截图失败: " .. (data or "未知错误"))
        return ""
       elseif action == "scrollHistory" then
        local historyData = json.decode(data)
        HistoryService.syncToServer(historyData.id, historyData.type, historyData.progress)
       elseif action == "copyText" then
        Helpers.UI.copyText(data)
        return ""
      elseif action == "finishPage" then
        Router.back()
        return ""
       elseif action == "message" then
        if messageListener then
          local msg = json.decode(data)
          local action = msg.action
          local data = msg.data
          local result = messageListener(action, data)
          return result or ""
        end
        return ""
      end

      return ""
    end
  })

  webView.bridge = bridge

  return {
    setMessageListener = function(listener)
      messageListener = listener
    end,
    updateSettings = function(newSettings)
      userSettings = newSettings
    end
  }
end

return M