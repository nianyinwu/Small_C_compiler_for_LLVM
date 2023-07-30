import org.antlr.runtime.*;
import java.util.ArrayList;
import java.util.List;
import java.io.*;

public class myCompiler_test {
	public static void main(String[] args) throws Exception {
	  String f = new String (args[0]);

      CharStream input = new ANTLRFileStream(args[0]);
      myCompilerLexer lexer = new myCompilerLexer(input);
      CommonTokenStream tokens = new CommonTokenStream(lexer);
 
      myCompilerParser parser = new myCompilerParser(tokens);
      parser.program();
      
	  /* Save the LLVM IR code and Output text section */
      List<String> text_code = parser.getTextCode();
	  String name = f.substring(0,f.length()-1);
	  name = name + "ll";
	  File file = new File(name);
	  file.createNewFile();
	  FileWriter writer = new FileWriter(file);
	  
	  for (int i=0; i < text_code.size(); i++){
		 writer.write(text_code.get(i));
		 writer.write("\n");
         System.out.println(text_code.get(i));
      }
	  writer.flush();
      writer.close();
	}
}
