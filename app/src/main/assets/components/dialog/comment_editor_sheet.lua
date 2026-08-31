-- components/dialog/comment_editor_sheet.lua
-- 发送评论面板（支持 @提及整体块、表情包、URL自动转换、图片上传）
-- TODO 贴纸 修复 @

local M = {}

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.recyclerview.widget.RecyclerView"
import "androidx.recyclerview.widget.GridLayoutManager"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.bottomsheet.BottomSheetDialog"
import "com.google.android.material.progressindicator.LinearProgressIndicator"
import "android.view.View"
import "android.view.Gravity"
import "android.content.Context"
import "android.text.Spanned"
import "java.util.regex.Pattern"
import "android.text.style.ReplacementSpan"
import "android.text.style.CharacterStyle"

local TextWatcher = luajava.bindClass("android.text.TextWatcher")

local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
local ImageUploader = require("services.api.image_uploader")
local MentionSpan = require("components.span.mention_span")
local EmojiSpan = require("components.span.emoji_span")
local LinkSpan = require("components.span.link_span")
local L = Helpers.Layout

local URL_PATTERN = Pattern.compile("((?:https?://)?[\\w\\-]+(\\.[\\w\\-]+)+[/#?]?.*?)(?=\\s|$)", 2)

local function fetchUrlTitle(url, callback)
  local urlParams = "?url=" .. url .. "&scene=editor"

  -- 网络异常时引擎侧以 code=-1 回调，必定触发；只有请求被安全验证闩住时
  -- NetWork.get 直接返回 false 且不进回调，这里补发一次兜底让 isProcessingUrl 复位
  local submitted = NetWork.get("https://api.zhihu.com/content/publish/parse_url" .. urlParams, Headers["defaultHead"],
  function(code, content)
    if code == 200 then
      -- 接口可能返回非 JSON，decode 失败落到下面的原始链接兜底
      local ok, data = pcall(json.decode, content)
      if ok and data and data.code == 0 and data.data and data.data[url] then
        local info = data.data[url]
        callback(info.title, info.icon_name)
       else
        callback(url, nil)
      end
     else
      callback(url, nil)
    end
  end)
  if submitted == false then
    callback(url, nil)
  end
end

local function getSendText(editable, imageUrl, imageWidth, imageHeight, isGif, stickerId, stickerTitle)
  local result = {}

  if editable and editable.length() > 0 then
    local len = editable.length()
    local i = 0

    while i < len do
      local next = editable.nextSpanTransition(i, len, CharacterStyle)
      local spans = editable.getSpans(i, next, ReplacementSpan)

      if spans and #spans > 0 then
        for j = 0, #spans - 1 do
          local span = spans[j]
          local spanText = span.toString()
          if spanText and spanText ~= "" then
            table.insert(result, spanText)
          end
        end
       else
        local text = editable.subSequence(i, next).toString()
        table.insert(result, Helpers.ZhihuParser.escapeHtml(text))
      end

      i = next
    end
  end

  local textContent = table.concat(result)

  if imageUrl and imageUrl ~= "" then
    if stickerId then
      -- TODO 打开表情面板
      -- imageUrl 为 dynamicImageUrl(动图) 或者 staticImageUrl(静图)
      local title = stickerTitle or "查看表情"
      return textContent .. '<a href="' .. imageUrl .. '" class="comment_sticker" data-width="0" data-height="0" data-sticker-id="' .. stickerId .. '">[' .. title .. ']</a>'
    end

    local type = isGif and "comment_gif" or "comment_img"
    local text = isGif and "查看动图" or "查看图片"
    local width = imageWidth or 0
    local height = imageHeight or 0
    return textContent .. '<a href="' .. imageUrl .. '" class="' .. type .. '" data-width="' .. width .. '" data-height="' .. height .. '">' .. text .. '</a>'
  end

  return textContent
end

--- 显示评论编辑器面板
--- @param opts table 配置项
--- @param opts.contentType string 内容类型 (answer/article/pin/question/comment)
--- @param opts.contentId string 内容ID
--- @param opts.replyId string|nil 回复的评论ID（可选，有则为回复模式）
--- @param opts.authorName string|nil 回复的作者名称（可选，用于 placeholder 提示）
--- @param opts.onSuccess function|nil 发送成功回调
--- @param opts.onError function|nil 发送失败回调
function M.show(opts)
  local contentType = opts.contentType
  local contentId = tostring(opts.contentId)
  local replyId = opts.replyId or ""
  local authorName = opts.authorName or ""
  local placeholder = opts.placeholder or (authorName ~= "" and "回复 " .. authorName or "发表评论")

  local views = {}
  local colors = AppTheme.colors
  local layout = {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "match_parent",
    layout_height = "match_parent",
    {
      LinearLayoutCompat,
      id = "input_lay",
      layout_width = "match_parent",
      layout_height = 0,
      layout_weight = 1,
      L.edit("input", AppTextStyle.bodyMedium, placeholder, {
        layout_height = "wrap_content",
        maxLines = 10,
        padding = "16dp",
        gravity = Gravity.TOP,
        inputType = 0x00020001,
      }),
    },
    {
      LinearLayoutCompat,
      orientation = "horizontal",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      paddingLeft = "16dp",
      paddingRight = "16dp",
      paddingTop = "8dp",
      paddingBottom = "12dp",
      gravity = Gravity.CENTER_VERTICAL,
      {
        LinearLayoutCompat,
        orientation = "horizontal",
        layout_width = 0,
        layout_weight = 1,
        layout_height = "wrap_content",
        {
          AppCompatImageView,
          id = "image_btn",
          layout_width = "28dp",
          layout_height = "28dp",
          imageBitmap = Helpers.Static.materialIcon("twotone_image"),
          colorFilter = colors.onSurfaceVariant,
        },
        {
          AppCompatImageView,
          id = "at_btn",
          layout_width = "28dp",
          layout_height = "28dp",
          layout_marginLeft = "20dp",
          imageBitmap = Helpers.Static.materialIcon("twotone_alternate_email"),
          colorFilter = colors.onSurfaceVariant,
        },
        {
          AppCompatImageView,
          id = "emoji_panel_btn",
          layout_width = "28dp",
          layout_height = "28dp",
          layout_marginLeft = "20dp",
          imageBitmap = Helpers.Static.materialIcon("twotone_emoji_emotions"),
          colorFilter = colors.onSurfaceVariant,
        },
      },
      {
        AppCompatImageView,
        id = "send_btn",
        layout_width = "28dp",
        layout_height = "28dp",
        imageBitmap = Helpers.Static.materialIcon("twotone_send"),
        colorFilter = colors.onSurfaceVariant,
      },
    },
    {
      LinearLayoutCompat,
      id = "image_preview",
      orientation = "horizontal",
      layout_width = "match_parent",
      layout_height = "wrap_content",
      padding = "12dp",
      gravity = Gravity.CENTER_VERTICAL,
      visibility = View.GONE,
      {
        AppCompatImageView,
        id = "preview_img",
        layout_width = "60dp",
        layout_height = "60dp",
        scaleType = "centerCrop",
      },
      {
        AppCompatImageView,
        id = "remove_image_btn",
        layout_width = "24dp",
        layout_height = "24dp",
        imageBitmap = Helpers.Static.materialIcon("twotone_close"),
        colorFilter = colors.error,
      },
    },
    {
      LinearProgressIndicator,
      id = "upload_progress",
      layout_width = "match_parent",
      layout_height = "2dp",
      visibility = View.GONE,
    },
    {
      RecyclerView,
      id = "emoji_grid",
      layout_width = "match_parent",
      layout_height = "240dp",
      visibility = View.GONE,
    },
  }

  local root = loadlayout(layout, views)
  local inputView = views.input
  local isAtSheetOpen = false
  local isProcessingUrl = false
  local isEmojiVisible = false
  local emojiList = Helpers.Static.zemojiList()

  local uploadedImageUrl = nil
  local uploadedImageWidth = nil
  local uploadedImageHeight = nil
  local uploadedImageIsGif = nil
  -- 选图序号：重新选图或移除图片时自增，上传回调按序号判断结果是否仍归属当前图片
  local uploadSeq = 0
  local isUploading = false

  local function checkAndConvertUrl(editable)
    if isProcessingUrl then return end

    local cursor = inputView.selectionStart
    if cursor <= 0 then return end

    local lastChar = editable.charAt(cursor - 1)
    if lastChar ~= 32 then return end

    isProcessingUrl = true

    local beforeCursor = editable.subSequence(0, cursor).toString()

    local matcher = URL_PATTERN.matcher(beforeCursor)
    local lastUrl = nil
    local lastUrlStart = 0
    local lastUrlEnd = 0
    while matcher.find() do
      lastUrl = matcher.group()
      lastUrlStart = matcher.start()
      lastUrlEnd = matcher["end"]()
    end

    if lastUrl and lastUrlEnd == cursor - 1 then
      local startPos = lastUrlStart
      local urlEndPos = lastUrlEnd

      local spans = editable.getSpans(startPos, urlEndPos, ReplacementSpan)
      if not spans or #spans == 0 then
        fetchUrlTitle(lastUrl, function(title, iconName)
          -- 请求往返期间用户可能已改动文本，区间越界或内容不再是原 URL 时放弃替换
          if urlEndPos > editable.length() or editable.subSequence(startPos, urlEndPos).toString() ~= lastUrl then
            isProcessingUrl = false
            return
          end

          editable.delete(startPos, urlEndPos)
          local displayText = title or lastUrl
          -- 区间末端按插入前后的长度差算：Java 字符数（UTF-16 码元）与码点数不等
          local lenBefore = editable.length()
          editable.insert(startPos, displayText)
          local endPos = startPos + (editable.length() - lenBefore)

          local link = LinkSpan.new(lastUrl, displayText, iconName)
          link.setSpan(editable, startPos, endPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
          isProcessingUrl = false
        end)
        return
      end
    end

    isProcessingUrl = false
  end

  views.image_btn.onClick = function()
    Extensions.File.pickFile("image/*", function(uri, name)
      if uri then
        uploadSeq = uploadSeq + 1
        local seq = uploadSeq
        isUploading = false
        uploadedImageUrl = nil

        views.image_preview.visibility = View.VISIBLE
        Helpers.Image.load(views.preview_img, uri)

        -- 只开一次流读全部字节，尺寸与 GIF 判定都从字节推导；
        -- 读取与探测是纯 IO，放 IO 线程执行，结果回主线程收，避免大图卡住 UI
        -- 解码期间预览已展示，占住 isUploading 让发送按钮等待图片就绪
        isUploading = true
        task(function()
          local imageBytes = Extensions.File.readUriAsBytes(uri)
          if not imageBytes then return nil end
          local width, height = Extensions.File.getImageSizeFromBytes(imageBytes)
          local isGif = Extensions.File.isGifFromBytes(imageBytes)
          return imageBytes, width, height, isGif
          end, function(imageBytes, width, height, isGif)
          -- 后台解码期间重选或移除图片则丢弃本次结果，状态由新流程接管
          if seq ~= uploadSeq then return end
          if not imageBytes then
            isUploading = false
            tip("图片读取失败")
            return
          end

          views.upload_progress.visibility = View.VISIBLE
          views.upload_progress.indeterminate = true

          ImageUploader.upload(imageBytes, function(success, imageUrl)
            if seq ~= uploadSeq then return end
            isUploading = false
            views.upload_progress.visibility = View.GONE
            if success then
              uploadedImageUrl = imageUrl
              uploadedImageWidth = width
              uploadedImageHeight = height
              uploadedImageIsGif = isGif
              tip("图片上传成功")
             else
              tip("图片上传失败")
            end
          end)
        end)
      end
    end)
  end

  views.remove_image_btn.onClick = function()
    -- 序号自增作废在途上传，其回调不再写回 uploadedImageUrl
    uploadSeq = uploadSeq + 1
    isUploading = false
    uploadedImageUrl = nil
    views.image_preview.visibility = View.GONE
    views.upload_progress.visibility = View.GONE
  end

  local mainWatcher = luajava.createProxy(TextWatcher, {
    beforeTextChanged = function() end,
    onTextChanged = function() end,
    afterTextChanged = function(editable)
      if not isAtSheetOpen then
        local cursor = inputView.selectionStart
        -- @
        if cursor > 0 and editable.charAt(cursor - 1) == 64 then
          isAtSheetOpen = true

          local AtUserSheet = require("components.dialog.at_user_sheet")
          AtUserSheet.show({
            onSelected = function(userId, userName)
              -- 面板停留期间文本可能已变动，删除前校验抓取的光标仍在界内且指向 @，越界或错位只插入不删
              if cursor >= 1 and cursor <= editable.length() and editable.charAt(cursor - 1) == 64 then
                editable.delete(cursor - 1, cursor)
              end
              local mentionText = "@" .. userName .. " "
              local insertPos = inputView.selectionStart
              if insertPos < 0 then insertPos = editable.length() end
              -- 区间末端按插入前后的长度差算：昵称含辅助平面字符时 Java 字符数与码点数不等
              local lenBefore = editable.length()
              editable.insert(insertPos, mentionText)
              local insertEndPos = insertPos + (editable.length() - lenBefore)
              local mention = MentionSpan.new(userId, userName)
              mention.setSpan(editable, insertPos, insertEndPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
              inputView.selection = insertEndPos
              isAtSheetOpen = false
            end
          })

          Helpers.UI.runDelayed(500, function()
            isAtSheetOpen = false
          end)
          return
        end
      end

      checkAndConvertUrl(editable)
    end
  })
  inputView.addTextChangedListener(mainWatcher)

  views.at_btn.onClick = function()
    if isAtSheetOpen then return end
    isAtSheetOpen = true

    local AtUserSheet = require("components.dialog.at_user_sheet")
    AtUserSheet.show({
      onSelected = function(userId, userName)
        -- 必须为 getEditableText() 不能是 editableText，否则会转换为 string。
        local editable = inputView.getEditableText()
        local insertPos = inputView.selectionStart
        if insertPos < 0 then insertPos = editable.length() end

        local mentionText = "@" .. userName .. " "
        -- 区间末端按插入前后的长度差算：昵称含辅助平面字符时 Java 字符数与码点数不等
        local lenBefore = editable.length()
        editable.insert(insertPos, mentionText)
        local insertEndPos = insertPos + (editable.length() - lenBefore)
        local mention = MentionSpan.new(userId, userName)
        mention.setSpan(editable, insertPos, insertEndPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        inputView.selection = insertEndPos

        isAtSheetOpen = false
      end
    })

    Helpers.UI.runDelayed(500, function()
      isAtSheetOpen = false
    end)
  end

  -- 按表情名缓存 drawable，缺图记 false；raw=true 不着色，实例可跨 item 复用
  local emojiDrawables = {}

  local emojiAdapter = SimpleRecyclerAdapter.new({
    items = emojiList,
    onCreateView = function()
      return SimpleRecyclerAdapter.inflate({
        LinearLayoutCompat,
        layout_width = "match_parent",
        layout_height = "48dp",
        gravity = Gravity.CENTER,
        {
          AppCompatImageView,
          id = "emoji_img",
          layout_width = "32dp",
          layout_height = "32dp",
          scaleType = "fitCenter",
        },
      })
    end,
    onBind = function(v, item, position, holder)
      local drawable = emojiDrawables[item]
      if drawable == nil then
        drawable = Helpers.Static.zemojiDrawable(item, 32, true) or false
        emojiDrawables[item] = drawable
      end
      if drawable then
        v.emoji_img.imageDrawable = drawable
      end
      holder.itemView.onClick = function()
        -- 必须为 getEditableText() 不能是 editableText，否则会转换为 string。
        local editable = inputView.getEditableText()
        local insertPos = inputView.selectionStart
        if insertPos < 0 then insertPos = editable.length() end
        local emojiTag = "[" .. item .. "]"
        -- 区间末端按插入前后的长度差算：表情名含辅助平面字符时 Java 字符数与码点数不等
        local lenBefore = editable.length()
        editable.insert(insertPos, emojiTag)
        local insertEndPos = insertPos + (editable.length() - lenBefore)

        local emoji = EmojiSpan.new(item, 20)
        emoji.setSpan(editable, insertPos, insertEndPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        inputView.selection = insertEndPos
      end
    end,
  })

  views.emoji_grid.layoutManager = GridLayoutManager(activity, 8)
  views.emoji_grid.adapter = emojiAdapter

  -- 边缘渐变效果
  views.emoji_grid.verticalFadingEdgeEnabled = true
  views.emoji_grid.fadingEdgeLength = 80

  views.emoji_panel_btn.onClick = function()
    isEmojiVisible = not isEmojiVisible
    views.emoji_grid.visibility = isEmojiVisible and View.VISIBLE or View.GONE
  end

  local bottomSheet
  local isSending = false
  views.send_btn.onClick = function()
    -- 在途发送期间忽略点击，避免网络往返内连点 POST 出重复评论
    if isSending then return end
    -- 图片上传未回填 uploadedImageUrl 时发送会丢图，先等上传结束
    if isUploading then
      tip("图片上传中，请稍候")
      return
    end

    -- 必须为 getEditableText() 不能是 editableText，否则会转换为 string。
    local sendText = getSendText(inputView.getEditableText(), uploadedImageUrl, uploadedImageWidth, uploadedImageHeight, uploadedImageIsGif)
    if sendText == "" then
      tip("请输入内容或选择图片")
      return
    end

    isSending = true
    views.send_btn.alpha = 0.4

    local postUrl = "https://www.zhihu.com/api/v4/comment_v5/" .. contentType .. "s/" .. contentId .. "/comment"
    local postData = json.encode({
      comment_id = "",
      content = sendText,
      extra_params = "",
      has_img = uploadedImageUrl ~= nil,
      reply_comment_id = replyId,
      score = 0,
      selected_settings = {},
      sticker_type = nil,
      unfriendly_check = "strict",
    })

    NetWork.post(postUrl, postData, nil, function(code, _)
      if code == 200 then
        tip("发送成功")
        if opts.onSuccess then opts.onSuccess() end
        bottomSheet.dismiss()
       else
        -- 失败后面板仍在，复位发送态让用户重试
        isSending = false
        views.send_btn.alpha = 1
        tip("发送失败")
        if opts.onError then opts.onError("发送失败") end
      end
    end)
  end

  bottomSheet = BottomSheetDialog(activity)
  bottomSheet.contentView = root
  bottomSheet.show()

  Helpers.UI.runDelayed(100, function()
    inputView.requestFocus()
    local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
    imm.showSoftInput(inputView, 0)
  end)

end

return M