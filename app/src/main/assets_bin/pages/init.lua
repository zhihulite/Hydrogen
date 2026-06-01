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
M.register("welcome", "pages.activity.welcome.WelcomeActivity", true, true)
M.register("main", "pages.activity.main.MainActivity", true, true)
M.register("login", "pages.activity.login.LoginActivity", true, false)
M.register("image", "pages.activity.image.ImageActivity", true, false)

-- Fragment 模式
M.register("home", "pages.fragment.home.HomeFragment", false)
M.register("answer", "pages.fragment.answer.AnswerFragment", false)
M.register("browser", "pages.fragment.browser.BrowserFragment", false)
M.register("question", "pages.fragment.question.QuestionFragment", false)
M.register("feedback", "pages.fragment.feedback.FeedbackFragment", false)
M.register("people", "pages.fragment.people.PeopleFragment", false)
M.register("people_more", "pages.fragment.people_more.PeopleMoreFragment", false)
M.register("people_list", "pages.fragment.people_list.PeopleListFragment", false)
M.register("collection", "pages.fragment.collection.CollectionFragment", false)
M.register("topic", "pages.fragment.topic.TopicFragment", false)
M.register("content", "pages.fragment.content.ContentFragment", false)
M.register("search", "pages.fragment.search.SearchFragment", false)
M.register("search_result", "pages.fragment.search_result.SearchResultFragment", false)
M.register("history", "pages.fragment.history.HistoryFragment", false)
M.register("local_content", "pages.fragment.local_content.LocalContentFragment", false)
M.register("local_list", "pages.fragment.local_list.LocalListFragment", false)
M.register("settings", "pages.fragment.settings.SettingsFragment", false)
M.register("about", "pages.fragment.about.AboutFragment", false)
M.register("theme_picker", "pages.fragment.theme_picker.ThemePickerFragment", false)
M.register("open_source", "pages.fragment.open_source.OpenSourceFragment", false)
M.register("scan", "pages.fragment.scan.ScanFragment", false)

-- 分发路由
M.registerDispatch("report", function(params)
  local id = params.id
  local type = params.type
  local url = "https://www.zhihu.com/report?id=" .. id .. "&type=" .. type.. "&source=android"
  local name = "browser"
  local params = { url = url }
  return { name = name, params = params }
end)

return M