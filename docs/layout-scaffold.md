# 布局脚手架（Helpers.Layout）

`helpers/layout.lua` 把重复的布局骨架收敛成构造器。布局文件里 `local L = Helpers.Layout`
后调用，返回的是 `loadlayout` 能吃的普通 Lua 表，可与手写节点混排。

构造器清单与参数以 `helpers/layout.lua` 的 LuaDoc 为准，本文只记不看代码就会踩的约定。

## 样式值必须运行时取

`dp2px`、`AppTheme.colors`、`AppTextStyle` 一律在 `loadlayout` 时求值，不做编译期常量替换 ——
主题切换与 Lua 热更新要求每次加载重新取值。

## L.card 的控制键与透传键

`style` / `paddingStyle` / `noMargin` / `horizontal` / `inner` 只影响脚手架自身的组装。
其余键按同名属性透传给 MaterialCardView。

**参数名必须与 MaterialCardView 的属性名一致** —— 名字对不上会被静默忽略，不报错。

## 横向卡片的第一个文本

用 `layout_width = 0` + `layout_weight = 1`，不能用 `"fill"`：横向 LinearLayout 按顺序分配宽度，
`match_parent` 会吃掉全部剩余空间，把后面的兄弟节点压成 0 宽。

## id 契约

`loadlayout` 只把声明了 `id` 的节点写进 views 表，views 是裸表无 `__index` 兜底 ——
取未声明的 id 必得 nil。改动构造器产出的 id 会让对应 Fragment 的 `views.xxx` 取空。

## 新增构造器的判据

结构在 3 个以上布局文件里逐字重复，且差异能用 2-3 个参数表达完。两条都满足才加 ——
单次使用的结构包成构造器会让读一个布局要跳两个文件。
