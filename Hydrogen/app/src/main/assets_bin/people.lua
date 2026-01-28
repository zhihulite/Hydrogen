require "import"
import "android.widget.*"
import "android.view.*"
import "mods.muk"

people_id, pre_data = ...

-- 如果有传入预置数据，第一时间渲染 UI
if type(pre_data) == "table" then
  taskUI(function()
    if _title then _title.text = pre_data.name end
    if people_name then people_name.text = pre_data.name end
    if people_sign then people_sign.text = (pre_data.headline ~= "" and pre_data.headline or "加载中...") end
    if 图像 then loadglide(图像, pre_data.avatar_url or pre_data.avatar_url_template) end
    if _voteup_count and pre_data.voteup_count then _voteup_count.Text = numtostr(pre_data.voteup_count) .. "个获赞" end
    if _fans and pre_data.follower_count then _fans.Text = numtostr(pre_data.follower_count) .. "个粉丝" end
    if _follow and pre_data.following_count then _follow.Text = numtostr(pre_data.following_count) .. "个关注" end
    if card then card.Visibility = 0 end
  end)
end

import "com.google.android.material.tabs.TabLayout"

设置视图("layout/people")
设置toolbar(toolbar)
edgeToedge(nil,nil,function() local layoutParams = topbar.LayoutParams;
  layoutParams.setMargins(layoutParams.leftMargin, 状态栏高度, layoutParams.rightMargin,layoutParams.bottomMargin);
  topbar.setLayoutParams(layoutParams); end)

初始化历史记录数据()
people_itemc=获取适配器项目布局("people/people")


if not(getLogin()) then
  提示("你可以登录使用更多过滤标签")
end


local base_people = require "model.people":new(people_id)

-- 并行发起用户信息和 Tab 列表请求
taskUI(function()
  base_people:getData(function(data, self)
    if not data then
      if _title then _title.Text = "获取用户信息失败" end
      if card then card.Visibility = 8 end
      return
    end
    
    local 名字 = data.name
    大头像 = data.avatar_url_template
    local 签名 = data.headline ~= "" and data.headline or "无签名"
    用户id = data.id
    people_id = data.id

    if _title then _title.text = 名字 end
    if people_name then people_name.text = 名字 end
    if people_sign then people_sign.text = 签名 end
    if 图像 then loadglide(图像, 大头像) end
    
    local 获赞数 = numtostr(data.voteup_count)
    local 粉丝数 = numtostr(data.follower_count)
    local 关注数 = numtostr(data.following_count)

    if _voteup_count then _voteup_count.Text = tostring(获赞数) .. "个获赞" end
    if _fans then _fans.Text = tostring(粉丝数) .. "个粉丝" end
    if _follow then _follow.Text = tostring(关注数) .. "个关注" end
    
    if 用户id ~= activity.getSharedData("idx") and people_o then
      people_o.setVisibility(View.VISIBLE)
    end

    保存历史记录(用户id, 名字, 签名, "用户")
    -- 非核心 UI 逻辑延迟处理
    taskUI(100, function()
      
      if fans then
        function fans.onClick()
          if not getLogin() then return 提示("你需要登录使用本功能") end
          newActivity("people_list", {名字 .. "的粉丝列表", 用户id})
        end
      end
      
      if follow then
        function follow.onClick()
          if not getLogin() then return 提示("你需要登录使用本功能") end
          newActivity("people_list", {名字 .. "的关注列表", 用户id})
        end
      end

      if data.is_following and following then
        关注数量 = {[1] = 粉丝数, [2] = numtostr(data.follower_count - 1)}
        following.Text = "取关"
      elseif following then
        关注数量 = {[1] = numtostr(data.follower_count + 1), [2] = 粉丝数}
        following.Text = "关注"
      end

      if 图像 then
        图像.onClick = function()
          this.setSharedData("imagedata", luajson.encode({["0"] = 大头像, ["1"] = 1}))
          activity.newActivity("image")
        end
      end

      pop = {
        tittle = "用户",
        list = {
          { src = 图标("add"), text = data.is_blocking and "取消拉黑" or "拉黑", onClick = function(text)
              if not getLogin() then return 提示("请登录后使用本功能") end
              AlertDialog.Builder(this)
              .setTitle("提示")
              .setMessage("屏蔽过后如果想查看屏蔽的所有用户 可以在软件内主页右划 点击消息 选择设置 之后打开屏蔽即可管理屏蔽 你也可以选择管理屏蔽用户 但是这样没有选择设置可设置的多 如果只想查看屏蔽的用户 推荐选择屏蔽用户管理")
              .setPositiveButton("我知道了", {onClick = function()
                  local mview = pop.list[1]
                  if mview.text == "拉黑" then
                    zHttp.post("https://api.zhihu.com/settings/blocked_users", "people_id=" .. people_id, apphead, function(code)
                      if code == 200 or code == 201 then
                        mview.src = 图标("close"); mview.text = "取消拉黑"
                        提示("已拉黑"); a = MUKPopu(pop)
                      end
                    end)
                  else
                    zHttp.delete("https://api.zhihu.com/settings/blocked_users/" .. people_id, posthead, function(code)
                      if code == 200 then
                        mview.src = 图标("add"); mview.text = "拉黑"
                        提示("已取消拉黑"); a = MUKPopu(pop)
                      end
                    end)
                  end
              end}).setNegativeButton("取消", nil).show()
          end },
          { src = 图标("add"), text = "举报", onClick = function()
              if not getLogin() then return 提示("请登录后使用本功能") end
              newActivity("browser", {"https://www.zhihu.com/report?id=" .. people_id .. "&type=member&source=android&ab_signature=", "举报"})
          end },
          { src = 图标("search"), text = "在当前内容中搜索", onClick = function()
              AlertDialog.Builder(this).setTitle("请输入")
              .setView(loadlayout({ LinearLayout, orientation="vertical", Focusable=true, FocusableInTouchMode=true, { EditText, id="edit", hint="输入", layout_margin="10dp", layout_width="match_parent" } }))
              .setPositiveButton("确定", {onClick = function() newActivity("search_result", {edit.text, "people", 用户id}) end})
              .setNegativeButton("取消", nil).show()
          end },
          { src = 图标("share"), text = "分享", onClick = function()
              分享文本(string.format("【用户】%s：%s", 名字, "https://www.zhihu.com/people/" .. 用户id))
            end,
            onLongClick = function()
              分享文本(string.format("【用户】%s：%s", 名字, "https://www.zhihu.com/people/" .. 用户id), true)
          end },
        }
      }
      a = MUKPopu(pop)
    end)
    
    base_people:getTabs(function(self, tabname, urlinfo, answerindex)
      _G["urlinfo"] = urlinfo
      people_pagetool = self:initpage(people_vpg, PeotabLayout)
      people_pagetool:setUrls(urlinfo)
      :addPage(2, tabname)
      :createfunc()
      :setOnTabListener(function(_, pos)
        _G["pos"] = pos
        if _sortvis then _sortvis.setVisibility(pos == answerindex and 0 or 8) end
      end)
      :refer(nil, nil, true)
    end)
  end)
end)



function 加载全部()
  base_people:next(function(r,a)
    if r==false and base_people.is_end==false then
      提示("获取个人动态列表出错 "..a or "")
     elseif base_people.is_end==false then
      add=true
    end
  end)
end

function _sort.onClick(view)
  local url=urlinfo[pos]
  pop=PopupMenu(activity,view)
  menu=pop.Menu
  menu.add("按时间排序").onMenuItemClick=function(a)
    if _sortt.text=="按时间排序" then
      return
    end
    _sortt.text="按时间排序"
    local url=replace_or_add_order_by(url,"created")
    people_pagetool
    :setUrlItem(url,pos)
    :clearItem(pos)
    :refer(pos,true)
  end
  menu.add("按赞数排序").onMenuItemClick=function(a)
    if _sortt.text=="按赞数排序" then
      return
    end
    _sortt.text="按赞数排序"
    local url=replace_or_add_order_by(url,"votenum")
    people_pagetool
    :setUrlItem(url,pos)
    :clearItem(pos)
    :refer(pos,true)
  end
  pop.show()--显示
end


波纹({fh,_more},"圆主题")

taskUI(function()
  a=MUKPopu({
    tittle="用户",
    list={
    }
  })
end)

function onActivityResult(a,b,c)
  if b==100 then
    刷新(true)
  end
end