zHttp = {}

function zHttp.setcallback(code,content,raw,headers,url,head,callback,func,data)
  if code==403 then
    local _ = pcall(function()
      decoded_content=luajson.decode(content)
    end)
    if decoded_content.error and decoded_content.error.message and decoded_content.error.redirect then
      if not mytip_dia or mytip_dia.isShowing()~=true then
        canload=false
        mytip_dia=AlertDialog.Builder(this)
        .setTitle("提示")
        .setMessage(decoded_content.error.message)
        .setPositiveButton("立即跳转",{onClick = function()
            newActivity("browser",{decoded_content.error.redirect})
            提示("已跳转 成功后请自行退出")
        end})
        .show()
        end
      end
     elseif decoded_content.error and decoded_content.error.message then
      提示(decoded_content.error.message)
    end
   elseif code==401 then
    if getLogin() then
      if mytip_dia==nil or mytip_dia.isShowing()~=true then
        mytip_dia=AlertDialog.Builder(this)
        .setTitle("提示")
        .setMessage("登录状态已失效 已自动帮你清除失效的登录状态 你可以点击下方我知道了来跳转登录")
        .setCancelable(false)
        .setPositiveButton("我知道了",{onClick=function()
            清除所有cookie()
            activity.setSharedData("signdata",nil)
            activity.setSharedData("idx",nil)
            activity.setSharedData("udid",nil)
            activity.newActivity("login")
        end})
        .show()
      end
    end
   elseif code==400 then
    local _ = pcall(function()
      decoded_content=luajson.decode(content)
    end)
    if decoded_content.error and decoded_content.error.message then
      提示("知乎提示："..decoded_content.error.message)
    end
   elseif headers and headers.Location and headers.Location[0] then
    zHttp.request(headers.Location[0],func,data,head,callback)
    return
  end
  callback(code,content)
end

function zHttp.request(url,method,data,head,callback)
  local method=string.lower(method)
  if method=="get" then
    zHttp.get(url,head,callback)
   elseif method=="delete" then
    zHttp.delete(url,head,callback)
   elseif method=="post" then
    zHttp.post(url,data,head,callback)
   elseif method=="put" then
    zHttp.put(url,data,head,callback)
  end
end

local zse96_encrypt=require "model.zse96_encrypt"

function zHttp.get(url,head,callback)
  if canload==false then return false end
  if url:find("https://www.zhihu.com") then
    url,head=zse96_encrypt(url)
  end
  Http.get(url,head,function(code,content,raw,headers)
    zHttp.setcallback(code,content,raw,headers,url,head,callback,"get")
  end)
end

function zHttp.delete(url,head,callback)
  if canload==false then return false end
  Http.delete(url,head,function(code,content,raw,headers)
    zHttp.setcallback(code,content,raw,headers,url,head,callback,"delete")
  end)
end


function zHttp.post(url,data,head,callback)
  if canload==false then return false end
  Http.post(url,data,head,function(code,content,raw,headers)
    zHttp.setcallback(code,content,raw,headers,url,head,callback,"post",data)
  end)
end

function zHttp.put(url,data,head,callback)
  if canload==false then return false end
  Http.put(url,data,head,function(code,content,raw,headers)
    zHttp.setcallback(code,content,raw,headers,url,head,callback,"put",data)
  end)
end