--想法 专栏 视频项目的获取类
--author huajiqaq
--time 2023-9-1
--self:对象本身


local base={}

function base:new(id,type)--类的new方法
  local child=table.clone(self)
  child.id=id
  child.type=type
  child:getinfo()
  return child
end

function base:setinfo(key,value)
  if value then
    value=value..self.id
    self[key]=value
  end
  return self
end

function base:getinfo()
  local type1=self.type
  local geturl,weburl,type2,fxurl
  switch type1
   case "文章"
    geturl="https://www.zhihu.com/api/v4/articles/"
    weburl="https://www.zhihu.com/appview/p/"
    type2="article"
    fxurl="https://zhuanlan.zhihu.com/p/"
   case "想法"
    geturl="https://www.zhihu.com/api/v4/pins/"
    weburl="https://www.zhihu.com/appview/pin/"
    type2="pin"
    fxurl="https://www.zhihu.com/appview/pin/"
   case "视频"
    geturl="https://www.zhihu.com/api/v4/zvideos/"
    weburl="https://www.zhihu.com/zvideo/"
    type2="zvideo"
    fxurl="https://www.zhihu.com/zvideo/"
   case "直播"
    geturl="https://api.zhihu.com/drama/theaters/"
    weburl="https://www.zhihu.com/theater/"
    type2="drama"
    fxurl=weburl
   case "圆桌"
    weburl="https://www.zhihu.com/roundtable/"
    fxurl="https://www.zhihu.com/roundtable/"
   case "专题"
    weburl="https://www.zhihu.com/special/"
    fxurl="https://www.zhihu.com/special/"
  end

  self.urltype=type2
  self:setinfo("geturl",geturl)
  :setinfo("weburl",weburl)
  :setinfo("fxurl",fxurl)

  return self
end

function base:getData(cb)
  local url = self.geturl
  if not url then
    if self.weburl then
      return cb(true)
    end
    return
  end

  zHttp.get(url, head, function(code, content)
    if code ~= 200 then
      return cb(false, code)
    end

    local data = luajson.decode(content)
    local datatype = self.type

    switch datatype
     case "文章", "想法"
      local title = data.title
      if datatype == "想法" then
        title = 获取想法标题(data.content[1].title or "")
      end
      if title == "" then
        title = "一个" .. datatype
      end
      data.title = title
      local username = data.author.name
      data.savepath = 内置存储文件("Download/" .. title .. "/" .. username)
    end

    cb(data)
  end)
end


return base