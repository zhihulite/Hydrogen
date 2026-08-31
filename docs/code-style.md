# 代码风格

适用范围：`app/src/main/assets` 下所有 Lua 文件，`app/src/main/java` 下所有 Java 文件。

## 文件头

每个 Lua 文件首行为自身路径注释，第二行为一句话职责：

```lua
-- pages/base/BasePage.lua
-- 所有页面的基类
```

适配自第三方的 Java 文件在文件头注明出处（`// 实现参考: <url>`），不写其他文件头。

## 注释

注释只描述代码现状与机制，遵守三条禁令：

1. **禁止"为什么不这么做"论证**：不写"用 A 而非 B，因为 B 会…"的替代方案对比。
   只写当前设计是什么、机制上为什么需要。
2. **禁止历史叙事**：不写"旧版/曾经/原实现是 X"、"曾尝试 Y"、"已随裁剪删除"等演变故事。
3. **禁止 § 类章节符号**，同样不使用 `// ========== xxx ==========` 分节横幅，分节用空行。

写法：

- 函数上方单行注释说明职责；机制约束写在紧邻代码处，说明"这段代码依赖什么前提"。
- 不复述代码：getter/setter、构造器、与代码逐字对应的步骤注释一律不写。
- 待办用 `-- TODO 说明`（Java 用 `// TODO 说明`），可附链接。
- 警告性注释直接给出约束与后果，如"页面销毁时务必调用 remove 清理"。

```lua
-- 本引擎把 Java byte[] 回传 Lua 时转成字符串（Lua 字符串就是字节串），
-- 字节用 string.byte 逐个读取。
local bytes = md.digest(String(data).bytes)
```

## LuaDoc 标注

公共 API（`M.xxx`、被继承的基类方法、跨文件回调）用 `---` 三横线标注，内部函数用普通
`--` 注释。参数与返回值按 `名字 类型 说明` 书写，可空类型加 `|nil`：

```lua
--- 分享文件，返回删除函数
--- @param filePath string 文件路径
--- @param mimeType string|nil MIME 类型，默认 "image/*"
--- @return function 删除函数
function M.shareFile(filePath, text, mimeType, onError)
```

基类可覆写方法（子类必须/可选实现）用空实现 + 注释声明，如 `function BasePage:initViews() end`。

## 命名

| 对象 | 风格 | 示例 |
| --- | --- | --- |
| 模块文件（core/helpers/extensions/services/models/layout） | snake_case | `core/router.lua`、`helpers/ui.lua` |
| 页面/组件类文件（pages/components） | PascalCase | `BasePage.lua`、`MaterialToolbar` 相关布局 |
| 变量、函数、方法 | camelCase | `getFirstPageUrl`、`parseResponse` |
| 常量 | UPPER_SNAKE | `MEDIA_MOUNTED`、`PageType.ACTIVITY` |
| 布尔 | is / has / need / enable 前缀 | `isAlive`、`needLogin`、`enableLoadMore` |
| 事件回调 | on 前缀 | `onCreate`、`onLoadSuccess` |
| 模块表 | `local M = {}` 导出 | `function M.setup(options)` |

## 码风

- 缩进 2 空格，不用 Tab；行尾不留空白。
- 字符串一律双引号。
- `then`、`do` 与条件同行，`else`/`elseif` 与 `if` 对齐缩进。
- table 构造允许尾逗号，多字段时换行书写。
- 拼接优先 `..`；格式化输出用 `string.format`。
- 全局变量只允许在 `core/init.lua` 与 `initApp.lua` 注入，业务代码一律 `local` 或经
  `_G.Extensions` / `_G.Helpers` / `_G.Services` 命名空间访问。

## Java 补充

- 注释规则与 Lua 一致：公共 API 与非直观机制用 Javadoc（`/** */`）或行注释说明；
  自明代码、IDE 生成残留（如空方法上的 `// TODO: Implement this method`）不留。
- 命名遵循 Java 标准：类 PascalCase、方法与变量 camelCase、常量 UPPER_SNAKE。
- 缩进 4 空格，不用 Tab；行尾不留空白。
- Java 侧零调用的方法或类不得按"未被引用"删除：它们可能经 luajava 从 Lua 桥接调用，
  判定方法见 docs/java-interop.md。
