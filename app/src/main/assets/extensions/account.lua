-- extensions/account.lua
-- 登录态门面：用户 ID 与登录凭证的唯一读写入口

local CookieManager = luajava.bindClass("android.webkit.CookieManager")

local M = {}

-- 是否已登录：登录成功即写入 user_id，登录失效/退出时清除
--- @return boolean
function M.isLoggedIn()
  return Extensions.Config.has(Constants.SharedDataKeys.USER_ID)
end

--- 当前登录用户 ID，未登录返回 nil
--- @return string|nil
function M.getUserId()
  return Extensions.Config.get(Constants.SharedDataKeys.USER_ID)
end

--- 登录凭证 JSON 原文（WebView oauth 响应体），未登录返回 nil
--- @return string|nil
function M.getSignInData()
  return Extensions.Config.getString(Constants.SharedDataKeys.SIGN_IN_DATA)
end

--- 保存登录凭证 JSON 原文（登录页 login_success 消息）
--- @param data string 凭证 JSON
function M.saveSignInData(data)
  Extensions.Config.set(Constants.SharedDataKeys.SIGN_IN_DATA, data)
end

--- 保存登录校验通过的用户 ID，标志登录完成
--- @param userId string
function M.saveUserId(userId)
  Extensions.Config.set(Constants.SharedDataKeys.USER_ID, userId)
end

--- 清除登录状态：cookie、凭证、用户 ID 与设备 ID，并重建请求头。
--- 凭证清空后 _G.Headers 仍持有失效 Authorization，必须重建
function M.logout()
  CookieManager.instance.removeAllCookies(nil)
  CookieManager.instance.flush()
  Extensions.Config.delete(Constants.SharedDataKeys.SIGN_IN_DATA)
  Extensions.Config.delete(Constants.SharedDataKeys.USER_ID)
  Extensions.Config.delete(Constants.SharedDataKeys.UDID)
  buildHeaders()
end

return M
