import "android.webkit.CookieManager"

function urlEncode(s)
  local s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
  return string.gsub(s, " ", " ")
end


function urlDecode(s)
  local s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
  return s
end

function 检查链接(url, needExecute)
  if url:find("https://www.zhihu.com/") then
    -- 首先匹配包含question的回答页面 防止包含question的answers页面被错误匹配question
    local qId, aId = url:match("zhihu.com/question/(%d+)/answers/(%d+)")
    if qId and aId then
      if needExecute then return true end
      return newActivity("answer", {qId, aId})
    end

    -- 回答页面 (answer/xxx)
    local answerId = url:match("zhihu.com/answer/(%d+)")
    if answerId then
      if needExecute then return true end
      return newActivity("answer", {"null", answerId})
    end

    -- 问题页面
    local questionId = url:match("zhihu.com/question/(%d+)")
    if questionId then
      if needExecute then return true end
      return newActivity("question", {questionId})
    end

    -- 专栏文章
    local columnId = url:match("zhuanlan.zhihu.com/p/(%d+)")
    if columnId then
      if needExecute then return true end
      return newActivity("column", {columnId})
    end

    -- appview 专栏文章
    columnId = url:match("zhihu.com/appview/p/(%d+)")
    if columnId then
      if needExecute then return true end
      return newActivity("column", {columnId})
    end

    -- 话题
    local topicId = url:match("zhihu.com/topics/(%d+)")
    if topicId then
      if needExecute then return true end
      return newActivity("topic", {topicId})
    end

    -- 话题
    topicId = url:match("zhihu.com/topic/(%d+)")
    if topicId then
      if needExecute then return true end
      return newActivity("topic", {topicId})
    end

    -- 想法
    local pinId = url:match("zhihu.com/pin/(%d+)")
    if pinId then
      if needExecute then return true end
      return newActivity("column", {pinId, "想法"})
    end

    -- 视频
    local videoId = url:match("zhihu.com/video/(%d+)")
    if videoId then
      if needExecute then return true end
      local head = {
        ["cookie"] = CookieManager.getInstance().getCookie("https://www.zhihu.com/");
      }
      zHttp.get("https://lens.zhihu.com/api/v4/videos/" .. videoId, head, function(code, content)
        if code == 200 then
          local v = luajson.decode(content)
          local videoLink = nil
          xpcall(function()
            videoLink = v.playlist.SD.play_url
            end, function()
            xpcall(function()
              videoLink = v.playlist.LD.play_url
              end, function()
              videoLink = v.playlist.HD.play_url
            end)
          end)
          if videoLink then
            newActivity("browser", {videoLink})
           else
            Toast.makeText(activity, "无法获取视频链接", Toast.LENGTH_SHORT).show()
          end
         elseif code == 401 then
          Toast.makeText(activity, "请登录后查看视频", Toast.LENGTH_SHORT).show()
         else
          Toast.makeText(activity, "获取视频信息失败: " .. code, Toast.LENGTH_SHORT).show()
        end
      end)
      return
    end

    -- 知乎视频
    videoId = url:match("zhihu.com/zvideo/(%d+)")
    if videoId then
      if needExecute then return true end
      return newActivity("column", {videoId, "视频"})
    end

    -- 用户页面
    local userType, userName = url:match("zhihu.com/(people|org)/([^/]+)")
    if userType and userName then
      if needExecute then return true end
      return newActivity("people", {userName})
    end

    -- 圆桌
    local roundTableId = url:match("zhihu.com/roundtable/(%d+)")
    if roundTableId then
      if needExecute then return true end
      return newActivity("column", {roundTableId, "圆桌"})
    end

    -- 专题
    local specialId = url:match("zhihu.com/special/(%d+)")
    if specialId then
      if needExecute then return true end
      return newActivity("column", {specialId, "专题"})
    end

    -- 专栏
    local columnId2 = url:match("zhihu.com/column/(%d+)")
    if columnId2 then
      if needExecute then return true end
      return newActivity("people_column", {columnId2})
    end

    -- 直播
    local dramaId = url:match("zhihu.com/theater.*drama_id=(%d+)")
    if dramaId then
      if needExecute then return true end
      return newActivity("column", {dramaId, "直播"})
    end

    -- 登录页
    if url:find("zhihu.com/signin") then
      if needExecute then return true end
      return newActivity("login")
    end

    -- OIA 页面
    if url:find("zhihu.com/oia/") then
      if needExecute then return true end
      local cleanUrl = url:gsub("oia/", "")
      return 检查意图(cleanUrl)
    end

    -- QQ 登录跳转
    if url:find("https://ssl.ptlogin2.qq.com/jump") then -- 原字符串末尾也有空格，需确认是否正确
      if needExecute then return true end
      activity.finish()
      return newActivity("login", {url})
    end

    -- 评论列表
    local commentType = url:match("zhihu.com/comment/list/(.-)/")
    if commentType then
      if needExecute then return true end
      return newActivity("comment", {url:getUrlArg(commentType .. "/"), commentType .. "s"})
    end

    -- zhihu:// 协议
   elseif url:find("zhihu://") then
    return 检查意图(url, needExecute)
   else
    -- 其他 zhihu.com 页面
    if needExecute then return false end
    return newActivity("browser", {url})
  end
end

function 检查意图(url, needExecute)
  if url and url:find("zhihu://") then
    -- 回答
    local id = url:match("answers/(%d+)")
    if id then
      if needExecute then return true end
      return newActivity("answer", {"null", id})
    end

    -- 回答
    id = url:match("answer/(%d+)")
    if id then
      if needExecute then return true end
      return newActivity("answer", {"null", id})
    end

    -- 问题
    local questionId = url:match("questions/(%d+)")
    if questionId then
      if needExecute then return true end
      return newActivity("question", {questionId})
    end

    -- 问题
    questionId = url:match("question/(%d+)")
    if questionId then
      if needExecute then return true end
      return newActivity("question", {questionId})
    end

    -- 话题
    local topicId = url:match("topic/(%d+)")
    if topicId then
      if needExecute then return true end
      return newActivity("topic", {topicId})
    end

    -- 用户
    local userName = url:match("people/(.-)/")
    if userName then
      if needExecute then return true end
      return newActivity("people", {userName})
    end

    -- 专栏
    local columnId = url:match("columns/(%d+)")
    if columnId then
      if needExecute then return true end
      return newActivity("people_column", {columnId})
    end

    -- 文章
    local articleId = url:match("articles/(%d+)")
    if articleId then
      if needExecute then return true end
      return newActivity("column", {articleId})
    end

    -- 文章
    articleId = url:match("article/(%d+)")
    if articleId then
      if needExecute then return true end
      return newActivity("column", {articleId})
    end

    -- 想法
    local pinId = url:match("pin/(%d+)")
    if pinId then
      if needExecute then return true end
      if string.find(url, "action") then
        return newActivity("people_list", {"获取点赞列表", pinId})
       else
        return newActivity("column", {pinId, "想法"})
      end
    end

    -- 知乎视频
    local videoId = url:match("zvideo/(%d+)")
    if videoId then
      if needExecute then return true end
      return newActivity("column", {videoId, "视频"})
    end

    -- 圆桌
    local roundTableId = url:match("roundtable/(%d+)")
    if roundTableId then
      if needExecute then return true end
      return newActivity("column", {roundTableId, "圆桌"})
    end

    -- 专题
    local specialId = url:match("special/(%d+)")
    if specialId then
      if needExecute then return true end
      return newActivity("column", {specialId, "专题"})
    end

    -- 直播
    local dramaId = url:match("theater.*drama_id=(%d+)")
    if dramaId then
      if needExecute then return true end
      return newActivity("column", {dramaId, "直播"})
    end

    if needExecute then return false end
    return Toast.makeText(activity, "暂不支持的知乎意图" .. url, Toast.LENGTH_SHORT).show()
   elseif url and (url:find("http://") or url:find("https://")) and url:find("zhihu.com") then
    return 检查链接(url, needExecute)
  end
end