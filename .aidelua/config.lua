--- 工具属性
tool={
  version="1.1",
}
appName="Hydrogen"--应用名称
packageName="com.zhihu.hydrogen.x"--应用包名
debugActivity="com.hydrogen.RunActivity"--运行Lua的Activity

include={"project:app","project:androlua"}--导入，第一个为主程序
compileLua=false--编译Lua，nil为跟随全局
alignZip = nil --优化APK，nil为跟随全局

---图标
---相对路径位于工程根目录下
icon={
  day="app/src/main/ic_launcher-playstore.png",--图标
  night="app/src/main/ic_launcher_night-playstore.png",--暗色模式图标
}