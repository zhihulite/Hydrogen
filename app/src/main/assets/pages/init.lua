-- pages/init.lua
-- 页面导出

local M = {}

local allPages = {}

-- 注册页面
function M.register(name, path, isActivity, replace)
  allPages[name] = {
    path = path,
    isActivity = isActivity or false,
    replace = replace or false,
  }
end

-- 注册分发路由
function M.registerDispatch(name, resolver)
  allPages[name] = {
    dispatch = true,
    resolver = resolver,
  }
end

-- 获取页面
function M.get(name)
  local info = allPages[name]
  if not info then
    return nil
  end

  if info.dispatch then
    return info.resolver
  end

  local ok, page = pcall(require, info.path)
  if ok then
    return page
  end

  return nil
end

-- 获取页面类型
function M.isActivity(name)
  local info = allPages[name]
  return info and info.isActivity or false
end

-- 获取页面路径
function M.getPath(name)
  local info = allPages[name]
  return info and info.path or nil
end

-- 是否是分发路由
function M.isDispatch(name)
  local info = allPages[name]
  return info and info.dispatch == true
end

-- 获取所有页面
function M.getAllPages()
  local pages = {}
  for name, info in pairs(allPages) do
    if info.path then
      table.insert(pages, {
        name = name,
        path = info.path,
        isActivity = info.isActivity,
        replace = info.replace
      })
    end
  end
  return pages
end

-- 注册所有页面到 Router
function M.registerToRouter(router)
  for name, info in pairs(allPages) do
    if info.path then
      if info.isActivity then
        router.registerActivity(name, info.path, info.replace)
       else
        router.registerFragment(name, info.path)
      end
     elseif info.dispatch then
      router.registerDispatch(name, info.resolver)
    end
  end
end

-- ============ 预注册所有页面 ============

-- Activity 模式
M.register("welcome", "pages.activity.welcome.welcome_activity", true, true)
M.register("main", "pages.activity.main.main_activity", true, true)
M.register("login", "pages.activity.login.login_activity", true, false)
M.register("image", "pages.activity.image.image_activity", true, false)

-- Fragment 模式
M.register("home", "pages.fragment.home.home_fragment", false)
M.register("answer", "pages.fragment.answer.answer_fragment", false)
M.register("browser", "pages.fragment.browser.browser_fragment", false)
M.register("question", "pages.fragment.question.question_fragment", false)
M.register("feedback", "pages.fragment.feedback.feedback_fragment", false)
M.register("people", "pages.fragment.people.people_fragment", false)
M.register("people_more", "pages.fragment.people_more.people_more_fragment", false)
M.register("people_list", "pages.fragment.people_list.people_list_fragment", false)
M.register("collection", "pages.fragment.collection.collection_fragment", false)
M.register("topic", "pages.fragment.topic.topic_fragment", false)
M.register("content", "pages.fragment.content.content_fragment", false)
M.register("search", "pages.fragment.search.search_fragment", false)
M.register("search_result", "pages.fragment.search_result.search_result_fragment", false)
M.register("history", "pages.fragment.history.history_fragment", false)
M.register("local_content", "pages.fragment.local_content.local_content_fragment", false)
M.register("local_list", "pages.fragment.local_list.local_list_fragment", false)
M.register("settings", "pages.fragment.settings.settings_fragment", false)
M.register("about", "pages.fragment.about.about_fragment", false)
M.register("theme_picker", "pages.fragment.theme_picker.theme_picker_fragment", false)
M.register("open_source", "pages.fragment.open_source.open_source_fragment", false)
M.register("scan", "pages.fragment.scan.scan_fragment", false)

-- 分发路由
M.registerDispatch("report", function(params)
  local reportId = params.id
  local reportType = params.type
  local url = "https://www.zhihu.com/report?id=" .. reportId .. "&type=" .. reportType .. "&source=android"
  return { name = "browser", params = { url = url } }
end)

return M