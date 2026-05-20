# Hydrogen

> ⚠️ **项目维护延缓**  
>
> 由于相关原因，Hydrogen 项目维护已延缓。  
>
> 推荐使用同类优秀项目：[Zhihu++](https://github.com/zly2006/zhihu-plus-plus)

**注意**：请勿在 Gitee 反馈问题或提交 PR，请前往 GitHub 提交。Gitee 仓库仅用于代码同步。

[![License](https://img.shields.io/github/license/zhihulite/Hydrogen)](LICENSE)
[![Gitee 仓库](https://img.shields.io/badge/Gitee-仓库-C71D23?logo=gitee)](https://gitee.com/huajicloud/Hydrogen)
[![Github 仓库](https://img.shields.io/badge/Github-仓库-0969DA?logo=github)](https://github.com/zhihulite/Hydrogen)
## 目录

- [项目介绍](#项目介绍)
- [更新与反馈说明](#更新与反馈说明)
- [历史版本存档](#历史版本存档)
- [特别致谢](#特别致谢)
- [打包说明](#打包说明)
- [Aide Lua 调试指南](#aide-lua-调试指南)
- [贡献指南](#贡献指南)

## 项目介绍

Hydrogen 是一个基于 Androlua+ 开发的项目。

> **Aide Lua 调试提示**：
> 你可以使用 [Aide Lua](https://gitee.com/AideLua/AideLua) 实现免打包快速调试 Lua 代码。
> **但在开始调试前，请务必阅读下方的 [配置指南](#aide-lua-调试指南)**，否则因环境配置缺失将导致运行失败。
> **不建议使用 Aide Lua 进行打包**。请务必通过 Gradle 打包 APK，详见下方 **[打包说明](#打包说明)**。

## 更新与反馈说明

- **更新策略**：默认情况下，仅在必要时才会推送版本更新。
- **反馈要求**：反馈问题时，请务必使用最新版本进行测试。
- **最新构建下载**：你可以从 [GitHub Actions](https://github.com/zhihulite/Hydrogen/actions) 获取最新的自动构建版本。

## 历史版本存档

- **Hydrogen Final 7 (2022 最终版)**：[查看源码存档](https://github.com/zhihulite/Hydrogen/releases/tag/archive-final7-original)

  > 此为 2022 年发布的 Final 7 原始代码存档，已停止维护。仅用于代码回溯与历史参考。

## 特别致谢

- [ZL114514](https://github.com/ZL114514)：目前负责仓库的维护工作
- [People 11](https://GitHub.com/People-11)：使用 Gemini 进行了不少修缮
- [orz12](https://gitee.com/orz12)：早期重新设计了部分布局
- [1582421598](https://github.com/1582421598)：提交 PR 修复 bug
- [NullCola](https://t.me/NullCola)：绘制矢量 Hydrogen 图标

## 打包说明

你可以通过以下方式打包：

- 使用 `app:assembleRelease` 打包（包含 lua 文件）

  > **重要提示**：请务必指定 `app` 模块（即使用 `app:assembleRelease`）。
  > **不要**直接使用根项目的 `assembleRelease`，这可能导致打包失败。

### 签名信息

> **安全提示**：为了方便开发者调试和二次打包，本项目公开了签名文件 (`hydrogen.jks`) 及密码。**请务必确认你下载的 APK 来自官方 GitHub Releases 页面、Actions 构建产物或本仓库可信来源**。任何第三方渠道分发的 APK 均可能被篡改，请注意甄别安全风险。

`hydrogen.jks` 是软件的签名文件，你可以使用 apksigner 或其他签名工具进行签名。签名信息如下：

- 别名：`hydrogen`
- 密钥库密码：`zhihu`
- 私钥密码：`android`

使用 apksigner 签名的示例命令：

```shell
apksigner sign --ks hydrogen.jks --ks-key-alias hydrogen --ks-pass pass:zhihu --key-pass pass:android --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true --v4-signing-enabled true -v --out 签名后apk 签名前apk
```

### Aide Lua 调试指南

> **调试前必读**：如果不按以下步骤操作，Aide Lua 将无法快速调试 Hydrogen。

如果你使用 **Aide Lua** 进行代码调试，请严格遵守以下操作流程：

1. **预安装正式版**：
   首先必须通过 Gradle 打包并安装正式版的 Hydrogen APK 到设备上（确保授权存储权限）。

2. **修改 Aide Lua 设置**：
   打开 Aide Lua，点击右上角的 **设置** 图标，找到并 **关闭** “比较完整的运行” 选项。
   *(注：开启此选项会导致调试所需时间增加)*

3. **开始调试**：
   完成上述两步后，即可在 Aide Lua 中加载项目进行调试。

## 贡献指南

### 架构概览

Hydrogen 采用分层架构，Lua 编写业务逻辑，桥接 Android 原生 API。

#### 技术栈

- 语言：Lua 5.3 + Java（仅桥接层）
- UI：Material Design Components（原生控件）
- 网络：HTTP + Cookie + ZSE96 加密
- 混合渲染：原生列表 + WebView（注入 JS）

#### 分层说明

| 层级           | 职责                                                         |
| -------------- | ------------------------------------------------------------ |
| **Pages**      | Activity / Fragment 页面容器，路由跳转                       |
| **Components** | 可复用组件（适配器、弹窗、自定义 Span、WebViewHelper）       |
| **Model**      | 数据 + 视图控制（加载、分页、刷新）                          |
| **Services**   | 网络、缓存、文件、权限                                       |
| **Extensions** | 配置管理、加密、文件操作、OOP 工具                           |
| **Helpers**    | UI 工具、图片加载、链接解析                                  |
| **luaLibs**    | Lua 层基础库（import、loadlayout、json、md5、base64 等），支撑整个框架的运行 |
| **Core**       | 应用核心（初始化、常量、主题、路由、应用信息），在 Pages/Model 等之前加载，提供全局配置和基础能力 |

#### 核心基础：initApp 与 Core

- **initApp.lua**：每个 Lua 文件执行前必须引入的环境初始化脚本。负责检测运行环境（AndroLua/LuaJ++）、设置 Lua 模块搜索路径（`package.path`）、注入全局工具函数（`print`、`onError` 崩溃记录），是整个应用的**启动入口和运行环境基石**。
- **Core**：应用核心模块集合，在 `initApp` 之后加载，提供：
  - `constants.lua`：全局常量定义（SharedPreferences 键名、默认配置）
  - `app_theme.lua`：主题管理（日间/夜间/OLED 模式，Material Design 3 颜色系统）
  - `app_info.lua`：应用信息与版本更新检查
  - `router.lua`：路由系统，统一管理 Activity/Fragment 跳转
  - `init.lua`：Core 模块的汇总导出，同时初始化全局变量（Screen、Fonts、AppTextStyle、Headers 等）

> **加载顺序**：`initApp` → `core/init` → Extensions/Helpers → Pages/Model/Components

#### 核心设计

- **Model 即控制器**：`PageToolModel` 封装完整列表逻辑（下拉刷新、上拉加载、分页、多 Tab），内部直接管理 RecyclerView/ViewPager 和适配器。一个 Model 即可驱动一个列表页，Fragment 仅需调用 `setupSingle` 或 `setupTabs`。
- **路由系统**：统一管理 Activity/Fragment 跳转，支持共享元素动画和返回栈。
- **WebView 混合**：`WebViewHelper` 封装 WebView 设置与 JS 桥接，注入的 JS 实现暗色模式、图片查看、滚动恢复、截图等，与知乎 Hybrid 页面无缝配合。
- **布局定义**：使用 Lua 表描述布局（类似 XML），运行时通过 `loadlayout` 转换为原生 View，支持主题属性和数据绑定。
- **主题系统**：遵循 Material Design 3 颜色规范，支持日间/夜间/OLED 模式，动态切换。

#### LuaJava 使用规范

为避免意外重写所有非抽象方法（包括 `equals`、`hashCode` 等），请遵循以下规范：

**1. 重写类方法：使用 `luajava.override`**

```
-- ❌ 错误：会重写该类所有非抽象方法
local adapter = {
    getCount = function() return 10 end,
    getItem = function(position) return data[position] end
}

-- ✅ 正确：只重写指定方法
local adapter = luajava.override(BaseAdapter, {
    getCount = function() return 10 end,
    getItem = function(position) return data[position] end
})
```

**2. 实现接口：使用 `Extensions.UI.createFixedProxy`**

lua

```
-- ❌ 错误：ViewTreeObserver 等特殊监听器无法正确移除
local listener = luajava.createProxy("android.view.ViewTreeObserver$OnGlobalLayoutListener", {
    onGlobalLayout = function() print("layout changed") end
})

-- ✅ 正确：可以正确添加和移除各类监听器
local listener = Extensions.UI.createFixedProxy("android.view.ViewTreeObserver$OnGlobalLayoutListener", {
    onGlobalLayout = function() print("layout changed") end
})
view.getViewTreeObserver().addOnGlobalLayoutListener(listener)
-- 后续可以正确移除：view.getViewTreeObserver().removeOnGlobalLayoutListener(listener)
```

**原因说明**：

- 直接使用 `{}` 简写会重写指定类的**所有非抽象方法**，即使表中未定义该方法也会被重写，可能造成意外行为
- `luajava.createProxy` 创建的代理缺少正确的 `equals` 方法实现，导致 ViewTreeObserver 等特殊监听器无法正确移除。
- `Extensions.UI.createFixedProxy` 已正确处理 `equals` 方法，确保各类监听器均可正确注销，避免内存泄漏

#### 扩展模块补充文档

- **Helpers.material_widgets**：Material Design 组件库，支持以**原本只能在 XML 中设置的自定义属性**动态创建 Material 组件。
- **Helpers.resource**：资源快速访问工具，提供颜色、字符串、尺寸、Drawable 等资源的便捷获取方法。

---

项目模块较多，其余部分请自行阅读相关源码。

### 生命周期安全机制（isAlive / runIfAlive）

为防止 Fragment/Activity 销毁后异步回调仍执行导致崩溃，项目实现了统一的生命周期安全机制。

#### 基类支持

**BasePage** 和 **BaseModel** 均实现了：

```lua
-- 检测是否存活（未销毁）
function isAlive()
    return not self.isDestroyed
end

-- 安全执行回调（存活时执行）
function runIfAlive(callback)
    if not callback then return function() end end
    return function(...)
        if self:isAlive() then
            callback(...)
        end
    end
end
```

#### 使用规范

| 场景 | 做法 | 示例 |
|------|------|------|
| **网络回调** | 使用 `runIfAlive` 包装 | `NetWork.get(url, headers, self:runIfAlive(function(code, data) ... end))` |
| **post/runnable** | 使用 `runIfAlive` 包装 | `view.post(self:runIfAlive(function() ... end))` |
| **task 延迟任务** | 使用 `runIfAlive` 包装 | `task(1000, self:runIfAlive(function() ... end))` |
| **PageTool** | PageTool 已自动处理，无需额外包装 | `pageTool:setupLoadFunction()` 内部已包装 |
| **PageToolModel** | PageToolModel 已自动处理，无需额外包装 | `PageToolModel:refresh(key)` 内部已包装 |
| **Model 回调** | BaseModel 已自动处理，无需额外包装 | `model:load(params, callback)` 内部已包装 |
| **addListener** | BaseModel 已自动处理，销毁时清除监听器 | `model:addListener("event", handler)` |

#### 销毁链

```lua
function SomeFragment:onDestroy()
    -- chainUp 确保父类 onDestroy 自动调用
    if self.model then
        self.model:destroy()  -- 设置 isDestroyed = true
        self.model = nil
    end
    if self.webViewHelper then
        self.webViewHelper:destroy()  -- 子模块自行销毁
        self.webViewHelper = nil
    end
end
```

#### 重要说明

> **1. `isAlive` / `runIfAlive` 的使用范围**
>
> 子模块（如 `WebViewHelper`、自定义 Model 等）可以在**内部实现**自己的 `isAlive` 和 `runIfAlive` 方法，用于内部异步回调的安全包装。但**外部调用方**（如 Fragment）应统一使用 `BasePage` 提供的 `isAlive` 和 `runIfAlive` 方法，而非直接调用子模块的对应方法。
>
> 原因：正确实现销毁链后，`BasePage` 会在 `onDestroy` 中统一销毁所有子模块，子模块的销毁状态与 `BasePage` 保持一致。外部通过 `BasePage` 的方法可以确保生命周期判断的统一性，避免因直接依赖子模块状态而导致的不一致问题。
>
> **推荐做法**：
> - 子模块内部：实现私有 `isAlive` / `runIfAlive` 供内部回调使用
> - 外部调用：使用 `self:isAlive()` 或 `self:runIfAlive()`（来自 `BasePage`）
> - Fragment/Activity：始终使用继承自 `BasePage` 的生命周期方法
>
>
> **2. BaseModel 已自动处理**
>
> `BaseModel` 已自动对网络回调和监听器进行 `runIfAlive` 包装，子类无需关心。所有继承 `BaseModel` 的子类自动获得生命周期安全保护。
>
> **3. 新增子模块的销毁检测**
>
> 如果需要增加子模块（如 `WebViewHelper`），你需要正确实现销毁检测：
> - 在 `ctor` 中初始化 `self.isDestroyed = false`
> - 在 `destroy()` 方法中将 `self.isDestroyed = true`
> - 所有异步回调在调用前和 callback 设置做相关判断
> - 在当前被使用方的 `onDestroy` 中调用子模块的 `destroy()` 方法
>
> 子模块（如 `WebViewHelper`、自定义组件等）可以在内部实现 `isAlive` 和 `runIfAlive` 方法，作为快捷方式供内部异步回调使用：
>
> ```lua
> -- 子模块内部实现
> function WebViewHelper:isAlive()
>     return not self.isDestroyed
> end
>
> function WebViewHelper:runIfAlive(callback)
>     if not callback then return function() end end
>     return function(...)
>         if self:isAlive() then
>             callback(...)
>         end
>     end
> end
>
> -- 子模块内部使用
> function WebViewHelper:loadData()
>     NetWork.get(url, headers, self:runIfAlive(function(code, data)
>         self:processData(data)
>     end))
> end
> ```
> 在子模块实现完成后，建议使用 `final` 关键字锁定 `isAlive` 和 `runIfAlive` 方法，防止外部继承时意外覆盖，例如：
> -- 锁定方法，禁止子类覆盖
> WebViewHelper:final("isAlive", "runIfAlive")
> 
> 当前网络操作模块较少，如果后续增多，建议参考 BasePagee 编写一个基类自动实现销毁检测，只需在销毁函数中调用模块销毁函数即可。
>
> **4. 网络请求必须包装**
>
> 所有 `NetWork.get/post/put/delete` 等网络请求，应在调用前和回调中正确使用 `runIfAlive`。
> 注：部分未使用 BaseModel 的组件，如果涉及网络请求，请在调用设置 callback 自行添加 `runIfAlive` 包装。例如 `CollectionMoveSheet.show({..., onSuccess = self.runIfAlive(function() ... end), onError = self.runIfAlive(function() ... end)})`

#### 正确示例

```lua
-- Fragment 中发起网络请求
function MyFragment:loadData()
    NetWork.get("https://api.example.com/data", headers, self:runIfAlive(function(code, data)
        if code == 200 then
            self:updateUI(data)  -- 仅在 Fragment 存活时执行
        end
    end))
end

-- 子模块实现示例（如 WebViewHelper）
function WebViewHelper:new(webView)
    local self = {
        webView = webView,
        isDestroyed = false,
    }
    return self
end

function WebViewHelper:runIfAlive(callback)
    return function(...)
        if not self.isDestroyed then
            callback(...)
        end
    end
end

function WebViewHelper:destroy()
    self.isDestroyed = true
    if self.webView then
        self.webView.destroy()
        self.webView = nil
    end
end
```

### 快速上手

1. 入口：`main.lua` → `initApp` → `core/init` → 欢迎页或主页。
2. 路由跳转：`Router.go("answer", { answerId = "123" })`
3. 新列表页：继承 `PageToolModel` → 实现 `getInitialUrl`、`parseItem`、`createAdapter` → Fragment 中调用 `setupSingle`
4. 新详情页：继承 `BaseModel` → 实现 `load` → Fragment 中手动调用并更新 UI

掌握 `PageToolModel`、`WebViewHelper` 以及生命周期安全机制（`runIfAlive`）是快速开发大部分页面的关键。