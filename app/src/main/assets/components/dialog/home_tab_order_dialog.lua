-- components/dialog/home_tab_order_dialog.lua
-- 主页 Tab 排序弹窗：拖拽调整启用的 Tab 顺序并单选主页

local M = {}

import "androidx.recyclerview.widget.ItemTouchHelper"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

local SimpleRecyclerAdapter = require("components.adapter.simple_recycler_adapter")
local SafeLinearLayoutManager = luajava.bindClass("com.hydrogen.SafeLinearLayoutManager")

local SharedDataKeys = Constants.SharedDataKeys

local LAYOUTS = {
  dialog = Layouts.pages.settings.dialogs.home_tab_order,
  tab_header = Layouts.pages.settings.items.home_tab_header,
  tab_item = Layouts.pages.settings.items.home_tab_item,
}

-- HOME_TAB_ORDER 形如 "推荐,热榜,关注,推荐"：逗号分隔的启用 Tab 顺序，末位重复的那项是主页。
-- 列表把「当前」「其他」两个分组标题行与 Tab 项混排，标题行只有 header 字段、没有 title。
local function buildPageData()
  local config = Extensions.Config.getString(SharedDataKeys.HOME_TAB_ORDER)
  local enabledTabs = {}
  for tab in config:gmatch("[^,]+") do
    table.insert(enabledTabs, tab)
  end
  local homeTab = table.remove(enabledTabs)

  local restTabs = { ["推荐"] = true, ["想法"] = true, ["热榜"] = true, ["关注"] = true }
  for _, item in ipairs(enabledTabs) do
    restTabs[item] = nil
  end

  local pageData = {}
  table.insert(pageData, { header = "当前" })
  for _, item in ipairs(enabledTabs) do
    table.insert(pageData, { title = item, isHome = (item == homeTab) })
  end
  table.insert(pageData, { header = "其他" })
  for tab in pairs(restTabs) do
    table.insert(pageData, { title = tab, isHome = false })
  end
  return pageData
end

-- 「其他」标题行之前的 Tab 按列表顺序写入配置，末位再追加一次主页名
local function saveOrder(pageData)
  local selected, conf = nil, {}
  for _, v in ipairs(pageData) do
    if v.title then
      table.insert(conf, v.title)
      if v.isHome then selected = v.title end
     elseif v.header == "其他" then break
    end
  end
  if #conf < 2 or not selected then
    tip("需至少开启两页且选一个主页")
    return
  end
  table.insert(conf, selected)
  Extensions.Config.set(SharedDataKeys.HOME_TAB_ORDER, table.concat(conf, ","))
  tip("保存成功，下次启动生效")
end

--- 显示主页 Tab 排序弹窗，确定后写入 HOME_TAB_ORDER 配置
function M.show()
  local pageData = buildPageData()
  local dialogViews = {}

  MaterialAlertDialogBuilder(activity)
  .setTitle("主页Tab排序")
  .setView(loadlayout(LAYOUTS.dialog, dialogViews))
  .setPositiveButton("确定", {
    onClick = function()
      saveOrder(pageData)
    end
  })
  .setNegativeButton("取消", nil)
  .show()

  local adapter = SimpleRecyclerAdapter.new({
    items = pageData,
    getItemViewType = function(pos, item)
      return item.header and 1 or 0
    end,
    onCreateView = function(viewType)
      if viewType == 1 then
        return SimpleRecyclerAdapter.inflate(LAYOUTS.tab_header)
       else
        return SimpleRecyclerAdapter.inflate(LAYOUTS.tab_item)
      end
    end,
    onBind = function(views, item, position, holder, adapter)
      if item.header then
        views.header.text = item.header
       else
        views.title.text = item.title
        views.radio.checked = item.isHome
        -- 单选主页：点中项与原选中项各自局部刷新，位置按 holder 的实时下标取
        views.itemRoot.onClick = function()
          local currentPos = holder.getAdapterPosition()
          if currentPos == -1 then return end

          local currentHomeIndex = nil
          for i, v in ipairs(pageData) do
            if v.title and v.isHome then
              currentHomeIndex = i
              break
            end
          end
          if currentHomeIndex == currentPos + 1 then return end

          if currentHomeIndex then
            pageData[currentHomeIndex].isHome = false
            adapter.notifyItemChanged(currentHomeIndex - 1)
          end

          item.isHome = true
          adapter.notifyItemChanged(currentPos)
        end
      end
    end,
  })

  local dragCallback = luajava.override(ItemTouchHelper.Callback, {
    -- 分组标题行不参与拖动，只有 Tab 项可上下移动
    getMovementFlags = function(_, _, vh)
      local row = pageData[vh.adapterPosition + 1]
      if not row or row.header then
        return int(0)
      end
      return int(ItemTouchHelper.Callback.makeMovementFlags(ItemTouchHelper.UP | ItemTouchHelper.DOWN, 0))
    end,
    -- 位置 0 是「当前」标题行，不能作为落点
    canDropOver = function(_, _, current, target)
      return target.adapterPosition > 0
    end,
    onMove = function(_, _, vh, target)
      local from = vh.adapterPosition + 1
      local to = target.adapterPosition + 1
      pageData[from], pageData[to] = pageData[to], pageData[from]
      adapter.notifyItemMoved(from - 1, to - 1)
      return true
    end,
  })

  ItemTouchHelper(dragCallback).attachToRecyclerView(dialogViews.recycler)

  dialogViews.recycler.layoutManager = SafeLinearLayoutManager(activity)
  dialogViews.recycler.adapter = adapter
end

return M
