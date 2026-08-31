# 格式化

`app/src/main/assets` 下的 Lua 统一按本文约定排版。

## 缩进

- 2 空格，不用 Tab；行尾不留空白。
- `else` / `elseif` **前置半格**：相对所属 `if` 少一个空格，缩进量为奇数。
- `end` / `until` / `}` 回到所属块的层级，缩进量为偶数。

```lua
if isManualNight then
  targetMode = NIGHT_YES
 elseif isAutoNight then
  targetMode = currentMode
 else
  targetMode = NIGHT_NO
end
```

机械校验：`else` / `elseif` 行缩进为偶数，或 `end` / `}` 行缩进为奇数，即违规。

## 空白

- 行内不留连续空格，赋值号不做跨行对齐。
- 表构造多字段时换行书写，允许尾逗号。

## 编码与行尾

- UTF-8 无 BOM。
- 一律 CRLF。行尾被改成 LF 时回写前必须转回，否则产生无意义 diff。

## 批量重排后的接受判据

整目录重排容易连带改动内容，写回仓库前逐文件分类，只接受前两类：

- 去掉全部空白字符后内容一致 —— 纯格式差异。
- 去注释、去空白后 token 序列一致 —— 仅注释差异。
- token 序列不一致 —— 代码被改动，逐处确认是有意修改再接受。

## 验收

`./gradlew :app:precompileLuaAssets` 必须 0 失败；随后 `./gradlew :app:cleanLuaAssets`
清掉就地产生的 `.luac`（构建产物不得进仓库）。
