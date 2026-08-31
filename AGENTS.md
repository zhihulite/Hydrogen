# AGENTS.md

AI 代理与贡献者的唯一规范入口。CLAUDE.md 只指向本文件，规则不重复维护。

Hydrogen 是知乎第三方客户端：页面与业务逻辑为 Lua（`app/src/main/assets`），运行在自研
luajvm 引擎（Lua 5.5.1 语义 + luajava Java 桥）上，原生层只保留少量自定义 View 与宿主 Activity。

## 规范文档

| 文档 | 内容 |
| --- | --- |
| [docs/code-style.md](docs/code-style.md) | 文件头、注释、LuaDoc 标注、命名、码风 |
| [docs/java-interop.md](docs/java-interop.md) | luajava 互操作：import、构造、内部类、代理、数组、零调用判定 |
| [docs/debugging.md](docs/debugging.md) | 调试：Lua、JS、luajvm 引擎三条回路 |
| README.md「架构概览」 | 目录结构与模块职责、生命周期安全机制 |

## 硬性规则

1. **注释三规则**（细则见 docs/code-style.md）：
   - 禁止"为什么不这么做"论证：不写"用 A 而非 B，因为 B 会…"的替代方案对比，只写当前
     设计是什么、机制上为什么需要。
   - 禁止历史叙事：不写"旧版/曾经/原实现是 X"、"已随裁剪删除"等演变故事，注释只描述
     代码现状。
   - 禁止 § 类章节符号。
2. **Java 类引用**（细则见 docs/java-interop.md）：函数体内禁止出现全限定类名字符串
   （`org.xx.xxx` 形式）。Java 类一律在文件顶部声明，函数体只调用短名：

   ```lua
   -- 文件顶部
   import "android.content.Intent"
   local String = luajava.bindClass("java.lang.String")

   -- 函数体内
   local intent = Intent(context)
   local bytes = String(data).getBytes("UTF-8")
   ```

3. **生命周期安全**：跨异步边界的 View/回调操作经 `BasePage:runIfAlive` 包裹；页面销毁
   时移除 EdgeToEdge 注册的视图并 `luajava.clear` 解除 Java 引用。
4. **零调用代码不删除**：Java 侧没有调用者的方法或类可能正被 Lua 经 luajava 桥接调用
   （Lua 的属性访问会映射到 `getXxx`/`isXxx`），不得按"未被引用"清理；标注
   `@SuppressWarnings("unused")` 的即为此类桥接 API。细则见 docs/java-interop.md。
5. **改动后校验**：运行 `./gradlew :app:precompileLuaAssets` 编译全部 Lua 做语法检查；
   结束后运行 `./gradlew :app:cleanLuaAssets` 删除就地生成的 `.luac`（构建产物，不得提交）。

## 提交约定

提交信息用中文，动词开头或 `类型: 描述`（feat / fix / build 等），与既有提交风格一致。
