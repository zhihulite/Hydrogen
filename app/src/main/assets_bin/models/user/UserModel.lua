-- models/user/UserModel.lua
-- 用户信息 - BaseModel

local BaseModel = require("models.base.BaseModel")

local UserModel = Extensions.Class(BaseModel)
UserModel:chainUp("destroy")

function UserModel:ctor(userId)
  self:setUserId(userId or "")
  self.requestHeadKey = "defaultHead"
  self.needLogin = false
end

function UserModel:setUserId(userId)
  self.userId = tostring(userId)
  self.data = nil
  self.isLoaded = false
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

    self.data = {
      id = tostring(response.id),
      name = response.name,
      headline = response.headline or "",
      avatarUrl = response.avatar_url or "",
      voteupCount = response.voteup_count or 0,
      followerCount = response.follower_count or 0,
      followingCount = response.following_count or 0,
      isFollowing = response.is_following or false,
      isBlocking = response.is_blocking or false,
      urlToken = response.url_token,
    }

    self.isLoaded = true
    self:notifyListeners("dataChanged", self.data)

    if callback then callback(true, self.data) end
  end)
end

function UserModel:loadCurrentUser(callback)
  local url = "https://www.zhihu.com/api/v4/me"

  self:fetch(url, nil, function(success, response)
    if not success then
      if callback then callback(false, nil) end
      return
    end

    self:setUserId(tostring(response.id))
    self.data = {
      id = tostring(response.id),
      name = response.name,
      headline = response.headline or "",
      avatarUrl = response.avatar_url or "",
      urlToken = response.url_token,
    }

    self.isLoaded = true
    self:notifyListeners("dataChanged", self.data)

    if callback then callback(true, self.data) end
  end)
end

function UserModel:follow(callback)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  if not self.userId or self.userId == "" then
    tip("用户ID无效")
    if callback then callback(false) end
    return
  end

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
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  if not self.userId or self.userId == "" then
    tip("用户ID无效")
    if callback then callback(false) end
    return
  end

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
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  if not self.userId or self.userId == "" then
    tip("用户ID无效")
    if callback then callback(false) end
    return
  end

  local url = "https://api.zhihu.com/settings/blocked_users"
  local data = "people_id=" .. self.userId

  self:post(url, data, { requestHeadKey = "app" }, function(success)
    if success and self.data then
      self.data.isBlocking = true
      self:notifyListeners("dataChanged", self.data)
    end
    if callback then callback(success) end
  end)
end

function UserModel:unblock(callback)
  if not Extensions.Config.has(Constants.SharedDataKeys.USER_ID) then
    tip("请登录后使用")
    if callback then callback(false) end
    return
  end

  if not self.userId or self.userId == "" then
    tip("用户ID无效")
    if callback then callback(false) end
    return
  end

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