all:
	java -cp ./antlr-3.5.3-complete-no-st3.jar org.antlr.Tool *.g
	javac -cp ./antlr-3.5.3-complete-no-st3.jar:. *.java
clean:
	rm -f myCompilerParser.java myCompilerLexer.java *.tokens *.class