-- pages/init.lua
-- 页面导出

local M = {}

local pageCache = {}

-- 注册页面
function M.register(name, path, isActivity)
  M[name] = {
    path = path,
    isActivity = isActivity or false,
  }
end

-- 获取页面
function M.get(name)
  if pageCache[name] then
    return pageCache[name]
  end

  local info = M[name]
  if not info then
    return nil
  end

  local ok, page = pcall(require, info.path)
  if ok then
    pageCache[name] = page
    return page
  end

  return nil
end

-- 获取页面类型
function M.isActivity(name)
  local info = M[name]
  return info and info.isActivity or false
end

-- 获取页面路径
function M.getPath(name)
  local info = M[name]
  return info and info.path or nil
end

-- 预注册所有页面
-- Activity 模式（独立虚拟机，跳转到 BlankActivity 执行）
M.register("welcome", "pages.activity.welcome.WelcomeActivity", true)
M.register("login", "pages.activity.login.LoginActivity", true)
M.register("main", "pages.activity.main.MainActivity", true)   -- 新增主Activity

-- Fragment 模式（共享虚拟机，在主 Activity 容器中切换）
M.register("home", "pages.fragment.home.HomeFragment", false)
M.register("answer", "pages.fragment.answer.AnswerFragment", false)
M.register("browser", "pages.fragment.browser.BrowserFragment", false)
M.register("question", "pages.fragment.question.QuestionFragment", false)
M.register("feedback", "pages.fragment.feedback.FeedbackFragment", false)
--M.register("comment", "pages.fragment.comment.CommentFragment", false)
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
M.register("image", "pages.activity.image.ImageActivity", true)

return M