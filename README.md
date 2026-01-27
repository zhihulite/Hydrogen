# Hydrogen

**注意**：请勿在 Gitee 反馈问题或提交 PR，请前往 GitHub 提交。Gitee 仓库仅用于代码同步。

[![License](https://img.shields.io/github/license/zhihulite/Hydrogen)](LICENSE)
[![Gitee 仓库](https://img.shields.io/badge/Gitee-仓库-C71D23?logo=gitee)](https://gitee.com/huajicloud/Hydrogen)
[![Github 仓库](https://img.shields.io/badge/Github-仓库-0969DA?logo=github)](https://github.com/zhihulite/Hydrogen)

## 项目介绍

Hydrogen 是一个基于 Androlua+ 开发的项目，为了避免重打包可以使用 [Aide Lua](https://gitee.com/AideLua/AideLua) 进行打包。也可以先通过 Gradle 打包，详见下方打包说明。

本项目是原 Hydrogen 项目的维护版本。由于时间限制，我可能无法及时维护，因此决定开源此项目，欢迎有兴趣和能力的开发者继续为 Hydrogen 添加或维护功能。

[关于 Hydrogen 项目维护延缓的说明](https://github.com/zhihulite/Hydrogen/issues/159)

## 特别致谢

- [ZL114514](https://gitee.com/ZL114514)：目前负责仓库的维护工作
- [orz12](https://gitee.com/orz12)：早期重新设计了部分布局
- [1582421598](https://github.com/1582421598)：提交 PR 修复 bug
- [NullCola](https://t.me/NullCola)：绘制矢量Hydrogen 图标

## 下载安装

最新版 App 请访问[发布页面](https://zhihulite.github.io)获取。历史版本可通过[此链接](https://workdrive.zoho.com.cn/folder/8ix3h3e8828db660e4e63acd5dd9e70bf591a)下载。

- **hydrogen-master.zip**：这是 Hydrogen 最终版 final 7 的源代码。请注意预览或打包时可能会报错。如需解决这些问题，请下载本项目中的 **要插入的 dex** 文件，将其添加至打包的 APK 中。
- **hydrogen 目录**：包含 Hydrogen 后续维护版本的源码。此版本无需下载 **要插入的 dex** 文件。

### 打包说明

您可以通过以下方式打包：
- 使用 `assembleRelease` 打包（包含 lua 文件）
- 使用 `assembleRelease_unlua` 打包（不包含 lua 文件，避免重打包）

对于 targetSdk ≥ 30 的情况，在 Android 10 及以上设备使用 AideLua 打包可能导致安装问题（因为 resources.arsc 需要对齐且不压缩），建议使用 MT 管理器进行优化。二次打包的 APK 可在项目路径 `/app/build/bin` 中找到。

### 签名信息

`hydrogen.jks` 是软件的签名文件，您可以使用 apksigner 或其他签名工具进行签名。签名信息如下：
- 别名：`hydrogen`
- 密钥库密码：`zhihu`
- 私钥密码：`android`

使用 apksigner 签名的示例命令：
```shell
apksigner sign --ks hydrogen.jks --ks-key-alias hydrogen --ks-pass pass:zhihu --key-pass pass:android --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true --v4-signing-enabled true -v --out 签名后apk 签名前apk
```
