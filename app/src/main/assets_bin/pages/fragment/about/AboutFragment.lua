-- pages/fragment/about/AboutFragment.lua
-- 关于页面 Fragment

import "android.content.Intent"
import "android.net.Uri"
import "androidx.recyclerview.widget.LinearLayoutManager"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

local BaseFragment = require("pages.base.BaseFragment")
local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")

local AboutFragment = Extensions.Class(BaseFragment)
AboutFragment:chainUp("onDestroy")

local appInfo = {
  name = AppInfo.name,
  versionName = AppInfo.versionName,
  versio = AppInfo.version,
  message = "让每次点击都有意义",
}

local developers = {
  { name = "没想到一个名字", qq = 1906327347, message = "维护者之一" },
  { name = "dingyi", qq = 2187778735, message = "软件初期奠定" },
  { name = "ZL", qq = 3543515846, message = "引诱苦手" },
  { name = "orz12", avatar = "https://avatars.githubusercontent.com/u/17450420?v=4", message = "布局优化", url = "https://gitee.com/orz12" },
  { name = "0xdeadc0de", message = "提交PR 修复BUG", avatar = "https://avatars.githubusercontent.com/u/26507452?v=4", url = "https://github.com/1582421598" },
  { name = "NullCola", message = "绘制矢量图标", avatar = "https://cdn5.telesco.pe/file/dIqKSocvTeoZyC6H62pJklUCeE-CdACKaKdoOnYAh4NEqsN8j3eGPjfIapUf4g12wPfuR436kvf4FpgUd7RWb98pXDO-sIEVo3vjGSn1HpicBdLghGPA8Cojhq4kQ7MfAtYLB1DtNsGygXP2uiAUkY5tMhpK6oTLYM4MhBlQqs0LfuZf3mlShf1Gc4gPCk1AcZ9AOZMVqq9UXy_lObNlfvjvWg32L5Oe5SXOd89xdeoIYZh6CIF3WxWX63AZoybG-Uw3UclcmYNit1FDyc3GHIWVFvlY3Fx8qiFUDH18GIW-6dTDDhPlVhMBRUcjDD-U7Qrlw3FT-H2aSjsouzfhBA.jpg", url = "https://t.me/NullCola" },
}

local agreements = {
  { title = "用户协议", name = "user_agreement" },
  { title = "隐私政策", name = "privacy_policy" },
}

local moreItems = {
  { title = "GitHub", url = "https://github.com/zhihulite/Hydrogen" },
  { title = "更新日志", url = "https://zhihulite.github.io/update.html" },
  { title = "反馈", route = "feedback" },
}

function AboutFragment:ctor()
  self.adapter = nil
  self.items = {}
end

function AboutFragment:onCreate(params)
  self:buildAboutData()
end

function AboutFragment:initLayout()
  self.root_view = loadlayout(Layouts.pages.about.main, self.views)
end

function AboutFragment:initViews()
  local views = self.views

  self:setupEdgeToEdge({
    top = { self.views.main_container },
    bottom = { self.views.recycler_view },
  })

  Helpers.UI.setupToolbar(views.toolbar, {
    title = "关于"
  })

  self:initListView()
end

function AboutFragment:buildAboutData()
  self.items = {}

  table.insert(self.items, { type = "header" })

  table.insert(self.items, { type = "title", title = "关于软件" })
  table.insert(self.items, {
    type = "item",
    title = "当前版本",
    summary = string.format("%s (%s)", appInfo.versionName, tostring(AppInfo.version)),
    route = "check_update",
    arrow = true,
  })

  if #agreements > 0 then
    table.insert(self.items, { type = "title", title = "协议" })
    for _, agreement in ipairs(agreements) do
      table.insert(self.items, {
        type = "item",
        title = agreement.title,
        route = "agreement",
        data = agreement,
        arrow = true,
      })
    end
  end

  table.insert(self.items, { type = "title", title = "开发信息" })

  for _, dev in ipairs(developers) do
    local route = dev.qq and ("qq://" .. dev.qq) or dev.url
    table.insert(self.items, {
      type = "developer",
      title = "@" .. dev.name,
      summary = dev.message,
      avatar = dev.avatar or self:getQQAvatarUrl(dev.qq),
      route = route,
    })
  end

  table.insert(self.items, {
    type = "item",
    title = "开源许可",
    route = "open_source",
    arrow = true,
  })

  if #moreItems > 0 then
    table.insert(self.items, { type = "title", title = "更多内容" })
    for _, item in ipairs(moreItems) do
      table.insert(self.items, {
        type = "item",
        title = item.title,
        route = item.route or item.url,
        arrow = true,
      })
    end
  end
end

function AboutFragment:getQQAvatarUrl(qq, size)
  if qq then
    size = size or 640
    return string.format("http://q.qlogo.cn/headimg_dl?spec=%d&img_type=jpg&dst_uin=%s", size, qq)
  end
  return nil
end

function AboutFragment:initListView()
  local views = self.views

  self.adapter = SimpleRecyclerAdapter.new({
    items = self.items,
    getItemViewType = function(position, item)
      if item.type == "header" then return 0
       elseif item.type == "title" then return 1
       elseif item.type == "developer" then return 2
       else return 3
      end
    end,
    onCreateView = function(viewType)
      if viewType == 0 then return SimpleRecyclerAdapter.inflate(Layouts.pages.about.items.header)
       elseif viewType == 1 then return SimpleRecyclerAdapter.inflate(Layouts.pages.about.items.title)
       elseif viewType == 2 then return SimpleRecyclerAdapter.inflate(Layouts.pages.about.items.developer)
       else return SimpleRecyclerAdapter.inflate(Layouts.pages.about.items.item)
      end
    end,
    onBind = function(views, item, position, holder)
      if item.title then
        views.title.text = item.title or ""
      end

      if item.summary then
        views.summary.text = item.summary
        views.summary.visibility = View.VISIBLE
       elseif views.summary then
        views.summary.visibility = View.GONE
      end

      if item.type == "item" then
        views.arrow.visibility = item.arrow == false and View.GONE or View.VISIBLE
       elseif views.arrow then
        views.arrow.visibility = View.GONE
      end

      if item.type == "developer" then
        if item.route and (item.route:find("^http") or item.route:find("^qq://")) then
          views.external_icon.visibility = View.VISIBLE
         else
          views.external_icon.visibility = View.GONE
        end
      end

      if item.avatar then
        Helpers.Image.load(views.avatar, item.avatar, { circle = true })
      end

      if views.card then
        views.card.onClick = function()
          self:onItemClick(item)
        end
      end
    end
  })

  views.recycler_view.adapter = self.adapter
  views.recycler_view.layoutManager = LinearLayoutManager(activity)
end

function AboutFragment:onItemClick(item)
  if not item.route then return end

  if item.route == "check_update" then
    self:checkUpdate()
   elseif item.route == "agreement" then
    self:showAgreement(item.data)
   elseif item.route == "open_source" then
    Router.go("open_source")
   elseif item.route == "feedback" then
    self:showFeedbackDialog()
   elseif item.route:find("^qq://") then
    -- 打开 QQ 对应对话
    local qq = item.route:gsub("qq://", "")
    self:openQQChat(qq)
   elseif item.route:find("^http") then
    local intent = Intent(Intent.ACTION_VIEW, Uri.parse(item.route))
    activity.startActivity(intent)
   else
    Router.go(item.route)
  end
end

function AboutFragment:openQQChat(qq)
  local url = string.format("mqqapi://card/show_pslcard?src_type=internal&version=1&uin=%s&card_type=person&source=sharecard", qq)
  local intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
  local ok, err = pcall(function()
    activity.startActivity(intent)
  end)
  if not ok then
    -- 没装 QQ 就打开网页版
    local webUrl = string.format("https://qm.qq.com/cgi-bin/qm/qr?k=%s", qq)
    local webIntent = Intent(Intent.ACTION_VIEW, Uri.parse(webUrl))
    pcall(function() activity.startActivity(webIntent) end)
  end
end

function AboutFragment:checkUpdate()
  AppInfo.showUpdateDialog(true)
end

function AboutFragment:showAgreement(agreement)
  local path = ROOT .. "/agreements/" .. agreement.name .. ".html"
  if Extensions.File.exists(path) then
    local content = Extensions.File.read(path)
    self:showHtmlDialog(agreement.title, content)
   else
    tip("协议文件不存在")
  end
end

function AboutFragment:showHtmlDialog(title, content)
  local views = {}
  MaterialAlertDialogBuilder(activity)
  .setTitle(title)
  .setView(loadlayout(Layouts.dialogs.html_dialog, views))
  .setPositiveButton("关闭", nil)
  .show()
  views.content.text = fromHtml(content)
end

function AboutFragment:showFeedbackDialog()
  Router.go("feedback")
end

function AboutFragment:onDestroy()
  if self.adapter then
    self.adapter = nil
  end
end

return AboutFragment