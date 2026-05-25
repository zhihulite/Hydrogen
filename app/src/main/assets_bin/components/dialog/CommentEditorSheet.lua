-- components/dialog/CommentEditorSheet.lua
-- 发送评论面板（支持 @提及整体块、表情包、URL自动转换、图片上传）
-- TODO 贴纸 修复 @

local M = {}

import "androidx.appcompat.widget.LinearLayoutCompat"
import "androidx.recyclerview.widget.RecyclerView"
import "androidx.recyclerview.widget.GridLayoutManager"
import "androidx.appcompat.widget.AppCompatEditText"
import "androidx.appcompat.widget.AppCompatImageView"
import "com.google.android.material.button.MaterialButton"
import "com.google.android.material.bottomsheet.BottomSheetDialog"
import "com.google.android.material.progressindicator.LinearProgressIndicator"
import "android.view.View"
import "android.view.Gravity"
import "com.google.android.material.textview.MaterialTextView"
import "android.text.Spanned"
import "java.util.regex.Pattern"
import "android.text.style.ReplacementSpan"
import "android.text.style.CharacterStyle"
import "androidx.core.widget.NestedScrollView"

local SimpleRecyclerAdapter = require("components.adapter.SimpleRecyclerAdapter")
local ImageUploader = require("services.api.image_uploader")
local MentionSpan = require("components.span.MentionSpan")
local EmojiSpan = require("components.span.EmojiSpan")
local LinkSpan = require("components.span.LinkSpan")

local URL_PATTERN = Pattern.compile("((?:https?://)?[\\w\\-]+(\\.[\\w\\-]+)+[/#?]?.*?)(?=\\s|$)", 2)

local function fetchUrlTitle(url, callback)
  local urlParams = "?url=" .. url .. "&scene=editor"

  NetWork.get("https://api.zhihu.com/content/publish/parse_url" .. urlParams, Headers["defaultHead"],
  function(code, content)
    if code == 200 then
      local data = json.decode(content)
      if data and data.code == 0 and data.data and data.data[url] then
        local info = data.data[url]
        callback(info.title, info.icon_name)
       else
        callback(url, nil)
      end
     else
      callback(url, nil)
    end
  end)
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
        text = text:gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
        :gsub("'", "&#39;")
        table.insert(result, text)
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
  local colors = AppTheme.getColors()
  local layout = {
    LinearLayoutCompat,
    orientation = "vertical",
    layout_width = "match_parent",
    layout_height = "match_parent",
    {
      NestedScrollView,
      id = "scroll_view",
      layout_width = "match_parent",
      layout_height = "0dp",
      layout_weight = 1,
      fillViewport = true,
      {
        AppCompatEditText,
        id = "input",
        layout_width = "match_parent",
        layout_height = "wrap_content",
        hint = placeholder,
        maxLines = 10,
        padding = "16dp",
        textSize = AppTextStyle.bodyMedium.size,
        textColor = AppTextStyle.bodyMedium.color,
        typeface = AppTextStyle.bodyMedium.font,
        gravity = Gravity.TOP,
        inputType = 0x00020001,
        background = null,
      },
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
        layout_width = "0dp",
        layout_weight = 1,
        layout_height = "wrap_content",
        {
          AppCompatImageView,
          id = "image_btn",
          layout_width = "28dp",
          layout_height = "28dp",
          ImageBitmap = Helpers.Static.materialIcon("twotone_image"),
          colorFilter = colors.onSurfaceVariant,
        },
        {
          AppCompatImageView,
          id = "at_btn",
          layout_width = "28dp",
          layout_height = "28dp",
          layout_marginLeft = "20dp",
          ImageBitmap = Helpers.Static.materialIcon("twotone_alternate_email"),
          colorFilter = colors.onSurfaceVariant,
        },
        {
          AppCompatImageView,
          id = "emoji_panel_btn",
          layout_width = "28dp",
          layout_height = "28dp",
          layout_marginLeft = "20dp",
          ImageBitmap = Helpers.Static.materialIcon("twotone_emoji_emotions"),
          colorFilter = colors.onSurfaceVariant,
        },
      },
      {
        AppCompatImageView,
        id = "send_btn",
        layout_width = "28dp",
        layout_height = "28dp",
        ImageBitmap = Helpers.Static.materialIcon("twotone_send"),
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
        ImageBitmap = Helpers.Static.materialIcon("twotone_close"),
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
  local scrollView = views.scroll_view
  local isAtSheetOpen = false
  local isProcessingUrl = false
  local emojiVisible = false
  local emojiList = Helpers.Static.zemojiList()

  local uploadedImageUrl = nil
  local uploadedImageWidth = nil
  local uploadedImageHeight = nil
  local uploadedImageIsGif = nil
  local imageUri = nil

  local function checkAndConvertUrl(editable)
    if isProcessingUrl then return end

    local cursor = inputView.getSelectionStart()
    if cursor <= 0 then return end

    local lastChar = editable.charAt(cursor - 1)
    if lastChar ~= 32 then return end

    isProcessingUrl = true

    local beforeCursor = editable.subSequence(0, cursor).toString()

    local matcher = URL_PATTERN.matcher(beforeCursor)
    local lastUrl = nil
    local lastUrlEnd = 0
    while matcher.find() do
      lastUrl = matcher.group()
      lastUrlEnd = matcher["end"]()
    end

    if lastUrl and lastUrlEnd == cursor - 1 then
      local startPos = lastUrlEnd - utf8.len(lastUrl)
      local urlEndPos = lastUrlEnd

      local spans = editable.getSpans(startPos, urlEndPos, ReplacementSpan)
      if not spans or #spans == 0 then
        fetchUrlTitle(lastUrl, function(title, iconName)
          editable.delete(startPos, urlEndPos)
          local displayText = title or lastUrl
          local insertPos = startPos + utf8.len(displayText)

          editable.insert(startPos, displayText)

          local link = LinkSpan.new(lastUrl, displayText, iconName)
          link.setSpan(editable, startPos, insertPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
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
        imageUri = uri
        views.image_preview.setVisibility(View.VISIBLE)
        Helpers.Image.load(views.preview_img, uri)

        local width, height = Extensions.File.getImageSizeFromUri(uri)
        local isGif = Extensions.File.isGifFromUri(uri)

        local imageBytes = Extensions.File.readUriAsBytes(uri)
        if imageBytes then
          views.upload_progress.setVisibility(View.VISIBLE)
          views.upload_progress.setIndeterminate(true)

          ImageUploader.upload(imageBytes, function(success, imageUrl)
            views.upload_progress.setVisibility(View.GONE)
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
         else
          tip("图片读取失败")
        end
      end
    end)
  end

  views.remove_image_btn.onClick = function()
    imageUri = nil
    uploadedImageUrl = nil
    views.image_preview.setVisibility(View.GONE)
    views.upload_progress.setVisibility(View.GONE)
  end

  local mainWatcher = luajava.createProxy("android.text.TextWatcher", {
    beforeTextChanged = function() end,
    onTextChanged = function() end,
    afterTextChanged = function(editable)
      if not isAtSheetOpen then
        local cursor = inputView.getSelectionStart()
        if cursor > 0 and editable.charAt(cursor - 1) == 64 then
          isAtSheetOpen = true

          local AtUserSheet = require("components.dialog.AtUserSheet")
          AtUserSheet.show({
            onSelected = function(userId, userName)
              editable.delete(cursor - 1, cursor)
              local mentionText = "@" .. userName .. " "
              local insertPos = inputView.getSelectionStart()
              if insertPos < 0 then insertPos = editable.length() end
              editable.insert(insertPos, mentionText)
              local insertEndPos = insertPos + utf8.len(mentionText)
              local mention = MentionSpan.new(userId, userName)
              mention.setSpan(editable, insertPos, insertEndPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
              inputView.setSelection(insertEndPos)
              isAtSheetOpen = false
            end
          })

          task(500, function()
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

    local AtUserSheet = require("components.dialog.AtUserSheet")
    AtUserSheet.show({
      onSelected = function(userId, userName)
        local editable = inputView.getText()
        local insertPos = inputView.getSelectionStart()
        if insertPos < 0 then insertPos = editable.length() end

        local mentionText = "@" .. userName .. " "
        editable.insert(insertPos, mentionText)
        local insertEndPos = insertPos + utf8.len(mentionText)
        local mention = MentionSpan.new(userId, userName)
        mention.setSpan(editable, insertPos, insertEndPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        inputView.setSelection(insertEndPos)

        isAtSheetOpen = false
      end
    })

    task(500, function()
      isAtSheetOpen = false
    end)
  end

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
      local drawable = Helpers.Static.zemojiDrawable(item, 32, true)
      if drawable then
        v.emoji_img.setImageDrawable(drawable)
      end
      holder.itemView.onClick = function()
        local editable = inputView.getText()
        local insertPos = inputView.getSelectionStart()
        if insertPos < 0 then insertPos = editable.length() end
        local emojiTag = "[" .. item .. "]"
        local insertEndPos = insertPos + utf8.len(emojiTag)

        editable.insert(insertPos, emojiTag)
        local span = EmojiSpan.new(item, 20)

        local emoji = EmojiSpan.new(item, 20)
        emoji.setSpan(editable, insertPos, insertEndPos, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        inputView.setSelection(insertEndPos)
      end
    end,
  })

  views.emoji_grid.setLayoutManager(GridLayoutManager(activity, 8))
  views.emoji_grid.setAdapter(emojiAdapter)

  views.emoji_panel_btn.onClick = function()
    emojiVisible = not emojiVisible
    views.emoji_grid.setVisibility(emojiVisible and View.VISIBLE or View.GONE)
  end

  local bottomSheet
  views.send_btn.onClick = function()
    local sendText = getSendText(inputView.getText(), uploadedImageUrl, uploadedImageWidth, uploadedImageHeight, uploadedImageIsGif)
    if sendText == "" then
      tip("请输入内容或选择图片")
      return
    end

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
        tip("发送失败")
        if opts.onError then opts.onError("发送失败") end
      end
    end)
  end

  bottomSheet = BottomSheetDialog(activity)
  bottomSheet.setContentView(root)
  bottomSheet.show()

  local InputMethodManager = luajava.bindClass("android.view.inputmethod.InputMethodManager")
  task(100, function()
    inputView.requestFocus()
    local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
    imm.showSoftInput(inputView, 0)
  end)

end

return M