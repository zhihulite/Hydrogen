# -------------------------------------------------------------------------
# 安全精简模式：仅移除调试元数据，不混淆、不压缩、不优化
# -------------------------------------------------------------------------

# 禁用核心修改功能，确保 Lua 调用万无一失
-dontshrink
-dontoptimize
-dontobfuscate

# 忽略所有警告，因为我们不删除代码，警告通常不影响运行
-ignorewarnings

# 抹除调试元数据
# 不保留以下属性，对应的 smali 标记就会消失：
# .source  -> SourceFile
# .line    -> LineNumberTable
# .local   -> LocalVariableTable
# .param   -> LocalVariableTypeTable
# .prologue -> (默认不保留)

# 必须保留的元数据（为了反射和注解正常工作）
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# 额外保险：保留所有类的成员名称和保护状态
-keep class ** { *; }