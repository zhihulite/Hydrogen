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
  -- 拆分 base 和 query
  local base, query = url:match("([^%?]+)%??(.*)")
  if not base then return end

  if base:find("https://www.zhihu.com/") then
    -- 先匹配最具体的路径 避免误判
    local qId, aId = base:match("zhihu.com/question/(%d+)/answer/(%d+)")
    if qId and aId then
      if needExecute then return true end
      return newActivity("answer", {qId, aId})
    end

    local answerId = base:match("zhihu.com/answer/(%d+)")
    if answerId then
      if needExecute then return true end
      return newActivity("answer", {"null", answerId})
    end

    local questionId = base:match("zhihu.com/question/(%d+)")
    if questionId then
      if needExecute then return true end
      return newActivity("question", {questionId})
    end

    local articleId = base:match("zhuanlan.zhihu.com/p/(%d+)") or base:match("zhihu.com/appview/p/(%d+)")
    if articleId then
      if needExecute then return true end
      return newActivity("column", {articleId})
    end

    local topicId = base:match("zhihu.com/topics/(%d+)") or base:match("zhihu.com/topic/(%d+)")
    if topicId then
      if needExecute then return true end
      return newActivity("topic", {topicId})
    end

    local pinId = base:match("zhihu.com/pin/(%d+)")
    if pinId then
      if needExecute then return true end
      return newActivity("column", {pinId, "想法"})
    end

    local videoId = base:match("zhihu.com/video/(%d+)")
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

    videoId = base:match("zhihu.com/zvideo/(%d+)")
    if videoId then
      if needExecute then return true end
      return newActivity("column", {videoId, "视频"})
    end

    local userName = base:match("zhihu.com/people/([^/]+)") or base:match("zhihu.com/org/([^/]+)")
    if userName then
      if needExecute then return true end
      return newActivity("people", {userName})
    end

    local roundTableId = base:match("zhihu.com/roundtable/(%d+)")
    if roundTableId then
      if needExecute then return true end
      return newActivity("column", {roundTableId, "圆桌"})
    end

    local specialId = base:match("zhihu.com/special/(%d+)")
    if specialId then
      if needExecute then return true end
      return newActivity("column", {specialId, "专题"})
    end

    local columnId = base:match("zhihu.com/column/(%d+)")
    if columnId then
      if needExecute then return true end
      return newActivity("people_column", {columnId})
    end

    if base:find("zhihu.com/theater") then
      local dramaId = query:match("drama_id=(%d+)")
      if dramaId then
        if needExecute then return true end
        return newActivity("column", {dramaId, "直播"})
      end
    end

    if base:find("zhihu.com/signin") then
      if needExecute then return true end
      return newActivity("login")
    end

    if base:find("zhihu.com/oia/") then
      if needExecute then return true end
      local cleanUrl = base:gsub("oia/", "")
      return 检查意图(cleanUrl)
    end

    if base:find("https://ssl.ptlogin2.qq.com/jump") then
      if needExecute then return true end
      activity.finish()
      return newActivity("login", {url})
    end

    local commentType, id = base:match("zhihu.com/comment/list/([^/]+)/(%d+)$")
    if commentType and id then
      if needExecute then return true end
      return newActivity("comment", {id, commentType .. "s"})
    end

   elseif base:find("zhihu://") then
    return 检查意图(url, needExecute)
   else
    if needExecute then return false end
    return newActivity("browser", {url})
  end
end


function 检查意图(url, needExecute)
  local base, query = url:match("([^%?]+)%??(.*)")
  if not base then return end

  if base:find("zhihu://") then
    local id = base:match("answers/(%d+)") or base:match("answer/(%d+)")
    if id then
      if needExecute then return true end
      return newActivity("answer", {"null", id})
    end

    local questionId = base:match("questions/(%d+)") or base:match("question/(%d+)")
    if questionId then
      if needExecute then return true end
      return newActivity("question", {questionId})
    end

    local topicId = base:match("topic/(%d+)")
    if topicId then
      if needExecute then return true end
      return newActivity("topic", {topicId})
    end

    local userName = base:match("people/([^/]+)") or base:match("org/([^/]+)")
    if userName then
      if needExecute then return true end
      return newActivity("people", {userName})
    end

    local columnId = base:match("columns/(%d+)")
    if columnId then
      if needExecute then return true end
      return newActivity("people_column", {columnId})
    end

    local articleId = base:match("articles/(%d+)") or base:match("article/(%d+)")
    if articleId then
      if needExecute then return true end
      return newActivity("column", {articleId})
    end

    local pinId = base:match("pin/(%d+)")
    if pinId then
      if needExecute then return true end
      if query:find("action") then
        return newActivity("people_list", {"获取点赞列表", pinId})
       else
        return newActivity("column", {pinId, "想法"})
      end
    end

    local videoId = base:match("zvideo/(%d+)")
    if videoId then
      if needExecute then return true end
      return newActivity("column", {videoId, "视频"})
    end

    local roundTableId = base:match("roundtable/(%d+)")
    if roundTableId then
      if needExecute then return true end
      return newActivity("column", {roundTableId, "圆桌"})
    end

    local specialId = base:match("special/(%d+)")
    if specialId then
      if needExecute then return true end
      return newActivity("column", {specialId, "专题"})
    end

    if base:find("theater") then
      local dramaId = query:match("drama_id=(%d+)")
      if dramaId then
        if needExecute then return true end
        return newActivity("column", {dramaId, "直播"})
      end
    end

    if needExecute then return false end
    return Toast.makeText(activity, "暂不支持的知乎意图" .. url, Toast.LENGTH_SHORT).show()

   elseif (base:find("http://") or base:find("https://")) and base:find("zhihu.com") then
    return 检查链接(url, needExecute)
  end
end