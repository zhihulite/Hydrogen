-- models/user/user_model.lua
-- 用户信息 - BaseModel

local BaseModel = require("models.base.base_model")

local UserModel = Extensions.Class(BaseModel)

-- /members、/me 接口的原始响应 → 驼峰字段表
local function mapMember(r)
  return {
    id = tostring(r.id),
    name = r.name,
    headline = r.headline or "",
    avatarUrl = r.avatar_url or "",
    voteupCount = Helpers.ZhihuItem.voteupOf(r),
    followerCount = r.follower_count or 0,
    followingCount = r.following_count or 0,
    isFollowing = r.is_following or false,
    isBlocking = r.is_blocking or false,
    urlToken = r.url_token,
  }
end

function UserModel:ctor(userId)
  self:setUserId(userId or "")
  self.requestHeadKey = Constants.RequestHeadKeys.DEFAULT_HEAD
  self.needLogin = false
end

function UserModel:setUserId(userId)
  self.userId = tostring(userId)
  self.data = nil
  self.isLoaded = false
end

-- fetch 的数据出口：网络回调经此把原始响应换成驼峰字段表再写入 self.data
function UserModel:parseResponse(response, params)
  return mapMember(response)
end

function UserModel:load(params, callback)
  if not self.userId or self.userId == "" then
    if callback then callback(false, nil) end
    return
  end

  local include = '?include=voteup_count,follower_count,following_count,is_following,is_blocking,headline,avatar_url'
  local url = "https://www.zhihu.com/api/v4/members/" .. self.userId .. include

  self:fetch(url, params, function(success, response)
    if not success then
      if callback then callback(false, nil) end
      return
    end

    -- fetch 已通过 parseResponse 写入 self.data 并通知过 dataChanged
    if callback then callback(true, response) end
  end)
end

function UserModel:loadCurrentUser(callback)
  local url = "https://www.zhihu.com/api/v4/me"

  self:fetch(url, nil, function(success, response)
    if not success then
      if callback then callback(false, nil) end
      return
    end

    -- 仅更新目标用户 ID，fetch 写入的 data 与 isLoaded 保持有效
    self.userId = tostring(response.id)

    if callback then callback(true, response) end
  end)
end

-- 关注/拉黑等操作的统一前置校验：登录态与目标用户 ID，不满足时提示并回调失败
local function canAct(model, callback)
  if not model:requireLogin(callback) then
    return false
  end
  if not model.userId or model.userId == "" then
    tip("用户ID无效")
    if callback then callback(false) end
    return false
  end
  return true
end

function UserModel:follow(callback)
  if not canAct(self, callback) then return end

  local url = "https://api.zhihu.com/people/" .. self.userId .. "/followers"

  self:post(url, "", nil, function(success)
    if success and self.data then
      self.data.isFollowing = true
      self.data.followerCount = (self.data.followerCount or 0) + 1
      self:notifyListeners("dataChanged", self.data)
    end
    if callback then callback(success) end
  end)
end

function UserModel:unfollow(callback)
  if not canAct(self, callback) then return end

  local selfID = Extensions.Config.get(Constants.SharedDataKeys.USER_ID)
  local url = "https://api.zhihu.com/people/" .. self.userId .. "/followers/" .. selfID

  self:delete(url, nil, function(success)
    if success and self.data then
      self.data.isFollowing = false
      self.data.followerCount = math.max(0, (self.data.followerCount or 1) - 1)
      self:notifyListeners("dataChanged", self.data)
    end
    if callback then callback(success) end
  end)
end

function UserModel:block(callback)
  if not canAct(self, callback) then return end

  local url = "https://api.zhihu.com/settings/blocked_users"
  local data = "people_id=" .. self.userId

  self:post(url, data, { requestHeadKey = Constants.RequestHeadKeys.APP }, function(success)
    if success and self.data then
      self.data.isBlocking = true
      self:notifyListeners("dataChanged", self.data)
    end
    if callback then callback(success) end
  end)
end

function UserModel:unblock(callback)
  if not canAct(self, callback) then return end

  local url = "https://api.zhihu.com/settings/blocked_users/" .. self.userId

  self:delete(url, nil, function(success)
    if success and self.data then
      self.data.isBlocking = false
      self:notifyListeners("dataChanged", self.data)
    end
    if callback then callback(success) end
  end)
end

return UserModel