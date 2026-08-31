# 发布流程

Hydrogen 依赖的自建 Maven 仓库 [zhihulite/maven-repository](https://github.com/zhihulite/maven-repository)
托管 luajvm 引擎（`io.github.zhihulite`）与定制 material。仓库工作副本在本机
`D:\77\Documents\GitHub\maven-repository`。

## 调试期：本地 Maven

调试 luajvm 引擎改动时，把 `settings.gradle` 的 `zhihulite-releases` 仓库 URL
临时切到本地工作副本，免推送即可解析新制品：

```gradle
url = 'file:///D:/77/Documents/GitHub/maven-repository/repository/releases'
```

制品经发布任务落入本地仓库（版本号建议带 `-SNAPSHOT` 或递增，覆盖旧版本后
需清理 Gradle 缓存才会重新下载）。构建、模拟器验证都在本地闭环完成。

## 发布：远程仓库

对外发布（推送 Hydrogen 仓库、出正式包）时必须：

1. 把 `settings.gradle` 的 URL 切回远程：
   ```gradle
   url = 'https://raw.githubusercontent.com/zhihulite/maven-repository/main/repository/releases'
   ```
2. 把本地 `maven-repository` 工作副本的提交推送到 `origin/main`，确认
   `git status` 干净、远程分支已包含新制品提交。
3. 用远程 URL 完整构建一次（必要时先清缓存 `./gradlew --stop` 后删
   `~/.gradle/caches/modules-2` 中对应目录），确认制品可从远程解析。

本地 URL 不得随代码提交；提交前检查 `settings.gradle` 的 diff。
