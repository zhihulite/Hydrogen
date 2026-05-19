-- pages/activity/welcome/WelcomeActivity.lua
-- 欢迎页面

import "androidx.core.widget.NestedScrollView"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.textview.MaterialTextView"
import "com.google.android.material.card.MaterialCardView"
import "com.google.android.material.checkbox.MaterialCheckBox"

local BaseActivity = require("pages.base.BaseActivity")

local WelcomeActivity = Extensions.Class(BaseActivity)
WelcomeActivity:chainUp("onDestroy")

local agreements = {
  { title = "用户协议", name = "user_agreement" },
  { title = "隐私政策", name = "privacy_policy" },
}

function WelcomeActivity:ctor()
  self.currentPage = 0 -- 从0开始
  self.maxPage = 1 + #agreements + 1 + 1 -- 开始页 + 协议页(2) + 权限页 + 完成页 = 5
  self.agreementStatus = {}
  self.currentContainer = nil

  self.permissions = {
    { title = "访问全部文件权限", summary = "用于调试软件" },
    { title = "相机权限", summary = "用于拍照和扫码功能" },
  }
end

function WelcomeActivity:initLayout()
  self.root_view = loadlayout(Layouts.pages.welcome.main, self.views)
end

function WelcomeActivity:initViews()
  local views = self.views
  views.nextButton.onClick = function() self:goToNext() end
  views.toolbar.setNavigationOnClickListener(function() self:goToPrev() end)

  local colors = AppTheme.getColors()
  views.toolbar.setTitleTextColor(colors.primary)
  views.toolbar.setNavigationIconTint(colors.primary)

  self.container = views.pageContainer
  self:showPage(0)

  -- 懒得做了，过于复杂
  self:setupEdgeToEdge({
    top = { self.views.main_container },
    bottom = { self.views.main_container },
  })
end

function WelcomeActivity:showPage(index)
  if self.currentContainer then
    self.container.removeView(self.currentContainer)
  end

  local page = self:createPage(index)
  if page then
    self.container.addView(page)
    self.currentContainer = page
  end

  self.currentPage = index
  self:updateUI()
end

function WelcomeActivity:createPage(index)
  if index == 0 then
    return self:createStartPage()
   elseif index <= #agreements then
    return self:createAgreementPage(agreements[index], index)
   elseif index == #agreements + 1 then
    return self:createPermissionPage()
   else
    return self:createCompletePage()
  end
end

function WelcomeActivity:goToNext()
  if not self:canGoToNext() then
    return
  end
  self:goToNextInternal()
end

function WelcomeActivity:goToNextInternal()
  if self.currentPage + 1 < self.maxPage then
    self:showPage(self.currentPage + 1)
   else
    self:finishWelcome()
  end
end

function WelcomeActivity:canGoToNext()
  if self.currentPage == 0 then
    return true -- 开始页直接可进
   elseif self.currentPage <= #agreements then
    return self.agreementStatus[self.currentPage] or false
   elseif self.currentPage == #agreements + 1 then
    return true -- 权限页仅提示，直接可进
  end
  return true
end

function WelcomeActivity:goToPrev()
  if self.currentPage > 0 then
    self:showPage(self.currentPage - 1)
  end
end

function WelcomeActivity:updateUI()
  local views = self.views

  self:updateToolbarTitle()

  if self.currentPage == self.maxPage - 1 then
    views.nextButton.setText("开始体验")
   else
    views.nextButton.setText("下一步")
  end

  views.nextButton.setEnabled(self:canGoToNext())

  if self.currentPage == 0 then
    views.toolbar.setNavigationIcon(nil)
   else
    views.toolbar.setNavigationIcon(Helpers.Static.materialDrawable("twotone_arrow_back", 24))
  end
end

function WelcomeActivity:updateToolbarTitle()
  local views = self.views

  if self.currentPage == 0 then
    views.toolbar.setTitle("欢迎")
   elseif self.currentPage <= #agreements then
    local agreement = agreements[self.currentPage]
    views.toolbar.setTitle("同意《" .. agreement.title .. "》")
   elseif self.currentPage == #agreements + 1 then
    views.toolbar.setTitle("权限说明")
   elseif self.currentPage == self.maxPage - 1 then
    views.toolbar.setTitle("准备就绪")
  end
end

function WelcomeActivity:createStartPage()
  local colors = AppTheme.getColors()

  local page = loadlayout({
    LinearLayoutCompat,
    layout_width = "fill",
    layout_height = "fill",
    gravity = "center",
    orientation = "vertical",
    padding = "32dp",
    {
      MaterialTextView,
      text = "✨",
      textSize = "48sp",
      gravity = "center",
      layout_marginBottom = "24dp",
    },
    {
      MaterialTextView,
      text = "欢迎使用 Hydrogen",
      textSize = AppTextStyle.headline.size,
      textColor = AppTextStyle.headline.color,
      gravity = "center",
      layout_marginBottom = "12dp",
      typeface = AppTextStyle.headline.font,
    },
    {
      MaterialTextView,
      text = "一个基于androlua+开发的知乎第三方app",
      textSize = AppTextStyle.body.size,
      textColor = AppTextStyle.body.color,
      gravity = "center",
      layout_marginBottom = "48dp",
      typeface = AppTextStyle.body.font,
    },
    {
      MaterialTextView,
      text = "接下来，让我们完成一些基础设置",
      textSize = AppTextStyle.body.size,
      textColor = AppTextStyle.body.color,
      gravity = "center",
      typeface = AppTextStyle.body.font,
    }
  })

  return page
end

function WelcomeActivity:createAgreementPage(agreement, index)
  local LinkMovementMethod = luajava.bindClass("android.text.method.LinkMovementMethod")
  local colors = AppTheme.getColors()

  local htmlContent = self:readAgreement(agreement.name) or agreement.title .. "内容加载中..."
  local spanned = fromHtml(htmlContent)

  local views = {}
  local page = loadlayout({
    LinearLayoutCompat,
    layout_width = "fill",
    layout_height = "fill",
    orientation = "vertical",
    {
      NestedScrollView,
      layout_width = "fill",
      layout_height = 0,
      layout_weight = 1,
      {
        MaterialTextView,
        id = "content",
        padding = "20dp",
        text = spanned,
        textSize = AppTextStyle.body.size,
        textColor = AppTextStyle.body.color,
        typeface = AppTextStyle.body.font,
        movementMethod = LinkMovementMethod.getInstance(),
      }
    },
    {
      LinearLayoutCompat,
      layout_width = "fill",
      layout_height = "wrap",
      orientation = "horizontal",
      gravity = "center_vertical",
      padding = "16dp",
      {
        MaterialCheckBox,
        id = "check",
        text = "我已阅读并同意《" .. agreement.title .. "》",
        layout_width = 0,
        layout_weight = 1,
        layout_marginEnd = "8dp",
        textSize = AppTextStyle.body.size,
        textColor = AppTextStyle.body.color,
        typeface = AppTextStyle.body.font,
      }
    }
  }, views)

  self.agreementStatus[index] = false
  views.check.setOnCheckedChangeListener({ onCheckedChanged = function(_, isChecked)
      self.agreementStatus[index] = isChecked
      self:updateUI()
  end })

  return page
end

function WelcomeActivity:createPermissionPage()
  local colors = AppTheme.getColors()
  local views = {}

  local page = loadlayout({
    LinearLayoutCompat,
    layout_width = "fill",
    layout_height = "fill",
    orientation = "vertical",
    padding = "16dp",
    {
      MaterialTextView,
      text = "以下权限仅在实际使用时申请，无需提前授权。",
      textSize = AppTextStyle.body.size,
      textColor = AppTextStyle.body.color,
      typeface = AppTextStyle.body.font,
      gravity = "center",
      layout_marginBottom = "24dp",
    },
    {
      NestedScrollView,
      layout_width = "fill",
      layout_height = 0,
      layout_weight = 1,
      {
        LinearLayoutCompat,
        id = "permContainer",
        layout_width = "fill",
        layout_height = "wrap",
        orientation = "vertical",
      }
    }
  }, views)

  for i, perm in ipairs(self.permissions) do
    local cardItem = loadlayout({
      LinearLayoutCompat,
      layout_width = "fill",
      layout_height = "wrap",
      {
        MaterialCardView,
        layout_width = "fill",
        layout_height = "wrap",
        layout_margin = "8dp",
        layout_marginLeft = "16dp",
        layout_marginRight = "16dp",
        {
          LinearLayoutCompat,
          layout_width = "fill",
          orientation = "horizontal",
          gravity = "center_vertical",
          padding = "16dp",
          {
            LinearLayoutCompat,
            layout_width = 0,
            layout_weight = 1,
            orientation = "vertical",
            {
              MaterialTextView,
              text = perm.title,
              textSize = AppTextStyle.title.size,
              textColor = AppTextStyle.title.color,
              typeface = AppTextStyle.title.font,
            },
            {
              MaterialTextView,
              text = perm.summary,
              textSize = AppTextStyle.caption.size,
              textColor = AppTextStyle.caption.color,
              typeface = AppTextStyle.caption.font,
              layout_marginTop = "4dp",
            }
          }
        }
      }
    })

    views.permContainer.addView(cardItem)
  end

  return page
end

function WelcomeActivity:createCompletePage()
  local colors = AppTheme.getColors()

  local page = loadlayout({
    LinearLayoutCompat,
    layout_width = "fill",
    layout_height = "fill",
    gravity = "center",
    orientation = "vertical",
    {
      MaterialTextView,
      text = "🎉",
      textSize = "48sp",
      gravity = "center",
      layout_marginBottom = "24dp",
    },
    {
      MaterialTextView,
      text = "准备就绪",
      textSize = AppTextStyle.headline.size,
      textColor = AppTextStyle.headline.color,
      gravity = "center",
      layout_marginBottom = "12dp",
      typeface = AppTextStyle.headline.font,
    },
    {
      MaterialTextView,
      text = "一切准备就绪，开始探索精彩内容吧",
      textSize = AppTextStyle.body.size,
      textColor = AppTextStyle.body.color,
      gravity = "center",
      typeface = AppTextStyle.body.font,
    }
  })

  return page
end

function WelcomeActivity:readAgreement(name)
  local path = ROOT .. "/agreements/" .. name .. ".html"
  local file = io.open(path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    return content
  end
  return nil
end

function WelcomeActivity:finishWelcome()
  for i, agreement in ipairs(agreements) do
    if self.agreementStatus[i] then
      Extensions.Config.set(agreement.name .. "_agreed", 1)
    end
  end
  Router.go("main")
  activity.finish()
end

function WelcomeActivity:onDestroy()
  -- 清空容器引用
  self.currentContainer = nil
  self.container = nil
  self.views = nil
end

return WelcomeActivity