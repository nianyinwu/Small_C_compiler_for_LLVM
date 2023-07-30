## Small C compiler for LLVM IR

1. Feature of my Compiler
(1) lexical analyzer 去識別C subset並將字串轉為token
(2) parser 驗證字串是否能由C 的grammer產生
(3) 使用 java 產生 immediate code
而我的compiler產生的 immediate code能夠進行一些簡單的運算：
arithmetic computation、Comparison expression、
if-then / if-then-else program constructs (Nested if construct)、
Printf function、 scanf function、
For-loop construct/ while-loop construct / Switch-case construct、
Logical operation、
自定義的function call等等的功能(詳細在MS-WORD)

2.Compile:（我的antlr-3.5.3-complete-no-st3.jar在此資料夾中）
第 1 種方式:
先下指令 java -cp ./antlr-3.5.3-complete-no-st3.jar org.antlr.Tool myCompiler.g 產生 myCompilerLexer.java、myCompilerParser.java 與 myCompiler.tokens
再下指令 javac -cp ./antlr-3.5.3-complete-no-st3.jar:. *.java 進行編譯
第 2 種方式:
使用Makefile 直接下指令make

3.Execute:
第一步：產生.ll檔
java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test0.c
java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test1.c
java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test2.c
java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test3.c
java -cp ./antlr-3.5.3-complete-no-st3.jar:. myCompiler_test test10.c
第二步：interpreter
lli test0.ll
lli test1.ll
lli test2.ll
lli test3.ll
lli test10.ll
