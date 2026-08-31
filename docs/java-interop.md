# Java 互操作

Lua 通过引擎提供的 `import` 与 `luajava.*` 访问 Java。核心规则一条：**函数体内禁止出现
全限定类名字符串（`org.xx.xxx` 形式）**，Java 类一律在文件顶部声明，函数体只调用短名。

## 声明方式

文件顶部二选一：

```lua
-- 页面 / 布局 / 组件：import 绑定为全局短名（主流写法）
import "android.content.Intent"
import "com.google.android.material.dialog.MaterialAlertDialogBuilder"

-- 库模块：绑定为文件内 local（不污染全局）
local String = luajava.bindClass("java.lang.String")
local BitmapFactoryOptions = luajava.bindClass("android.graphics.BitmapFactory$Options")
```

`import` 的行为：绑定类并写入全局变量，全局名取最后一个 `.` 或 `$` 之后的段；同时返回
类对象，需要隔离时用 `local X = import "..."`。绑定失败会回退为 `require(name)` 加载 Lua
模块。

## 构造实例

类对象可直接当构造器调用，优先于 `luajava.newInstance`：

```lua
local intent = Intent(context)          -- 不写 luajava.newInstance("android.content.Intent", context)
local file = File(activity.cacheDir, "share.jpg")
local dialog = MaterialAlertDialogBuilder(activity)
```

## 内部类

外层类已绑定时用 `外层.内部` 访问；外层未绑定时在顶部单独绑定：

```lua
import "androidx.recyclerview.widget.ItemTouchHelper"
local callback = luajava.override(ItemTouchHelper.Callback, { ... })

local TabLayoutOnTabSelectedListener = luajava.bindClass(
  "com.google.android.material.tabs.TabLayout$OnTabSelectedListener")
```

## 原始类型与数组

引擎预置 `boolean` `byte` `char` `short` `int` `long` `float` `double` 八个全局变量，
等价各原始类型的 `TYPE`。数组过桥后是 userdata（JavaCollection），可按下标读写、`#` 取长度，
含 `byte` 数组：

```lua
local uris = luajava.newArray(Uri, 1)
uris[0] = uri

local buf = luajava.newArray(byte, 8192)   -- 可写缓冲，read(buf) 填充的是它本身
local n = stream.read(buf)
```

数组类（`[B` 等）无法用短名 import，在顶部绑定：

```lua
local ByteArray = luajava.bindClass("[B")
```

## 字节数据

**出方向保真**：Java 方法返回的 `byte[]` 过桥后是 userdata（JavaCollection 包装的数组本体），
与 `int[]`、`String[]` 一致 —— `instanceof(arr, ByteArray)` 为真、可写、重载分派按 `byte[]` 走。

**入方向按值**：`byte[]` 形参同时接受 Lua 字符串（字节串）、Lua 表、`byte[]` userdata，字节
不丢：

```lua
local LuaUtil = luajava.bindClass("org.luajvm.android.util.LuaUtil")

local hash = LuaUtil.md5(imageBytes)                -- userdata 或字节串都行
stream.write(imageBytes)                            -- OutputStream.write(byte[])
Base64.encodeToString(imageBytes, Base64.NO_WRAP)   -- encodeToString(byte[], int)
```

批量读字节用引擎工具一次取完（返回 `byte[]` userdata）：

```lua
local bytes = LuaUtil.readAll(path)            -- 整个文件
local bytes = LuaUtil.readAll(inputStream)     -- 整个流，不关流，调用方自己 close
local bytes = LuaUtil.readAll(byteBuffer)      -- ByteBuffer 全部内容，不动原游标
LuaUtil.copyFile(inputStream, outputStream)    -- 流对拷
```

userdata 字节要按文本处理时显式解码；Lua 字节串要字符串方法时本来就是字符串：

```lua
local text = tostring(String(bytes, "UTF-8"))  -- byte[] userdata -> 文本
```

**不推荐**用 `java.lang.String` 在字节与字节之间中转：能跑，但不是最优解 —— `String(data)`
按 UTF-8 解码，非法序列被替换成 U+FFFD（`EF BF BD` 三字节），`.getBytes()` 再编码回来字节
数与内容都已改变，图片等二进制数据因此失真。请求体同理，`Http.post`/`Http.put` 的 body 传
字节串或 `byte[]` userdata 即可。

```lua
-- 不推荐
stream.write(String(data).getBytes("UTF-8"))
MessageDigest.getInstance("MD5").digest(String(data).bytes)

-- 推荐
stream.write(data)
LuaUtil.md5(data)
```

## 代理与覆写

接口用 `luajava.createProxy`，继承类/抽象类用 `luajava.override`，第一个参数传类对象，
不传字符串：

```lua
view.setOnClickListener(luajava.createProxy(View.OnClickListener, {
  onClick = function(v) ... end,
}))

local span = luajava.override(ReplacementSpan, { ... })
```

## 常用工具

| API | 用途 |
| --- | --- |
| `luajava.astable(obj)` | Java List/Map/数组 转 Lua table |
| `luajava.instanceof(obj, Class)` | 类型判断 |
| `luajava.clear(obj)` | 置空 userdata 持有的 Java 引用，页面销毁时对长生命周期对象调用，让 GC 能回收 |

## 桥接调用与零调用代码

Lua 通过类对象直接调用 Java 公开方法，这类调用在 Java 侧静态分析中不可见：一个方法在
`app/src/main/java` 内没有任何调用者，不代表它是死代码——它可能正被 Lua 桥接使用。
清理代码时禁止按"零调用"删除方法或类；确需下线某个 API 前，先在
`app/src/main/assets` 全量检索方法名确认无 Lua 调用点（属性访问形式 `obj.xxx` 会
映射到 `getXxx`/`isXxx`，也要一并检索）。

标注 `@SuppressWarnings("unused")` 的类与方法即此类桥接 API，属正常现状，不视为待清理项。

## 反例

```lua
-- 禁止：函数体内直接写全限定类名
local clip = luajava.newInstance("android.content.ClipData", text)
luajava.newArray(luajava.bindClass("java.lang.Byte").TYPE, 8192)
luajava.createProxy("android.text.TextWatcher", { ... })
```

对应正例：顶部 `import "android.content.ClipData"` / `local String =
luajava.bindClass("java.lang.String")`，体内 `ClipData(text)`、
`luajava.newArray(byte, 8192)`、`luajava.createProxy(TextWatcher, { ... })`。
