# 调试指南

三条独立的回路：调试 Lua、调试 JS、调试 luajvm 引擎。业务逻辑在 `app/src/main/assets`
（Lua + JS），引擎不在本仓库、以 Maven 制品引入，所以引擎改动的验证方式与业务代码不同。

免打包快速调试 Lua 见 README 的 [Aide Lua 调试指南](../README.md#aide-lua-调试指南)。

## 调试 Lua

### 免重装改脚本

Lua 不从 APK 里直接执行：首启时引擎把 `assets/` 整体解包到 `filesDir`，入口是
`<filesDir>/main.lua`。之后只要 `main.lua` 还在、APK 没被重装（`lastUpdateTime` 未变），
就不再解包，所以覆盖 `filesDir` 下的 `.lua` 即时生效：

```powershell
adb push .\ui.lua /sdcard/ui.lua
adb shell run-as com.zhihu.hydrogen.x cp /sdcard/ui.lua files/helpers/ui.lua
adb shell am force-stop com.zhihu.hydrogen.x
```

`run-as` 只在 debuggable 构建上可用。重装 APK 会先清空整个目录再解包，推进去的改动全部消失。

### 语法检查与装机

改完先过一遍编译，比装到设备上再崩快得多（AGENTS.md 硬性规则 5）：

```powershell
.\gradlew.bat :app:precompileLuaAssets   # 编译全部 Lua，语法错误直接报出来
.\gradlew.bat :app:cleanLuaAssets        # 删掉就地生成的 .luac，构建产物不得提交
.\gradlew.bat :app:installDebug
```

debug 与 release 同包名同签名、没有 `applicationIdSuffix`，装 debug 会直接覆盖设备上的正式版。

### 日志

引擎的 `print`/`printf` 无条件写 logcat（也进内存日志），tag 是 `LuaJVM`，不看任何开关：

```powershell
adb logcat -s LuaJVM LuaActivity LuaApplication
```

`initApp.lua` 给 `print` 打了补丁：先调引擎原 `print`（即上面这条 logcat），再看设置页的
「调试模式」（`SharedDataKeys.DEBUG_MODE`）——开着才额外弹模态对话框（标题 Print）。
所以关掉调试模式只是不弹窗，logcat 照旧。判据是在每次调用时惰性读的，因为 `initApp` 跑在
`core/init` 与 Extensions 之前，那时配置模块还不存在。

高频探针用 `printf`：它不经这个补丁，只落 logcat 与内存日志。

### 报错怎么显形

引擎每次报错都调用 Lua 的 `print`，所以错误一定进 logcat；开着调试模式时还会弹对话框，
标题即出错位置（如 `Lua init error`、回调名）。除此之外：

- 主 chunk（模块加载期）出错：整屏被日志 ListView 顶掉，错误连栈直接显示在屏幕上。
- 所有报错都进 logcat 的 `Log.e("LuaJVM", …)`，`LuaError` 带 `stack traceback:`。
- 未捕获的 Java 异常：崩溃日志落
  `/sdcard/Android/data/com.zhihu.hydrogen.x/files/crash/crash-<时间戳>.log`，之后才弹系统崩溃框。

### 在设备上直接跑代码

设置里打开「允许加载代码」，页面工具栏菜单会多出「执行代码」，输入的内容经 `load` 直接执行，
相当于设备端 REPL。外部脚本也可以用 scheme 拉起（域外路径会先弹确认框）：

```powershell
adb shell am start -a android.intent.action.VIEW -d "zhihu://run/sdcard/foo.lua"
```

## 调试 JS

### 注入的是合并产物

`helpers/luawebview_bridge.lua` 的 `getMergedModulesJS` 按固定清单从 `static/js` 逐个取出模块
源码，拼成一整段注入页面，清单顺序即依赖顺序（`loader` 必须排最后，它按页面类型 `runIf` 各
模块的 `init`）。想看真正注入的那份，把同文件里的 `local debug = false` 改 `true`，合并结果会
写成 `megred.js` 落到 cacheDir，路径打在日志里。

### chrome://inspect（首选）

`components/views/WebViewHelper.lua` 无条件开了 `webContentsDebuggingEnabled = true`，不看构建
类型。USB 连上设备，桌面 Chrome 打开 `chrome://inspect`，Console / Network / Elements 全都有。

### eruda（手边没有电脑时）

设置页「启用内部WebView eruda调试」（配置键 `eruda`）映射成注入侧的 `debug` 配置项，
`loader.js` 在页面 idle 时加载 `static/js/libs/eruda.js` 并 `eruda.init()`，页面上出现悬浮按钮。
问答页与本地内容页在自己的设置表里硬写了 `debug = false`，这两页开不出来。

### 免重装换单个模块

模块从 `<filesDir>/static/js/<名字>.js` 读，覆盖该文件即换实现。两层缓存都是进程级
（`moduleCache` 按路径缓存、`mergedModulesJS` 在 require 时只算一次），换完必须
`am force-stop` 杀掉进程重进。

### 从页面回喊宿主

```js
HydrogenCore.api.toast('...')   // Lua 侧 tip(...)，弹 toast
HydrogenCore.api.log('...')     // Lua 侧 print，会弹模态对话框，只适合低频断点
```

高频输出别走这条通道，用 chrome://inspect 的 console。

## 调试 luajvm 引擎

### 本地回环

引擎源码在并排 clone 的 `../luajvm`，以 `io.github.zhihulite:luajvm-android:<版本>` 引入，
制品经 `../maven-repository` 分发（`settings.gradle` 的 `zhihulite-releases` 指向该仓库的
raw.githubusercontent 地址）。调引擎时不必每轮 push，把地址临时切到本地副本：

```groovy
// settings.gradle
maven {
    name = 'zhihulite-releases'
    url = '../maven-repository/repository/releases'   // 临时：本地副本
    ...
}
```

发制品、回来构建：

```powershell
cd ..\luajvm
.\gradlew.bat publish -PluajvmVersion=1.0.0
cd ..\Hydrogen
.\gradlew.bat :app:assembleDebug
```

**验证完把地址改回原来的远端地址**（`git checkout -- settings.gradle`）：本地相对路径提交
进去，换一台机器或 CI 上就解析不到制品。

### 不重打包就改引擎开关

`<filesDir>/luajvm.props` 里的 `luajvm.*` 键会在 `attachBaseContext` 阶段写进 System property，
可以临时开关引擎特性（例如 `luajvm.webviewprewarm=false`），文件不存在时零影响：

```powershell
adb shell run-as com.zhihu.hydrogen.x sh -c 'echo luajvm.webviewprewarm=false > files/luajvm.props'
adb shell am force-stop com.zhihu.hydrogen.x
```

注入结果会打在 logcat 的 `LuajvmProps` tag 下，出现 `X=false(want true)` 说明注入晚于类初始化。
