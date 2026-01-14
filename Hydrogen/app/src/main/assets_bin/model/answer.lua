--回答页相关数据类
--author huajiqaq
--time 2023-7-09
--self:对象本身
--TODO 针对pageinfo的获取是即时性的 也就代表如果pageinfo再次多加一个内容 可能会导致内容错位 一个解决方法是使用table本地存储 不过出现几率极低


local base={--表初始化
  getid=nil,
  pageinfo={},

}


function base:new(id)--类的new方法
  local child=table.clone(self)
  --这里必须tonumber 因为不能保证传入的是string
  child.getid=tonumber(id) --这里的id是回答页id
  return child
end


function base:getinfo(id,cb)
  local include='?include=question.answer_count%2Cquestion.visit_count%2Cqustion.comment_count'
  local url="https://www.zhihu.com/api/v4/answers/"..id..include
  zHttp.get(url,apphead
  ,function(a,b)
    if a==200 then
      cb(luajson.decode(b).question)
     elseif a==404 then
    end
  end)
end


function base:getAnswer(id,cb)
  local include='?include=author%2Ccontent%2Cvoteup_count%2Ccomment_count%2Cfavlists_count%2Cthanks_count%2Cpagination_info%2Cad_track_url%2Ccontent%2Ccreated_time%2Cupdated_time%2Creshipment_settings%2Cmark_infos%2Ccopyright_applications_count%2Cis_collapsed%2Ccollapse_reason%2Cannotation_detail%2Cis_normal%2Ccollaboration_status%2Creview_info%2Creward_info%2Crelationship.voting%2Crelationship.is_author%3Bsuggest_edit.unnormal_details%3Bcommercial_info%2Crelevant_info%2Csearch_words%2Cpagination_info%2Cfavlists_count%2Ccomment_count%2Cexcerpt%2Cattachment'
  local url="https://www.zhihu.com/api/v4/answers/"..id..include
  zHttp.get(url,head,function(a,b)
    if a==200 then
      cb(luajson.decode(b))
     elseif a==404 then
      if self.pageinfo[self.getid] then
        AlertDialog.Builder(this)
        .setTitle("提示")
        .setMessage("发生错误 不存在该回答 已尝试跳转下个回答 如还无法访问 可点击上方标题进入问题详情页")
        .setCancelable(false)
        .setPositiveButton("我知道了",nil)
        .show()
        cb(false)
       else
        AlertDialog.Builder(this)
        .setTitle("提示")
        .setMessage("发生错误 不存在该回答 可点击上方标题进入问题详情页")
        .setCancelable(false)
        .setPositiveButton("我知道了",nil)
        .show()
      end
    end
  end)
end

function base:updateLR()
  local mypageinfo=self.pageinfo
  if mypageinfo[self.getid] then
    local prev_ids=mypageinfo[self.getid].prev_ids
    local next_ids=mypageinfo[self.getid].next_ids
    --即使滑动到已经加载过的页面再次判断是否在最左or最右端
    self.isleft=#prev_ids==0
    self.isright=#next_ids==0
  end
end

function base:getNextId(z)
  local getid=self.getid..""
  local pageinfo=self.pageinfo

  if pageinfo[getid] then
    if z then
      local prev_ids=pageinfo[getid].prev_ids
      getid=prev_ids[#prev_ids]
     else
      local next_ids=pageinfo[getid].next_ids
      getid=next_ids[1]
    end
  end
  return getid
end

function base:getOneData(cb,z) --获取一条数据
  local getid=self.getid..""
  local pageinfo=self.pageinfo

  if pageinfo[getid] then
    if z then
      local prev_ids=pageinfo[getid].prev_ids
      getid=prev_ids[#prev_ids]
     else
      local next_ids=pageinfo[getid].next_ids
      getid=next_ids[1]
    end
  end
  self:getAnswer((getid),function(myz)
    if myz==false then
      if z then
        table.remove(pageinfo[self.getid].prev_ids)
       else
        table.remove(pageinfo[self.getid].next_ids,1)
      end
      return self:getOneData(cb,z)
    end

    --更新getid
    self.getid=getid..""

    local mypageinfo=myz.pagination_info
    if mypageinfo then
      local prev_ids=mypageinfo.prev_answer_ids
      local next_ids=mypageinfo.next_answer_ids
      pageinfo[self.getid]={
        prev_ids=prev_ids,
        next_ids=next_ids
      }
      --在请求后再次判断是否在最左or最右端
      self.isleft=#mypageinfo.prev_answer_ids==0
      self.isright=#mypageinfo.next_answer_ids==0
    end
    cb(myz)
  end)

  return self
end

return base