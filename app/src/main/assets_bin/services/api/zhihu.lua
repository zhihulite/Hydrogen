-- services/api/zhihu.lua
-- api请求

local M = {}

local client = require("services.api.client")
local endpoints = require("services.api.endpoints")

-- ============================================
-- 用户相关
-- ============================================

-- 获取当前用户信息
function M.getCurrentUser(callback)
    client.get(endpoints.ME, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 获取用户信息
function M.getUserInfo(userId, callback)
    local url = string.format(endpoints.USER_INFO, userId)
    client.get(url, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 关注用户
function M.followUser(userId, callback)
    local url = string.format(endpoints.FOLLOW_USER, userId)
    client.post(url, "", function(success)
        callback(success)
    end)
end

-- 取消关注用户
function M.unfollowUser(userId, callback)
    local selfID = Extensions.Config.get(Constants.SharedDataKeys.USER_ID)
    local url = string.format(endpoints.UNFOLLOW_USER, userId, selfID)
    client.delete(url, function(success)
        callback(success)
    end)
end

-- ============================================
-- 内容相关
-- ============================================

-- 获取问题详情
function M.getQuestion(questionId, callback)
    local url = string.format(endpoints.QUESTION_DETAIL, questionId)
    client.get(url, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 获取回答详情
function M.getAnswer(answerId, callback)
    local url = string.format(endpoints.ANSWER_DETAIL, answerId)
    client.get(url, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 获取回答列表（问题页）
function M.getQuestionAnswers(questionId, offset, limit, callback)
    local url = string.format(endpoints.QUESTION_ANSWERS, questionId, offset or 0, limit or 20)
    client.get(url, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- ============================================
-- 推荐流
-- ============================================

-- 获取推荐内容
function M.getRecommendFeed(offset, limit, callback)
    local url = string.format(endpoints.RECOMMEND_FEED, offset or 0, limit or 10)
    client.get(url, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 获取热榜
function M.getHotList(limit, callback)
    local url = string.format(endpoints.HOT_LIST, limit or 50)
    client.get(url, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 获取日报
function M.getDailyNews(callback)
    client.get(endpoints.DAILY_LATEST, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 获取往期日报
function M.getDailyNewsBefore(date, callback)
    local url = string.format(endpoints.DAILY_BEFORE, date)
    client.get(url, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- ============================================
-- 评论相关
-- ============================================

-- 获取评论列表
function M.getComments(contentType, contentId, offset, limit, callback)
    local url = string.format(endpoints.COMMENTS, contentType, contentId, offset or 0, limit or 20)
    client.get(url, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 发表评论
function M.postComment(contentType, contentId, content, replyId, callback)
    local url = string.format(endpoints.POST_COMMENT, contentType, contentId)
    local postData = string.format('{"content":"%s","reply_comment_id":"%s"}', 
        content:gsub('"', '\\"'), replyId or "")
    client.post(url, postData, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 点赞评论
function M.likeComment(commentId, callback)
    local url = string.format(endpoints.LIKE_COMMENT, commentId)
    client.put(url, "", function(success)
        callback(success)
    end)
end

-- 取消点赞评论
function M.unlikeComment(commentId, callback)
    local url = string.format(endpoints.LIKE_COMMENT, commentId)
    client.delete(url, function(success)
        callback(success)
    end)
end

-- ============================================
-- 点赞/感谢
-- ============================================

-- 点赞回答
function M.likeAnswer(answerId, callback)
    local url = string.format(endpoints.LIKE_ANSWER, answerId)
    client.post(url, '{"type":"up"}', function(success)
        callback(success)
    end)
end

-- 取消点赞回答
function M.unlikeAnswer(answerId, callback)
    local url = string.format(endpoints.LIKE_ANSWER, answerId)
    client.post(url, '{"type":"neutral"}', function(success)
        callback(success)
    end)
end

-- 感谢回答
function M.thankAnswer(answerId, callback)
    local url = endpoints.THANK_ANSWER
    local data = string.format('{"content_type":"answers","content_id":"%s","action_type":"emojis","action_value":"red_heart"}', answerId)
    client.post(url, data, function(success)
        callback(success)
    end)
end

-- 取消感谢回答
function M.unthankAnswer(answerId, callback)
    local url = string.format("%s?content_type=answers&content_id=%s&action_type=emojis&action_value=", 
        endpoints.THANK_ANSWER, answerId)
    client.delete(url, function(success)
        callback(success)
    end)
end

-- ============================================
-- 收藏夹
-- ============================================

-- 获取收藏夹内容
function M.getCollection(collectionId, offset, callback)
    local url = string.format(endpoints.COLLECTION_CONTENTS, collectionId, offset or 0)
    client.get(url, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 添加到收藏夹
function M.addToCollection(contentType, contentId, collectionId, callback)
    local url = string.format(endpoints.ADD_TO_COLLECTION, contentType, contentId)
    local data = string.format("add_collections=%s", collectionId)
    client.put(url, data, function(success)
        callback(success)
    end)
end

-- 从收藏夹移除
function M.removeFromCollection(contentType, contentId, collectionId, callback)
    local url = string.format(endpoints.ADD_TO_COLLECTION, contentType, contentId)
    local data = string.format("remove_collections=%s", collectionId)
    client.put(url, data, function(success)
        callback(success)
    end)
end

-- ============================================
-- 搜索
-- ============================================

-- 搜索
function M.search(query, type, offset, limit, callback)
    local url = string.format(endpoints.SEARCH, 
        NetWork.urlEncode(query), 
        type or "general", 
        offset or 0, 
        limit or 20)
    client.get(url, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 搜索建议
function M.searchSuggest(query, callback)
    local url = string.format(endpoints.SEARCH_SUGGEST, NetWork.urlEncode(query))
    client.get(url, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

-- 热门搜索
function M.getTopSearch(callback)
    client.get(endpoints.TOP_SEARCH, function(success, data)
        if success and data then
            callback(json.decode(data))
        else
            callback(nil)
        end
    end)
end

return M