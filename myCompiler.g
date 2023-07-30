grammar myCompiler;

options {
   language = Java;
   k = 2;
   backtrack=true;
}

@header {
    // import packages here.
    import java.util.HashMap;
    import java.util.ArrayList;
    import java.math.BigDecimal;
}

@members {
    boolean TRACEON = false;
	int scope = 0;
	
    // Type information.
    public enum Type{
		ERR, BOOL, INT, FLOAT, CHAR, DOUBLE, CONST_INT, VOID, LABEL, STRING, CONST_FLOAT,CONST_CHAR,STRUCT;
    }
    
    public enum Key{
        STATIC,SHORT,CONST,LONG_LONG,LONG,SIGNED,UNSIGNED,EXTERN;
    }

    // This structure is used to record the information of a variable or a constant.
    class tVar {
	   int   varIndex; // temporary variable's index. Ex: t1, t2, ..., etc.
	   int   iValue;   // value of constant integer. Ex: 123.
	   String fValue;   // value of constant floating point. Ex: 2.314.
	};

    class Info {
       Key theKey;
       Type theType;  // type information.
       tVar theVar;
       boolean isGlobal;
	   boolean isFunc;
	   
	   Info() {
          theType = Type.ERR;
		  theVar = new tVar();
          theKey = null;
          isGlobal = false;
		  isFunc = false;
	   }
    };

	
    // ============================================
    // Create a symbol table.
	// ArrayList is easy to extend to add more info. into symbol table.
	//
	// The structure of symbol table:
	// <variable ID, [Type, [varIndex or iValue, or fValue]]>
	//    - type: the variable type   (please check "enum Type")
	//    - varIndex: the variable's index, ex: t1, t2, ...
	//    - iValue: value of integer constant.
	//    - fValue: value of floating-point constant.
    // ============================================

    HashMap<String, Info> symtab = new HashMap<String, Info>();

    // labelCount is used to represent temporary label.
    // The first index is 0.
    int labelCount = 0;
	int textCount=0;
	int strCount = 0;
	String curLabel = null;

    // varCount is used to represent temporary variables.
    // The first index is 0.
    int varCount = 0;


    // Record all assembly instructions.
	String structt = null;
	List<String> CaseL = new ArrayList<String>();
	List<String> CaseT = new ArrayList<String>();
    List<String> TextCode = new ArrayList<String>();
	List<String> EndL = new ArrayList<String>();
	List<String> ElseL = new ArrayList<String>();
	List<String> ForL = new ArrayList<String>();
    List<String> WhileL = new ArrayList<String>();

    /*
     * Output prologue.
     */
    void prologue()
    {
       TextCode.add(0,"; === prologue ====");
	   textCount ++;
	   TextCode.add(1,"declare dso_local i32 @scanf(i8*, ...)\n");
       TextCode.add(2,"declare dso_local i32 @printf(i8*, ...)\n");
	   textCount ++;

	}
    
	
    /*
     * Output epilogue.
     */
    void epilogue()
    {
       /* handle epilogue */
       TextCode.add("\n; === epilogue ===");
	   TextCode.add("ret i32 0");
       TextCode.add("}");
    }
    
    
    /* Generate a new label */
    String newLabel()
    {
       labelCount ++;
       return (new String("L")) + Integer.toString(labelCount);
    } 
	
	String newStr()
    {
       strCount ++;
       return (new String("str")) + Integer.toString(strCount);
    } 
    
    public List<String> getTextCode()
    {
       return TextCode;
    }
}

header:  POUND INCLUDE '<' LIBRARY '>' {if (TRACEON) System.out.println("#include<LIBRARY>"); } ;

global : func_dec 
	   | global_dec ';'
       ;

global_dec : ((key)? type a = Identifier ('=' c=arith_expression )?)
				{   
					String str = $a.text + Integer.toString(scope);
					if (symtab.containsKey(str)){ // identifier already exist
						System.out.println("Error! " + $a.getLine() + ": Redeclared identifier." + "( identifier:" +$a.text +" )"); 
						System.exit(0);
					} // if
					if($key.keytype != null){
						if((($key.keytype==Key.LONG)||($key.keytype==Key.LONG_LONG)||($key.keytype==Key.SHORT)) && !($type.attr_type == Type.INT)){
							System.out.println("Error! " + $a.getLine() + ": " + $key.keytype + " " + $type.attr_type + " is invalid.");
							System.exit(0);
						} // if
					} // if

					Info the_entry = new Info();
					the_entry.theType = $type.attr_type;
					the_entry.theKey = $key.keytype;
					the_entry.theVar.varIndex = varCount;
					the_entry.isGlobal = true;
					varCount ++;
					symtab.put(str, the_entry);
					//System.out.println(the_entry.theVar.varIndex);
					// issue the instruction.
					// Ex: \%a = alloca i32, align 4
					if( $c.theInfo == null ){
						if ($type.attr_type == Type.INT) {
							if($key.keytype != null){
								if ( $key.keytype==Key.SHORT ) TextCode.add("@t" + the_entry.theVar.varIndex + " = common global i16 0, align 2");
								else if ( $key.keytype==Key.LONG ) TextCode.add("@t" + the_entry.theVar.varIndex + " = common global i64 0, align 8");
								else if ( $key.keytype==Key.LONG_LONG ) TextCode.add("@t" + the_entry.theVar.varIndex + " = common global i64 0, align 8");
								else TextCode.add("@t" + the_entry.theVar.varIndex + " = common global i32 0, align 4");
							}
							else TextCode.add("@t" + the_entry.theVar.varIndex + " = common global i32 0, align 4");
						}
						else if ($type.attr_type == Type.FLOAT) {
							String s = String.format("\%e", Double.valueOf(0));
							TextCode.add("@t" + the_entry.theVar.varIndex + " = common global float "+ s +", align 4");
						}
						else if ($type.attr_type == Type.DOUBLE) {
							String s = String.format("\%e", Double.valueOf(0));
							TextCode.add("@t" + the_entry.theVar.varIndex + " = common global double " + s + ", align 8");
						}
						else if ($type.attr_type == Type.CHAR) {
							TextCode.add("@t" + the_entry.theVar.varIndex + " = common global i8 0, align 1");
						}
					}
					else {
						if ( $c.theInfo.theType != Type.CONST_INT && $c.theInfo.theType != Type.CONST_FLOAT && $c.theInfo.theType != Type.CONST_CHAR){
							System.out.println("Error! " + $a.getLine() + ": Type mismatch for the two silde operands in a global declaration assignment.");
							System.exit(0);
						} // if
						if (symtab.get(str).theType != $c.theInfo.theType
							&& !((symtab.get(str).theType == Type.FLOAT || symtab.get(str).theType == Type.DOUBLE ) && ($c.theInfo.theType == Type.INT))
							&& !((symtab.get(str).theType == Type.FLOAT || symtab.get(str).theType == Type.DOUBLE ) && ($c.theInfo.theType == Type.FLOAT || $c.theInfo.theType == Type.DOUBLE ))
							&& !((symtab.get(str).theType == Type.INT) && ($c.theInfo.theType == Type.CHAR))
							&& !((symtab.get(str).theType == Type.INT)&& ($c.theInfo.theType != Type.BOOL))
							&& !((symtab.get(str).theType == Type.INT||symtab.get(str).theType == Type.FLOAT ||symtab.get(str).theType == Type.DOUBLE) && ($c.theInfo.theType == Type.CONST_INT))
							&& !((symtab.get(str).theType == Type.FLOAT|| symtab.get(str).theType == Type.DOUBLE) && ($c.theInfo.theType == Type.CONST_FLOAT))
							&& !((symtab.get(str).theType == Type.CHAR) && ($c.theInfo.theType == Type.CONST_CHAR))) {
							System.out.println("Error! " + $a.getLine() + ": Type mismatch for the two silde operands in a declaration assignment.");
							System.exit(0);
						} // if
					  
						Info theRHS = $c.theInfo;
						Info theLHS = symtab.get(($a.text + Integer.toString(scope)));
						//System.out.println(theLHS.theType);
						//System.out.println(theRHS.theType);
						if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.CONST_INT)){
							if( (theLHS.theKey == Key.SHORT))
								TextCode.add("@t" + theLHS.theVar.varIndex + " = global i16 "+ theLHS.theVar.iValue +", align 2");
							else if( (theLHS.theKey == Key.LONG))
								TextCode.add("@t" + theLHS.theVar.varIndex + " = global i64 "+ theLHS.theVar.iValue +", align 8");
							else if( (theLHS.theKey == Key.LONG_LONG))
								TextCode.add("@t" + theLHS.theVar.varIndex + " = global i64 "+ theLHS.theVar.iValue +", align 8");
							else
								TextCode.add("@t" + theLHS.theVar.varIndex + " = global i32 "+ theLHS.theVar.iValue +", align 4");
						}
						else if ((theLHS.theType == Type.FLOAT) && (theRHS.theType == Type.CONST_INT)) {
							String s = String.format("\%e", Double.valueOf(theRHS.theVar.iValue));
							TextCode.add("@t" + theLHS.theVar.varIndex + " = global float " + s +", align 4");
						} // else if
						else if ((theLHS.theType == Type.FLOAT) && (theRHS.theType == Type.CONST_FLOAT)) {
							Float f = Float.parseFloat(theRHS.theVar.fValue);
							double dou = (double) f;
							long bits = Double.doubleToLongBits(dou);
							String s = String.format("\%16s", Long.toHexString(bits));
							s = s.toUpperCase();
							s = "0x" + s ;
							TextCode.add("@t" + theLHS.theVar.varIndex + " = global float " + s +", align 4");
						} // else if
						else if ((theLHS.theType == Type.DOUBLE) && (theRHS.theType == Type.CONST_INT)) {
							// issue store insruction.
							// Ex: store i32 value, i32* \%ty
							String s = String.format("\%e", Double.valueOf(theRHS.theVar.iValue));
							TextCode.add("@t" + theLHS.theVar.varIndex + " = global double " + s +", align 8");
						} // else if
						else if ((theLHS.theType == Type.DOUBLE) && (theRHS.theType == Type.CONST_FLOAT)) {
							Double dou = Double.parseDouble(theRHS.theVar.fValue);
							long bits = Double.doubleToLongBits(dou);
							String s = String.format("\%16s", Long.toHexString(bits));
							s = s.toUpperCase();
							s = "0x" + s ;
							TextCode.add("@t" + theLHS.theVar.varIndex + " = global double " + s +", align 8");
						} // else if
						else if ((theLHS.theType == Type.CHAR) && (theRHS.theType == Type.CONST_CHAR)) {
						    TextCode.add("@t" + theLHS.theVar.varIndex + " = global i8 " + theRHS.theVar.iValue +", align 8");
						} // else if
					}
				}
			| STRUCT a = Identifier '{' (type b = Identifier
				{	
					if (structt == null){
						structt = new String("");
						if ( $type.attr_type == Type.CHAR ) structt = structt.concat(" i8");
						else if ( $type.attr_type == Type.INT ) structt = structt.concat(" i32");
						else if ( $type.attr_type == Type.FLOAT ) structt = structt.concat(" float");
						else if ( $type.attr_type == Type.DOUBLE ) structt = structt.concat(" double");
					}
					else{
						if ( $type.attr_type == Type.CHAR ) structt = structt.concat(", i8");
						else if ( $type.attr_type == Type.INT ) structt = structt.concat(", i32");
						else if ( $type.attr_type == Type.FLOAT ) structt = structt.concat(", float");
						else if ( $type.attr_type == Type.DOUBLE ) structt = structt.concat(", double");;
					}
				}
			 ';')+ '}' 
				{
					String str = $a.text;
					if (symtab.containsKey(str)){ // identifier already exist
						System.out.println("Error! " + $a.getLine() + ": identifier is func name." + "( identifier:" +$a.text +" )"); 
						System.exit(0);
					}
					str = $a.text + Integer.toString(scope);
					if (symtab.containsKey(str)){ // identifier already exist
						System.out.println("Error! " + $a.getLine() + ": Redeclared identifier." + "( identifier:" +$a.text +" )"); 
						System.exit(0);
					}
					Info the_entry = new Info();
					the_entry.theType = Type.STRUCT;
					the_entry.theKey = null;
					the_entry.theVar.varIndex = -1;
					symtab.put(str, the_entry);
					
					TextCode.add("\%" + str + " = type {" + structt + "}" );

					

					
					
				}	
                ;

func_dec : INT a=Identifier
			{	
				if($a.text == "main" )
					System.exit(0);
				String str = $a.text + Integer.toString(scope);
				if (symtab.containsKey(str)){ // identifier already exist
					System.out.println("Error! " + $a.getLine() + ": Redeclared identifier." + "( identifier:" +$a.text +" )"); 
				    System.exit(0);
				} // if
				str = $a.text;
				Info the_entry = new Info();
				the_entry.theType = Type.INT;
				the_entry.theKey = null;
				the_entry.isFunc = true;
				the_entry.theVar.varIndex = varCount;
				varCount ++;
				symtab.put(str, the_entry);
			}
			'(' INT b=Identifier ')'
			{
				scope=scope+1;
				String str = $b.text + Integer.toString(scope);
				if (symtab.containsKey(str)){ // identifier already exist
					System.out.println("Error! " + $b.getLine() + ": Redeclared identifier." + "( identifier:" +$a.text +" )"); 
				    System.exit(0);
				} // if
				Info the_entry = new Info();
				the_entry.theType = Type.INT;
				the_entry.theKey = null;
				the_entry.isFunc = true;
				the_entry.theVar.varIndex = varCount;
				varCount ++;
				symtab.put(str, the_entry);
				Info theLHS = symtab.get($a.text);
				TextCode.add("define dso_local i32 @t" +  theLHS.theVar.varIndex + "(i32 \%t" +  the_entry.theVar.varIndex + ") {" );
				TextCode.add("\%t" + varCount + " = alloca i32, align 4");
				int pre = varCount;
				TextCode.add("store i32 \%t" + the_entry.theVar.varIndex + ", i32* \%t" + pre + ", align 4");
				the_entry.theVar.varIndex = pre;
				varCount ++;
			}
			'{'
				statements
				RETURN ( c=logic_arith_expression
					{
						if($c.theInfo.theType == Type.CONST_INT)
							TextCode.add("ret i32 " +$c.theInfo.theVar.iValue );
						else if($c.theInfo.theType == Type.INT) {
							TextCode.add("ret i32 \%t" + $c.theInfo.theVar.varIndex);
							varCount++;
						}
						else{
							System.out.println("Error! " + $RETURN.getLine() + ": function return type is wrong." ); 
							System.exit(0);
						}

					}
				|{TextCode.add("ret i32 0");} 
				) ';'
				{TextCode.add("}");}
			'}'
			;


program:{prologue();}(header)* (global)*
		( (VOID|INT)  MAIN '(' ')'
        {  scope=scope+1;
           	TextCode.add("define dso_local i32 @main()");
	   		TextCode.add("{");
        }
        '{' 
           statements
		   (RETURN (logic_arith_expression)? ';')?
        '}'
        { if (TRACEON)
	      System.out.println("VOID MAIN () {declarations statements}");

           /* output function epilogue */	  
           epilogue();
        }
		)
		;
		


// declarations
declarations: (key)? type a = Identifier 
				{
				  String str = $a.text;
				  if (symtab.containsKey(str)){ // identifier already exist
					System.out.println("Error! " + $a.getLine() + ": identifier is func name." + "( identifier:" +$a.text +" )"); 
				    System.exit(0);
				  }
				  str = $a.text + Integer.toString(scope);
				  if (symtab.containsKey(str)){ // identifier already exist
					System.out.println("Error! " + $a.getLine() + ": Redeclared identifier." + "( identifier:" +$a.text +" )"); 
				    System.exit(0);
				  }
				  if($key.keytype != null){
                    if((($key.keytype==Key.LONG)||($key.keytype==Key.LONG_LONG)||($key.keytype==Key.SHORT)) && !($type.attr_type == Type.INT)){
                        System.out.println("Error! " + $a.getLine() + ": " + $key.keytype + " " + $type.attr_type + " is invalid.");
                        System.exit(0);
                    }
                  }
                  
				  Info the_entry = new Info();
    			  the_entry.theType = $type.attr_type;
                  the_entry.theKey = $key.keytype;
			      the_entry.theVar.varIndex = varCount;
			      varCount ++;
			      symtab.put(str, the_entry);
				  //System.out.println(the_entry.theVar.varIndex);
     			  // issue the instruction.
		          // Ex: \%a = alloca i32, align 4
                  if ($type.attr_type == Type.INT) {
                    if($key.keytype != null){
                        if ( $key.keytype==Key.SHORT ) TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i16, align 2");
                        else if ( $key.keytype==Key.LONG ) TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i64, align 8");
                        else if ( $key.keytype==Key.LONG_LONG ) TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i64, align 8");
                        else TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
                    }
                    else TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
                  }
                  else if ($type.attr_type == Type.FLOAT) {
                    TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca float, align 4");
                  }
                  else if ($type.attr_type == Type.DOUBLE) {
                    TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca double, align 8");
                  }
                  else if ($type.attr_type == Type.CHAR) {
                    TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i8, align 1");
                  }
				}
				('=' c=arith_expression 
					{   String str = $a.text + Integer.toString(scope);
						if (symtab.get(str).theType != $c.theInfo.theType
							&& !((symtab.get(str).theType == Type.FLOAT || symtab.get(str).theType == Type.DOUBLE ) && ($c.theInfo.theType == Type.INT))
							&& !((symtab.get(str).theType == Type.FLOAT || symtab.get(str).theType == Type.DOUBLE ) && ($c.theInfo.theType == Type.FLOAT || $c.theInfo.theType == Type.DOUBLE ))
							&& !((symtab.get(str).theType == Type.INT) && ($c.theInfo.theType == Type.CHAR))
							&& !((symtab.get(str).theType == Type.INT)&& ($c.theInfo.theType != Type.BOOL))
							&& !((symtab.get(str).theType == Type.INT||symtab.get(str).theType == Type.FLOAT ||symtab.get(str).theType == Type.DOUBLE) && ($c.theInfo.theType == Type.CONST_INT))
							&& !((symtab.get(str).theType == Type.FLOAT|| symtab.get(str).theType == Type.DOUBLE) && ($c.theInfo.theType == Type.CONST_FLOAT))
							&& !((symtab.get(str).theType == Type.CHAR) && ($c.theInfo.theType == Type.CONST_CHAR))) {
							System.out.println("Error! " + $a.getLine() + ": Type mismatch for the two silde operands in a declaration assignment.");
							System.exit(0);
						}
					
						Info theRHS = $c.theInfo;
						Info theLHS = symtab.get(($a.text + Integer.toString(scope)));
						//System.out.println(theLHS.theType);
						//			   System.out.println(theRHS.theType);
						if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.INT)){
							// issue the instruction.
							// Ex: \%a = alloca i32, align 4
							if( (theLHS.theKey == Key.SHORT) && (theRHS.theKey == Key.SHORT) )
								TextCode.add("store i16 \%t" + theRHS.theVar.varIndex + ", i16* \%t" + theLHS.theVar.varIndex + ", align 2");
							else if( (theLHS.theKey == Key.LONG) && (theRHS.theKey == Key.LONG) )
								TextCode.add("store i64 \%t" + theRHS.theVar.varIndex + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else if( (theLHS.theKey == Key.LONG_LONG) && (theRHS.theKey == Key.LONG_LONG) )
								TextCode.add("store i64 \%t" + theRHS.theVar.varIndex + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else { 
								if (( theLHS.theKey == null )){
									if (( theRHS.theKey == null ))
										TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
									else if((theRHS.theKey == Key.SHORT)){
										TextCode.add("\%t" + varCount +  " = sext i16 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;									
									}
									else if( (theRHS.theKey == Key.LONG)){
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;	
									}
									else if( (theRHS.theKey == Key.LONG_LONG )){
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;	
									}
								} // if 
								else if (( theLHS.theKey == Key.SHORT )){
									if ( (theRHS.theKey == null ) )
										TextCode.add("\%t" + varCount +  " = trunc i32 \%t" + theRHS.theVar.varIndex + " to i16");
									else if( (theRHS.theKey == Key.LONG) )
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i16");
									else if( (theRHS.theKey == Key.LONG_LONG ))
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i16");
									TextCode.add("store i16 \%t" + varCount + ", i16* \%t" + theLHS.theVar.varIndex + ", align 2");
									varCount++;
								} // else if 
								else if (( theLHS.theKey == Key.LONG ) || ( theLHS.theKey == Key.LONG_LONG )){
									if((theRHS.theKey == null))
										TextCode.add("\%t" + varCount +  " = sext i32 \%t" + theRHS.theVar.varIndex + " to i64");
									else if((theRHS.theKey == Key.SHORT))
										TextCode.add("\%t" + varCount +  " = sext i16 \%t" + theRHS.theVar.varIndex + " to i64");
									TextCode.add("store i64 \%t" + varCount + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
									varCount++;
								} // else if 		
								//TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
							}
						}
						else if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.CONST_INT)){
							if( (theLHS.theKey == Key.SHORT))
								TextCode.add("store i16 " + theRHS.theVar.iValue + ", i16* \%t" + theLHS.theVar.varIndex + ", align 2");
							else if( (theLHS.theKey == Key.LONG))
								TextCode.add("store i64 " +  theRHS.theVar.iValue + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else if( (theLHS.theKey == Key.LONG_LONG))
								TextCode.add("store i64 " + theRHS.theVar.iValue + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else
								TextCode.add("store i32 " + theRHS.theVar.iValue + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
						}
						else if ((theLHS.theType == Type.FLOAT) &&
							(theRHS.theType == Type.FLOAT)) {
							// issue store insruction.
							// Ex: store i32 value, i32* \%ty
							TextCode.add("store float \%t" + theRHS.theVar.varIndex + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
						} // else if
						else if ((theLHS.theType == Type.FLOAT) &&
							(theRHS.theType == Type.CONST_INT)) {
							// issue store insruction.
							// Ex: store i32 value, i32* \%ty
							String s = String.format("\%e", Double.valueOf(theRHS.theVar.iValue));
							TextCode.add("store float " + s + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
						} // else if
						else if ((theLHS.theType == Type.FLOAT) &&
							(theRHS.theType == Type.CONST_FLOAT)) {
							// issue store insruction.
							// Ex: store i32 value, i32* \%ty
							Float f = Float.parseFloat(theRHS.theVar.fValue);
							double dou = (double) f;
							long bits = Double.doubleToLongBits(dou);
							String s = String.format("\%16s", Long.toHexString(bits));
							s = s.toUpperCase();
							s = "0x" + s ;
							TextCode.add("store float " + s + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
						} // else if
						else if ((theLHS.theType == Type.FLOAT) &&
							(theRHS.theType == Type.DOUBLE)) {
							// issue store insruction.
							// Ex: store i32 value, i32* \%ty
							TextCode.add("\%t" + varCount + " = fptrunc double \%t" + theRHS.theVar.varIndex + " to float");
							TextCode.add("store float \%t" + varCount + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
							varCount++;
						} // else if
						else if ((theLHS.theType == Type.DOUBLE) &&
							(theRHS.theType == Type.FLOAT)) {
							// issue store insruction.
							// Ex: store i32 value, i32* \%ty
							TextCode.add("\%t" + varCount + " = fpext float \%t" + theRHS.theVar.varIndex + " to double" );
							TextCode.add("store double \%t" + varCount + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
							varCount++;
						} // else if
						else if ((theLHS.theType == Type.DOUBLE) &&
							(theRHS.theType == Type.DOUBLE)) {
							// issue store insruction.
							// Ex: store i32 value, i32* \%ty
							TextCode.add("store double \%t" + theRHS.theVar.varIndex + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
						} // else if
						else if ((theLHS.theType == Type.DOUBLE) &&
							(theRHS.theType == Type.CONST_INT)) {
							// issue store insruction.
							// Ex: store i32 value, i32* \%ty
							String s = String.format("\%e", Double.valueOf(theRHS.theVar.iValue));
							TextCode.add("store double " + s + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
						} // else if
						else if ((theLHS.theType == Type.DOUBLE) &&
							(theRHS.theType == Type.CONST_FLOAT)) {
							// issue store insruction.
							// Ex: store i32 value, i32* \%ty
							// System.out.println(theRHS.theVar.fValue);
							Double dou = Double.parseDouble(theRHS.theVar.fValue);
							long bits = Double.doubleToLongBits(dou);
							String s = String.format("\%16s", Long.toHexString(bits));
							//System.out.println(s);
							//s = s.substring(0,9);
							s = s.toUpperCase();
							s = "0x" + s ;
							TextCode.add("store double " + s + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
						} // else if
						else if ((theLHS.theType == Type.CHAR) &&
							(theRHS.theType == Type.CHAR)) {
							// issue store insruction.
							// Ex: store i32 value, i32* \%ty
							TextCode.add("store i8 \%t" + theRHS.theVar.varIndex + ", i8* \%t" + theLHS.theVar.varIndex + ", align 1");
						} // else if
						else if ((theLHS.theType == Type.CHAR) &&
							(theRHS.theType == Type.CONST_CHAR)) {
							// issue store insruction.
							// Ex: store i32 value, i32* \%ty
							TextCode.add("store i8 " + theRHS.theVar.iValue + ", i8* \%t" + theLHS.theVar.varIndex + ", align 1");
						} // else if
					}
				)? 
				(','  b = Identifier
					{
						String str = $b.text;
				  		if (symtab.containsKey(str)){ // identifier already exist
							System.out.println("Error! " + $b.getLine() + ": identifier is func name." + "( identifier:" +$b.text +" )"); 
							System.exit(0);
						}
						str = $b.text + Integer.toString(scope);
						if (symtab.containsKey(str)){ // identifier already exist
							System.out.println("Error! " + $a.getLine() + ": Redeclared identifier." + "( identifier:" +$b.text +" )"); 
							System.exit(0);
						}
						if($key.keytype != null){
							if((($key.keytype==Key.LONG)||($key.keytype==Key.LONG_LONG)||($key.keytype==Key.SHORT)) && !($type.attr_type == Type.INT)){
								System.out.println("Error! " + $a.getLine() + ": " + $key.keytype + " " + $type.attr_type + " is invalid.");
								System.exit(0);
							}
						}
						
						Info the_entry = new Info();
						the_entry.theType = $type.attr_type;
						the_entry.theKey = $key.keytype;
						the_entry.theVar.varIndex = varCount;
						varCount ++;
						symtab.put(str, the_entry);
									
						// issue the instruction.
						// Ex: \%a = alloca i32, align 4
						if ($type.attr_type == Type.INT) {
							if($key.keytype != null){
								if ( $key.keytype==Key.SHORT ) TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i16, align 2");
								else if ( $key.keytype==Key.LONG ) TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i64, align 8");
								else if ( $key.keytype==Key.LONG_LONG ) TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i64, align 8");
								else TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
							}
							else TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
						}
						else if ($type.attr_type == Type.FLOAT) {
							TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca float, align 4");
						}
						else if ($type.attr_type == Type.DOUBLE) {
							TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca double, align 8");
						}
						else if ($type.attr_type == Type.CHAR) {
							TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i8, align 1");
						}
					}
				('=' d=arith_expression 
					{   String str = $b.text + Integer.toString(scope);
						if (symtab.get(str).theType != $c.theInfo.theType
							&& !((symtab.get(str).theType == Type.FLOAT || symtab.get(str).theType == Type.DOUBLE ) && ($c.theInfo.theType == Type.INT))
							&& !((symtab.get(str).theType == Type.FLOAT || symtab.get(str).theType == Type.DOUBLE ) && ($c.theInfo.theType == Type.FLOAT || $c.theInfo.theType == Type.DOUBLE ))
							&& !((symtab.get(str).theType == Type.INT) && ($c.theInfo.theType == Type.CHAR))
							&& !((symtab.get(str).theType == Type.INT)&& ($c.theInfo.theType != Type.BOOL))
							&& !((symtab.get(str).theType == Type.INT||symtab.get(str).theType == Type.FLOAT ||symtab.get(str).theType == Type.DOUBLE) && ($c.theInfo.theType == Type.CONST_INT))
							&& !((symtab.get(str).theType == Type.FLOAT|| symtab.get(str).theType == Type.DOUBLE) && ($c.theInfo.theType == Type.CONST_FLOAT))
							&& !((symtab.get(str).theType == Type.CHAR) && ($c.theInfo.theType == Type.CONST_CHAR))) {
							System.out.println("Error! " + $a.getLine() + ": Type mismatch for the two silde operands in a declaration assignment.");
							System.exit(0);
						}
					
						Info theRHS = $d.theInfo;
						Info theLHS = symtab.get(str);
					
						if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.INT)){
							// issue the instruction.
							// Ex: \%a = alloca i32, align 4
							if( (theLHS.theKey == Key.SHORT) && (theRHS.theKey == Key.SHORT) )
								TextCode.add("store i16 \%t" + theRHS.theVar.varIndex + ", i16* \%t" + theLHS.theVar.varIndex + ", align 2");
							else if( (theLHS.theKey == Key.LONG) && (theRHS.theKey == Key.LONG) )
								TextCode.add("store i64 \%t" + theRHS.theVar.varIndex + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else if( (theLHS.theKey == Key.LONG_LONG) && (theRHS.theKey == Key.LONG_LONG) )
								TextCode.add("store i64 \%t" + theRHS.theVar.varIndex + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else{ 
								if (( theLHS.theKey == null )){
									if (( theRHS.theKey == null ))
										TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
									else if((theRHS.theKey == Key.SHORT)){
										TextCode.add("\%t" + varCount +  " = sext i16 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;									
									}
									else if( (theRHS.theKey == Key.LONG)){
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;	
									}
									else if( (theRHS.theKey == Key.LONG_LONG )){
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;	
									}
								} // if 
								else if (( theLHS.theKey == Key.SHORT )){
									if ( (theRHS.theKey == null ) )
										TextCode.add("\%t" + varCount +  " = trunc i32 \%t" + theRHS.theVar.varIndex + " to i16");
									else if( (theRHS.theKey == Key.LONG) )
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i16");
									else if( (theRHS.theKey == Key.LONG_LONG ))
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i16");
									TextCode.add("store i16 \%t" + varCount + ", i16* \%t" + theLHS.theVar.varIndex + ", align 2");
									varCount++;
								} // else if 
								else if (( theLHS.theKey == Key.LONG ) || ( theLHS.theKey == Key.LONG_LONG )){
									if((theRHS.theKey == null))
										TextCode.add("\%t" + varCount +  " = sext i32 \%t" + theRHS.theVar.varIndex + " to i64");
									else if((theRHS.theKey == Key.SHORT))
										TextCode.add("\%t" + varCount +  " = sext i16 \%t" + theRHS.theVar.varIndex + " to i64");
									TextCode.add("store i64 \%t" + varCount + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
									varCount++;
								} // else if 
							}
						}
						else if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.CONST_INT)){
							if( (theLHS.theKey == Key.SHORT))
								TextCode.add("store i16 " + theRHS.theVar.iValue + ", i16* \%t" + theLHS.theVar.varIndex + ", align 2");
							else if( (theLHS.theKey == Key.LONG))
								TextCode.add("store i64 " + theRHS.theVar.iValue + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else if( (theLHS.theKey == Key.LONG_LONG))
								TextCode.add("store i64 " + theRHS.theVar.iValue + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else
								TextCode.add("store i32 " + theRHS.theVar.iValue + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
						}
						else if ((theLHS.theType == Type.FLOAT) &&
							(theRHS.theType == Type.FLOAT)) {
						// issue store insruction.
						// Ex: store i32 value, i32* \%ty
						TextCode.add("store float \%t" + theRHS.theVar.varIndex + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
						} // else if
						else if ((theLHS.theType == Type.FLOAT) &&
							(theRHS.theType == Type.CONST_INT)) {
						// issue store insruction.
						// Ex: store i32 value, i32* \%ty
						String s = String.format("\%e", Double.valueOf(theRHS.theVar.iValue));
						TextCode.add("store float " + s + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
						} // else if
						else if ((theLHS.theType == Type.FLOAT) &&
							(theRHS.theType == Type.CONST_FLOAT)) {
						// issue store insruction.
						// Ex: store i32 value, i32* \%ty
						Float f = Float.parseFloat(theRHS.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = "0x" + s ;
						s = s.toUpperCase();
						TextCode.add("store float " + s + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
						} // else if
						else if ((theLHS.theType == Type.FLOAT) &&
							(theRHS.theType == Type.DOUBLE)) {
						// issue store insruction.
						// Ex: store i32 value, i32* \%ty
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + theRHS.theVar.varIndex + " to float");
						TextCode.add("store float \%t" + varCount + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
						varCount++;
						} // else if
						else if ((theLHS.theType == Type.DOUBLE) &&
							(theRHS.theType == Type.FLOAT)) {
						// issue store insruction.
						// Ex: store i32 value, i32* \%ty
						TextCode.add("\%t" + varCount + " = fpext float \%t" + theRHS.theVar.varIndex + " to double" );
						TextCode.add("store double \%t" + varCount + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
						varCount++;
						} // else if
						else if ((theLHS.theType == Type.DOUBLE) &&
							(theRHS.theType == Type.DOUBLE)) {
						// issue store insruction.
						// Ex: store i32 value, i32* \%ty
						TextCode.add("store double \%t" + theRHS.theVar.varIndex + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
						} // else if
						else if ((theLHS.theType == Type.DOUBLE) &&
							(theRHS.theType == Type.CONST_INT)) {
						// issue store insruction.
						// Ex: store i32 value, i32* \%ty
						String s = String.format("\%e", Double.valueOf(theRHS.theVar.iValue));
						TextCode.add("store double " + s + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
						} // else if
						else if ((theLHS.theType == Type.DOUBLE) &&
							(theRHS.theType == Type.CONST_FLOAT)) {
						// issue store insruction.
						// Ex: store i32 value, i32* \%ty
						Double dou = Double.parseDouble(theRHS.theVar.fValue);
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						//System.out.println(s);
						//s = s.substring(0,9);
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("store double " + s + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
						} // else if
						else if ((theLHS.theType == Type.CHAR) &&
							(theRHS.theType == Type.CHAR)) {
						// issue store insruction.
						// Ex: store i32 value, i32* \%ty
						TextCode.add("store i8 \%t" + theRHS.theVar.varIndex + ", i8* \%t" + theLHS.theVar.varIndex + ", align 1");
						} // else if
						else if ((theLHS.theType == Type.CHAR) &&
							(theRHS.theType == Type.CONST_CHAR)) {
						// issue store insruction.
						// Ex: store i32 value, i32* \%ty
						TextCode.add("store i8 " + theRHS.theVar.iValue + ", i8* \%t" + theLHS.theVar.varIndex + ", align 1");
						} // else if
					}			
				)?)*
              { if (TRACEON) System.out.println("declarations: (key)? type Identifier('=' arith_expression )? (',' Identifier('=' arith_expression )?)* ; "); }
			  ;
			  


type returns [Type attr_type]
	: INT { if (TRACEON) System.out.println("type: INT"); $attr_type=Type.INT; }
	| FLOAT { if (TRACEON) System.out.println("type: FLOAT"); $attr_type=Type.FLOAT; }
	| VOID { if (TRACEON) System.out.println("type: VOID"); $attr_type=Type.VOID; }
	| CHAR'*' { if (TRACEON) System.out.println("type: STRING"); $attr_type=Type.STRING; }
	| CHAR { if (TRACEON) System.out.println("type: CHAR"); $attr_type=Type.CHAR; }
	| DOUBLE { if (TRACEON) System.out.println("type: DOUBLE"); $attr_type=Type.DOUBLE; }
	| BOOL { if (TRACEON) System.out.println("type: BOOL"); $attr_type=Type.BOOL; }
	;  


statements:statement statements
          |
          ;



statement: declarations ';'
		 | assign_statement ';'
         | if_else_stmt
         | printf_func 
		 | scanf_func
         | func_no_return_stmt ';'
         | for_stmt
         | while_stmt
		 | switch_stmt
		 | ';'
         ; 
		 


assign_statement: Identifier
                ( PP
                {
					String str = $Identifier.text;
				  	if (symtab.containsKey(str)){ // identifier already exist
						System.out.println("Error! " + $Identifier.getLine() + ": identifier is func name." + "( identifier:" +$Identifier.text +" )"); 
				  	 	System.exit(0);
				 	}
                    str = $Identifier.text + Integer.toString(scope);
                    Info t = symtab.get(str);
                    int cur = scope;
                    while( t == null ){
                        cur = cur - 1;
                        if( cur < 0 ){
                            System.out.println("Error! " + $Identifier.getLine() + ": Undefined identifier."+ "( identifier:" +$Identifier.text +" )");
                            System.exit(0);
                        } // if
                        str = $Identifier.text + Integer.toString(cur);
                        t = symtab.get(str);
                        if(t != null) break;
                    } // while
                    Info Id =symtab.get(str);
                    if(Id.theType == Type.INT){
						if ( Id.isGlobal ){
							TextCode.add("\%t" + varCount + " = load i32, i32* @t" + Id.theVar.varIndex + ", align 4");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + pre + ", 1" );
							TextCode.add("store i32 \%t" + varCount + ", i32* @t" + Id.theVar.varIndex + ", align 4");
							varCount ++;
						}
                        else{
							TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + Id.theVar.varIndex + ", align 4");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + pre + ", 1" );
							TextCode.add("store i32 \%t" + varCount + ", i32* \%t" + Id.theVar.varIndex + ", align 4");
							varCount ++;
						}
					}//if
					else if(Id.theType == Type.FLOAT){
						if ( Id.isGlobal ){
							TextCode.add("\%t" + varCount + " = load float, float* @t" + Id.theVar.varIndex + ", align 4");
							int pre = varCount;
							varCount++;
							String s = String.format("\%e", Double.valueOf(1));
							TextCode.add("\%t" + varCount + " = fadd float \%t" + pre + ", " + s );
							TextCode.add("store float \%t" + varCount + ", float* @t" + Id.theVar.varIndex + ", align 4");
							varCount ++;
						}
                        else{
							TextCode.add("\%t" + varCount + " = load float, float* \%t" + Id.theVar.varIndex + ", align 4");
							int pre = varCount;
							varCount++;
							String s = String.format("\%e", Double.valueOf(1));
							TextCode.add("\%t" + varCount + " = fadd float \%t" + pre + ", " + s );
							TextCode.add("store float \%t" + varCount + ", float* \%t" + Id.theVar.varIndex + ", align 4");
							varCount ++;
						}
					}//else if
					else if(Id.theType == Type.DOUBLE){
						if ( Id.isGlobal ){
							TextCode.add("\%t" + varCount + " = load double, double* @t" + Id.theVar.varIndex + ", align 8");
							int pre = varCount;
							varCount++;
							String s = String.format("\%e", Double.valueOf(1));
							TextCode.add("\%t" + varCount + " = fadd double \%t" + pre + ", " + s );
							TextCode.add("store double \%t" + varCount + ", double* @t" + Id.theVar.varIndex + ", align 8");
							varCount ++;
						}
                        else{
							TextCode.add("\%t" + varCount + " = load double, double* \%t" + Id.theVar.varIndex + ", align 8");
							int pre = varCount;
							varCount++;
							String s = String.format("\%e", Double.valueOf(1));
							TextCode.add("\%t" + varCount + " = fadd double \%t" + pre + ", " + s );
							TextCode.add("store double \%t" + varCount + ", double* \%t" + Id.theVar.varIndex + ", align 8");
							varCount ++;
						}
					}//else if
					else if(Id.theType == Type.CHAR){
						if ( Id.isGlobal ){
							TextCode.add("\%t" + varCount + " = load i8, i8* @t" + Id.theVar.varIndex + ", align 1");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = add i8 \%t" + pre + ", 1" );
							TextCode.add("store i8 \%t" + varCount + ", i8* @t" + Id.theVar.varIndex + ", align 1");
							varCount ++;
						}
                        else{
							TextCode.add("\%t" + varCount + " = load i8, i8* \%t" + Id.theVar.varIndex + ", align 1");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = add i8 \%t" + pre + ", 1" );
							TextCode.add("store i8 \%t" + varCount + ", i8* \%t" + Id.theVar.varIndex + ", align 1");
							varCount ++;
						}
					}//else if
                }
                | MM
                {
                    String str = $Identifier.text;
				  	if (symtab.containsKey(str)){ // identifier already exist
						System.out.println("Error! " + $Identifier.getLine() + ": identifier is func name." + "( identifier:" +$Identifier.text +" )"); 
				  	 	System.exit(0);
				 	}
                    str = $Identifier.text + Integer.toString(scope);
                    Info t = symtab.get(str);
                    int cur = scope;
                    while( t == null ){
                        cur = cur - 1;
                        if( cur < 0 ){
                            System.out.println("Error! " + $Identifier.getLine() + ": Undefined identifier."+ "( identifier:" +$Identifier.text +" )");
                            System.exit(0);
                        } // if
                        str = $Identifier.text + Integer.toString(cur);
                        t = symtab.get(str);
                        if(t != null) break;
                    } // while
                    Info Id =symtab.get(str);
					if(Id.theType == Type.INT){
						if ( Id.isGlobal ){
							TextCode.add("\%t" + varCount + " = load i32, i32* @t" + Id.theVar.varIndex + ", align 4");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + pre + ", 1" );
							TextCode.add("store i32 \%t" + varCount + ", i32* @t" + Id.theVar.varIndex + ", align 4");
							varCount ++;
						}
                        else{
							TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + Id.theVar.varIndex + ", align 4");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + pre + ", 1" );
							TextCode.add("store i32 \%t" + varCount + ", i32* \%t" + Id.theVar.varIndex + ", align 4");
							varCount ++;
						}
					}//if
					else if(Id.theType == Type.FLOAT){
						if ( Id.isGlobal ){
							TextCode.add("\%t" + varCount + " = load float, float* @t" + Id.theVar.varIndex + ", align 4");
							int pre = varCount;
							varCount++;
							String s = String.format("\%e", Double.valueOf(1));
							TextCode.add("\%t" + varCount + " = fsub float \%t" + pre + ", " + s );
							TextCode.add("store float \%t" + varCount + ", float* @t" + Id.theVar.varIndex + ", align 4");
							varCount ++;
						}
                        else{
							TextCode.add("\%t" + varCount + " = load float, float* \%t" + Id.theVar.varIndex + ", align 4");
							int pre = varCount;
							varCount++;
							String s = String.format("\%e", Double.valueOf(1));
							TextCode.add("\%t" + varCount + " = fsub float \%t" + pre + ", " + s );
							TextCode.add("store float \%t" + varCount + ", float* \%t" + Id.theVar.varIndex + ", align 4");
							varCount ++;
						}
					}//else if
					else if(Id.theType == Type.DOUBLE){
						if ( Id.isGlobal ){
							TextCode.add("\%t" + varCount + " = load double, double* @t" + Id.theVar.varIndex + ", align 8");
							int pre = varCount;
							varCount++;
							String s = String.format("\%e", Double.valueOf(1));
							TextCode.add("\%t" + varCount + " = fsub double \%t" + pre + ", " + s );
							TextCode.add("store double \%t" + varCount + ", double* @t" + Id.theVar.varIndex + ", align 8");
							varCount ++;
						}
                        else{
							TextCode.add("\%t" + varCount + " = load double, double* \%t" + Id.theVar.varIndex + ", align 8");
							int pre = varCount;
							varCount++;
							String s = String.format("\%e", Double.valueOf(1));
							TextCode.add("\%t" + varCount + " = fsub double \%t" + pre + ", " + s );
							TextCode.add("store double \%t" + varCount + ", double* \%t" + Id.theVar.varIndex + ", align 8");
							varCount ++;
						}
					}//else if
					else if(Id.theType == Type.CHAR){
						if ( Id.isGlobal ){
							TextCode.add("\%t" + varCount + " = load i8, i8* @t" + Id.theVar.varIndex + ", align 1");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = add i8 \%t" + pre + ", -1" );
							TextCode.add("store i8 \%t" + varCount + ", i8* @t" + Id.theVar.varIndex + ", align 1");
							varCount ++;
						}
                        else{
							TextCode.add("\%t" + varCount + " = load i8, i8* \%t" + Id.theVar.varIndex + ", align 1");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = add i8 \%t" + pre + ", -1" );
							TextCode.add("store i8 \%t" + varCount + ", i8* \%t" + Id.theVar.varIndex + ", align 1");
							varCount ++;
						}
					}//else if
                }
                | '=' logic_arith_expression
                 {
                    String str = $Identifier.text;
				  	if (symtab.containsKey(str)){ // identifier already exist
						System.out.println("Error! " + $Identifier.getLine() + ": identifier is func name." + "( identifier:" +$Identifier.text +" )"); 
				  	 	System.exit(0);
				 	}
                    str = $Identifier.text + Integer.toString(scope);
                    Info t = symtab.get(str);
                    int cur = scope;
                    while( t == null ){
                        cur = cur - 1;
                        if( cur < 0 ){
                            System.out.println("Error! " + $Identifier.getLine() + ": Undefined identifier."+ "( identifier:" +$Identifier.text +" )");
                            System.exit(0);
                        } // if
                        str = $Identifier.text + Integer.toString(cur);
                        t = symtab.get(str);
                        if(t != null) break;
                    } // while
                    
                    Info theRHS = $logic_arith_expression.theInfo;
                    Info theLHS = symtab.get(str);
               		//System.out.println(theLHS.theType);
					//System.out.println(theRHS.theType);
					if (theLHS.theType != theRHS.theType
                        && !((theLHS.theType == Type.FLOAT || theLHS.theType == Type.DOUBLE ) && (theRHS.theType == Type.INT))
                        && !((theLHS.theType == Type.FLOAT || theLHS.theType == Type.DOUBLE ) && (theRHS.theType == Type.FLOAT || theRHS.theType == Type.DOUBLE ))
						&& !((theLHS.theType == Type.INT) && (theRHS.theType == Type.CHAR))
                        && !((theLHS.theType == Type.INT)&& (theRHS.theType != Type.BOOL))
                        && !((theLHS.theType == Type.INT||theLHS.theType == Type.FLOAT || theLHS.theType == Type.DOUBLE) && (theRHS.theType == Type.CONST_INT))
                        && !((theLHS.theType == Type.FLOAT|| theLHS.theType == Type.DOUBLE) && (theRHS.theType == Type.CONST_FLOAT))
                        && !((theLHS.theType == Type.CHAR) && (theRHS.theType == Type.CONST_CHAR))) {
						System.out.println("Error! " + $Identifier.getLine() + ": Type mismatch for the two silde operands in a declaration assignment.");
						System.exit(0);
					}
                    if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.INT)){
                        // issue the instruction.
						if(theLHS.isGlobal){
							// Ex: \%a = alloca i32, align 4
							if( (theLHS.theKey == Key.SHORT) && (theRHS.theKey == Key.SHORT) )
								TextCode.add("store i16 \%t" + theRHS.theVar.varIndex + ", i16* @t" + theLHS.theVar.varIndex + ", align 2");
							else if( (theLHS.theKey == Key.LONG) && (theRHS.theKey == Key.LONG) )
								TextCode.add("store i64 \%t" + theRHS.theVar.varIndex + ", i64* @t" + theLHS.theVar.varIndex + ", align 8");
							else if( (theLHS.theKey == Key.LONG_LONG) && (theRHS.theKey == Key.LONG_LONG) )
								TextCode.add("store i64 \%t" + theRHS.theVar.varIndex + ", i64* @t" + theLHS.theVar.varIndex + ", align 8");
							else {
								if (( theLHS.theKey == null )){
									if (( theRHS.theKey == null ))
										TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* @t" + theLHS.theVar.varIndex + ", align 4");
									else if((theRHS.theKey == Key.SHORT)){
										TextCode.add("\%t" + varCount +  " = sext i16 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* @t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;									
									}
									else if( (theRHS.theKey == Key.LONG)){
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* @t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;	
									}
									else if( (theRHS.theKey == Key.LONG_LONG )){
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* @t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;	
									}
								} // if 
								else if (( theLHS.theKey == Key.SHORT )){
									if ( (theRHS.theKey == null ) )
										TextCode.add("\%t" + varCount +  " = trunc i32 \%t" + theRHS.theVar.varIndex + " to i16");
									else if( (theRHS.theKey == Key.LONG) )
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i16");
									else if( (theRHS.theKey == Key.LONG_LONG ))
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i16");
									TextCode.add("store i16 \%t" + varCount + ", i16* @t" + theLHS.theVar.varIndex + ", align 2");
									varCount++;
								} // else if 
								else if (( theLHS.theKey == Key.LONG ) || ( theLHS.theKey == Key.LONG_LONG )){
									if((theRHS.theKey == null))
										TextCode.add("\%t" + varCount +  " = sext i32 \%t" + theRHS.theVar.varIndex + " to i64");
									else if((theRHS.theKey == Key.SHORT))
										TextCode.add("\%t" + varCount +  " = sext i16 \%t" + theRHS.theVar.varIndex + " to i64");
									TextCode.add("store i64 \%t" + varCount + ", i64* @t" + theLHS.theVar.varIndex + ", align 8");
									varCount++;
								} // else if 
							}
						} // if
						else{
							// Ex: \%a = alloca i32, align 4
							if( (theLHS.theKey == Key.SHORT) && (theRHS.theKey == Key.SHORT) )
								TextCode.add("store i16 \%t" + theRHS.theVar.varIndex + ", i16* \%t" + theLHS.theVar.varIndex + ", align 2");
							else if( (theLHS.theKey == Key.LONG) && (theRHS.theKey == Key.LONG) )
								TextCode.add("store i64 \%t" + theRHS.theVar.varIndex + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else if( (theLHS.theKey == Key.LONG_LONG) && (theRHS.theKey == Key.LONG_LONG) )
								TextCode.add("store i64 \%t" + theRHS.theVar.varIndex + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else {
								if (( theLHS.theKey == null )){
									if (( theRHS.theKey == null ))
										TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
									else if((theRHS.theKey == Key.SHORT)){
										TextCode.add("\%t" + varCount +  " = sext i16 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;									
									}
									else if( (theRHS.theKey == Key.LONG)){
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;	
									}
									else if( (theRHS.theKey == Key.LONG_LONG )){
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i32");
										TextCode.add("store i32 \%t" + varCount + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");
										varCount++;	
									}
								} // if 
								else if (( theLHS.theKey == Key.SHORT )){
									if ( (theRHS.theKey == null ) )
										TextCode.add("\%t" + varCount +  " = trunc i32 \%t" + theRHS.theVar.varIndex + " to i16");
									else if( (theRHS.theKey == Key.LONG) )
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i16");
									else if( (theRHS.theKey == Key.LONG_LONG ))
										TextCode.add("\%t" + varCount +  " = trunc i64 \%t" + theRHS.theVar.varIndex + " to i16");
									TextCode.add("store i16 \%t" + varCount + ", i16* \%t" + theLHS.theVar.varIndex + ", align 2");
									varCount++;
								} // else if 
								else if (( theLHS.theKey == Key.LONG ) || ( theLHS.theKey == Key.LONG_LONG )){
									if((theRHS.theKey == null))
										TextCode.add("\%t" + varCount +  " = sext i32 \%t" + theRHS.theVar.varIndex + " to i64");
									else if((theRHS.theKey == Key.SHORT))
										TextCode.add("\%t" + varCount +  " = sext i16 \%t" + theRHS.theVar.varIndex + " to i64");
									TextCode.add("store i64 \%t" + varCount + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
									varCount++;
								} // else if 
							}
						} // else
					} // if
                    else if ((theLHS.theType == Type.INT) && (theRHS.theType == Type.CONST_INT)){
						if( theLHS.isGlobal ){
							if( (theLHS.theKey == Key.SHORT))
								TextCode.add("store i16 " + theRHS.theVar.iValue + ", i16* @t" + theLHS.theVar.varIndex + ", align 2");
							else if( (theLHS.theKey == Key.LONG))
								TextCode.add("store i64 \%t" + theRHS.theVar.iValue + ", i64* @t" + theLHS.theVar.varIndex + ", align 8");
							else if( (theLHS.theKey == Key.LONG_LONG))
								TextCode.add("store i64 \%t" + theRHS.theVar.iValue + ", i64* @t" + theLHS.theVar.varIndex + ", align 8");
							else
								TextCode.add("store i32 " + theRHS.theVar.iValue + ", i32* @t" + theLHS.theVar.varIndex + ", align 4");
						} //if
						else{
							if( (theLHS.theKey == Key.SHORT))
								TextCode.add("store i16 \%t" + theRHS.theVar.iValue + ", i16* \%t" + theLHS.theVar.varIndex + ", align 2");
							else if( (theLHS.theKey == Key.LONG))
								TextCode.add("store i64 \%t" + theRHS.theVar.iValue + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else if( (theLHS.theKey == Key.LONG_LONG))
								TextCode.add("store i64 \%t" + theRHS.theVar.iValue + ", i64* \%t" + theLHS.theVar.varIndex + ", align 8");
							else
								TextCode.add("store i32 " + theRHS.theVar.iValue + ", i32* \%t" + theLHS.theVar.varIndex + ", align 4");						
						}
					} // else if
                    else if ((theLHS.theType == Type.FLOAT) && (theRHS.theType == Type.FLOAT)) {
						if( theLHS.isGlobal )
							TextCode.add("store float \%t" + theRHS.theVar.varIndex + ", float* @t" + theLHS.theVar.varIndex + ", align 4");
						else
							TextCode.add("store float \%t" + theRHS.theVar.varIndex + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
                    } // else if
                    else if ((theLHS.theType == Type.FLOAT) && (theRHS.theType == Type.CONST_INT)) {
						String s = String.format("\%e", Double.valueOf(theRHS.theVar.iValue));
						if( theLHS.isGlobal )
							TextCode.add("store float " + s + ", float* @t" + theLHS.theVar.varIndex + ", align 4");
						else 
							TextCode.add("store float " + s + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
				   } // else if
					else if ((theLHS.theType == Type.FLOAT) && (theRHS.theType == Type.CONST_FLOAT)) {
						//System.out.println(theRHS.theVar.fValue);
						Float f = Float.parseFloat(theRHS.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						if ( theLHS.isGlobal )
							TextCode.add("store float " + s + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
						else	
							TextCode.add("store float " + s + ", float* @t" + theLHS.theVar.varIndex + ", align 4");
                    } // else if
                    else if ((theLHS.theType == Type.FLOAT) && (theRHS.theType == Type.DOUBLE)) {
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + theRHS.theVar.varIndex + " to float");
						if ( theLHS.isGlobal )
							TextCode.add("store float \%t" + varCount + ", float* @t" + theLHS.theVar.varIndex + ", align 4");
						else
							TextCode.add("store float \%t" + varCount + ", float* \%t" + theLHS.theVar.varIndex + ", align 4");
						varCount++;
                    } // else if
                    else if ((theLHS.theType == Type.DOUBLE) && (theRHS.theType == Type.FLOAT)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + theRHS.theVar.varIndex + " to double" );
						if ( theLHS.isGlobal )
							TextCode.add("store double \%t" + varCount + ", double* @t" + theLHS.theVar.varIndex + ", align 8");
						else
							TextCode.add("store double \%t" + varCount + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
						varCount++;
					} // else if
                    else if ((theLHS.theType == Type.DOUBLE) && (theRHS.theType == Type.DOUBLE)) {
						if ( theLHS.isGlobal )
							TextCode.add("store double \%t" + theRHS.theVar.varIndex + ", double* @t" + theLHS.theVar.varIndex + ", align 8");
						else
							TextCode.add("store double \%t" + theRHS.theVar.varIndex + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
                    } // else if
					else if ((theLHS.theType == Type.DOUBLE) && (theRHS.theType == Type.CONST_INT)) {
						String s = String.format("\%e", Double.valueOf(theRHS.theVar.iValue));
						if ( theLHS.isGlobal )
							TextCode.add("store double " + s + ", double* @t" + theLHS.theVar.varIndex + ", align 8");
						else
							TextCode.add("store double " + s + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
                    } // else if
					else if ((theLHS.theType == Type.DOUBLE) && (theRHS.theType == Type.CONST_FLOAT)) {
						Double dou = Double.parseDouble(theRHS.theVar.fValue);
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						if( theLHS.isGlobal )
							TextCode.add("store double " + s + ", double* @t" + theLHS.theVar.varIndex + ", align 8");
						else
							TextCode.add("store double " + s + ", double* \%t" + theLHS.theVar.varIndex + ", align 8");
                    } // else if
                    else if ((theLHS.theType == Type.CHAR) && (theRHS.theType == Type.CHAR)) {
						if( theLHS.isGlobal )
							TextCode.add("store i8 \%t" + theRHS.theVar.varIndex + ", i8* @t" + theLHS.theVar.varIndex + ", align 1");
						else
							TextCode.add("store i8 \%t" + theRHS.theVar.varIndex + ", i8* \%t" + theLHS.theVar.varIndex + ", align 1");
                    } // else if
                    else if ((theLHS.theType == Type.CHAR) && (theRHS.theType == Type.CONST_CHAR)) {
						if( theLHS.isGlobal )
							TextCode.add("store i8 " + theRHS.theVar.iValue + ", i8* @t" + theLHS.theVar.varIndex + ", align 1");
						else
							TextCode.add("store i8 " + theRHS.theVar.iValue + ", i8* \%t" + theLHS.theVar.varIndex + ", align 1");
                    } // else if
                 }
                 )
                 ;
			  
printf_func returns [Type attr_type]
					: PRINTF '(' STRING (','  a =logic_arith_expression (',' b =logic_arith_expression)?)? ')' ';' 
					{	//System.out.println($STRING.text);
						String str = $STRING.text;
						str = str.substring(1,str.length()-1); // delete ""
						String old = str;
						int count = 0;
						//System.out.println(str.length());
						int len = str.length();
						str = str.replaceFirst("\\\\n","\\\\0A");
						while( !str.equals(old) ){
							old = str;
							str = str.replaceFirst("\\\\n","\\\\0A");
							// System.out.println(old);
							count++;
						}
						//System.out.println(count);
						str = str.replaceFirst("\\\\r","\\\\0D");
						while( !str.equals(old) ){
							old = str;
							str = str.replaceFirst("\\\\r","\\\\0D");
							// System.out.println(old);
							count++;
						}
						//System.out.println(count);
						str = str.replaceFirst("\\\\t","\\\\09");
						while( !str.equals(old) ){
							old = str;
							str = str.replaceFirst("\\\\t","\\\\09");
							// System.out.println(old);
							count++;
						}
						str = str + "\\00";
						len -= (count-1);
						//System.out.println(len);
						//System.out.println(str);
						String temp = newStr();
						TextCode.add(1, "@" + temp + " = private unnamed_addr constant [" + Integer.toString(len) + " x i8] c\"" + str + "\"" );
						
						if($a.theInfo == null){
							//System.out.println(str);
							TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0))");
							varCount++;
						}
						else if($b.theInfo == null ){
							if($a.theInfo.theType == Type.INT){
								if($a.theInfo.theKey == Key.SHORT){
									TextCode.add("\%t" + varCount + " = sext i16 \%t" + $a.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t"+pre+")");			   
								}
								else if($a.theInfo.theKey == Key.LONG_LONG){
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64 \%t"+$a.theInfo.theVar.varIndex+")");			   
								}
								else if($a.theInfo.theKey == Key.LONG){
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64 \%t"+$a.theInfo.theVar.varIndex+")");			   
								}
								else TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t"+$a.theInfo.theVar.varIndex+")");			   
							}
							else if($a.theInfo.theType == Type.CONST_INT)
								TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 "+$a.theInfo.theVar.iValue+")");	
							else if($a.theInfo.theType == Type.FLOAT){
								TextCode.add( "\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int last = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + last + ")");
							}
							else if($a.theInfo.theType == Type.DOUBLE){
								TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + $a.theInfo.theVar.varIndex + ")");
							}
							else if($a.theInfo.theType == Type.CHAR){
								TextCode.add( "\%t" + varCount + " = sext i8 \%t" + $a.theInfo.theVar.varIndex + " to i32");
								int last = varCount;
								varCount++;			
								TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + last + ")");
							}
							else if($a.theInfo.theType == Type.CONST_FLOAT)
								TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double " + $a.theInfo.theVar.fValue + ")" );	
							else if($a.theInfo.theType == Type.CONST_CHAR)
								TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 " + $a.theInfo.theVar.iValue + ")" );	
							varCount++;
						} // else if
						else{
							if($a.theInfo.theType == Type.INT ){
								if( $b.theInfo.theType == Type.INT ){
									if($a.theInfo.theKey == Key.SHORT){
										TextCode.add("\%t" + varCount + " = sext i16 \%t" + $a.theInfo.theVar.varIndex + " to i32");
										int first = varCount;
										varCount++;
										if($b.theInfo.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
											int second = varCount;
											varCount++;
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + first + ", i32 \%t" + second + ")" );			   			   
										}
										else if($b.theInfo.theKey == Key.LONG_LONG ||$b.theInfo.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + first + ", i64 \%t"+$b.theInfo.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + first + ", i32 \%t"+$b.theInfo.theVar.varIndex+")");			   
									} // if
									else if($a.theInfo.theKey == Key.LONG_LONG||$a.theInfo.theKey == Key.LONG){		   
										if($b.theInfo.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
											int first = varCount;
											varCount++;
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64 \%t" + $a.theInfo.theVar.varIndex + ", i32 \%t" + first + ")" );			   			   
										}
										else if($b.theInfo.theKey == Key.LONG_LONG ||$b.theInfo.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64 \%t" + $a.theInfo.theVar.varIndex + ", i64 \%t"+$b.theInfo.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64 \%t" + $a.theInfo.theVar.varIndex + ", i32 \%t"+$b.theInfo.theVar.varIndex+")");			   
									} // else if
									else{
										if($b.theInfo.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
											int first = varCount;
											varCount++;
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.varIndex + ", i32 \%t" + first + ")" );			   			   
										}
										else if($b.theInfo.theKey == Key.LONG_LONG ||$b.theInfo.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.varIndex + ", i64 \%t"+$b.theInfo.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.varIndex + ", i32 \%t"+$b.theInfo.theVar.varIndex+")");			   
									}
								}
								else if ( $b.theInfo.theType == Type.CONST_INT )
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.varIndex + ", i32 "+$b.theInfo.theVar.iValue+")");		
								else if ( $b.theInfo.theType == Type.FLOAT ){
									TextCode.add( "\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
									int last = varCount;
									varCount ++;
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.varIndex + ", double \%t" + last + ")");								
								}
								else if ( $b.theInfo.theType == Type.DOUBLE ){
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.varIndex + ", double \%t" +  $b.theInfo.theVar.varIndex + ")");								
								}
								else if($b.theInfo.theType == Type.CHAR){
									TextCode.add( "\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int last = varCount;
									varCount++;			
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.varIndex + ", i32 \%t" + last + ")");
								}
								else if( $b.theInfo.theType == Type.CONST_FLOAT )
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.varIndex + ", double " + $b.theInfo.theVar.fValue + ")" );	
								else if( $b.theInfo.theType == Type.CONST_CHAR )  
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.varIndex + ", i32 " + $b.theInfo.theVar.iValue + ")" );	
								varCount++;
							}
							else if($a.theInfo.theType == Type.CONST_INT){
								if( $b.theInfo.theType == Type.INT ){
									if($b.theInfo.theKey == Key.SHORT){
										TextCode.add("\%t" + varCount + " = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int second = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.iValue + ", i32 \%t" + second + ")" );			   			   
									}
									else if($b.theInfo.theKey == Key.LONG_LONG ||$b.theInfo.theKey == Key.LONG )
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.iValue + ", i64 \%t"+$b.theInfo.theVar.varIndex+")");			   
									else	
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + $a.theInfo.theVar.iValue + ", i32 \%t"+$b.theInfo.theVar.varIndex+")");			   
								}
								else if( $b.theInfo.theType == Type.CONST_INT )
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0),i32 " + $a.theInfo.theVar.iValue + ", i32 "+$b.theInfo.theVar.iValue+")");			   	   			
								else if ( $b.theInfo.theType == Type.FLOAT ){
									TextCode.add( "\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
									int last = varCount;
									varCount ++;
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 " + $a.theInfo.theVar.iValue + ", double \%t" + last + ")");								
								}
								else if ( $b.theInfo.theType == Type.DOUBLE ){
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 " + $a.theInfo.theVar.iValue + ", double \%t" +  $b.theInfo.theVar.varIndex + ")");								
								}
								else if($b.theInfo.theType == Type.CHAR){
									TextCode.add( "\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int last = varCount;
									varCount++;			
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 " + $a.theInfo.theVar.iValue + ", i32 \%t" + last + ")");
								}
								else if( $b.theInfo.theType == Type.CONST_FLOAT )
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 " + $a.theInfo.theVar.iValue + ", double " + $b.theInfo.theVar.fValue + ")" );	
								else if( $b.theInfo.theType == Type.CONST_CHAR )  
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 " + $a.theInfo.theVar.iValue + ", i32 " + $b.theInfo.theVar.iValue + ")" );
								varCount++;	
							}
							else if($a.theInfo.theType == Type.FLOAT){
								TextCode.add( "\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int first = varCount;
								varCount ++;
								if( $b.theInfo.theType == Type.INT ){
									if($b.theInfo.theKey == Key.SHORT){
										TextCode.add("\%t" + varCount + " = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int second = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + first + ", i32 \%t" + second + ")" );			   			   
									}
									else if($b.theInfo.theKey == Key.LONG_LONG ||$b.theInfo.theKey == Key.LONG )
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + first + ", i64 \%t"+$b.theInfo.theVar.varIndex+")");			   
									else	
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + first + ", i32 \%t"+$b.theInfo.theVar.varIndex+")");			   
								}//if
								else if( $b.theInfo.theType == Type.CONST_INT )
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + first + ", i32 "+$b.theInfo.theVar.iValue+")");			   	   			
								else if ( $b.theInfo.theType == Type.FLOAT ){
									TextCode.add( "\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
									int last = varCount;
									varCount++;
									TextCode.add( "\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + first + ", double \%t" + last + ")");									
								}
								else if ( $b.theInfo.theType == Type.DOUBLE ){
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + first + ", double \%t" +  $b.theInfo.theVar.varIndex + ")");								
								}
								else if($b.theInfo.theType == Type.CHAR){
									TextCode.add( "\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int last = varCount;
									varCount++;			
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + first + ", i32 \%t" + last + ")");
								}
								else if( $b.theInfo.theType == Type.CONST_FLOAT )
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + first + ", double " + $b.theInfo.theVar.fValue + ")" );	
								else if( $b.theInfo.theType == Type.CONST_CHAR )  
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + first + ", i32 " + $b.theInfo.theVar.iValue + ")" );
								varCount++;
							}
							else if($a.theInfo.theType == Type.DOUBLE){
								if( $b.theInfo.theType == Type.INT ){
									if($b.theInfo.theKey == Key.SHORT){
										TextCode.add("\%t" + varCount + " = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int second = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + $a.theInfo.theVar.varIndex + ", i32 \%t" + second + ")" );			   			   
									}
									else if($b.theInfo.theKey == Key.LONG_LONG ||$b.theInfo.theKey == Key.LONG )
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + $a.theInfo.theVar.varIndex + ", i64 \%t"+$b.theInfo.theVar.varIndex+")");			   
									else	
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + $a.theInfo.theVar.varIndex + ", i32 \%t"+$b.theInfo.theVar.varIndex+")");			   
								}//if
								else if( $b.theInfo.theType == Type.CONST_INT )
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + $a.theInfo.theVar.varIndex + ", i32 "+$b.theInfo.theVar.iValue+")");			   	   			
								else if ( $b.theInfo.theType == Type.FLOAT ){
									TextCode.add( "\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
									int last = varCount;
									varCount++;			
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + $a.theInfo.theVar.varIndex + ", double \%t" + last + ")");								
								}
								else if ( $b.theInfo.theType == Type.DOUBLE ){
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + $a.theInfo.theVar.varIndex + ", double \%t" +  $b.theInfo.theVar.varIndex + ")");								
								}
								else if($b.theInfo.theType == Type.CHAR){
									TextCode.add( "\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int last = varCount;
									varCount++;			
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + $a.theInfo.theVar.varIndex + ", i32 \%t" + last + ")");
								}
								else if( $b.theInfo.theType == Type.CONST_FLOAT )
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + $a.theInfo.theVar.varIndex + ", double " + $b.theInfo.theVar.fValue + ")" );	
								else if( $b.theInfo.theType == Type.CONST_CHAR )  
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double \%t" + $a.theInfo.theVar.varIndex + ", i32 " + $b.theInfo.theVar.iValue + ")" );
								varCount++;
							}
							else if($a.theInfo.theType == Type.CHAR){
								TextCode.add( "\%t" + varCount + " = sext i8 \%t" + $a.theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount ++;
								if( $b.theInfo.theType == Type.INT ){
									if($b.theInfo.theKey == Key.SHORT){
										TextCode.add("\%t" + varCount + " = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int second = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + first + ", i32 \%t" + second + ")" );			   			   
									}
									else if($b.theInfo.theKey == Key.LONG_LONG ||$b.theInfo.theKey == Key.LONG )
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + first + ", i64 \%t"+$b.theInfo.theVar.varIndex+")");			   
									else	
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" + first + ", i32 \%t"+$b.theInfo.theVar.varIndex+")");			   
								}//if
								else if( $b.theInfo.theType == Type.CONST_INT )
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" +  first + ",i32 "+$b.theInfo.theVar.iValue+")");			   	   			
								else if ( $b.theInfo.theType == Type.FLOAT ){
									TextCode.add( "\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
									int last = varCount;
									varCount++;
									TextCode.add( "\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" +  first + ", double \%t" + last + ")");									
								}
								else if ( $b.theInfo.theType == Type.DOUBLE ){
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" +  first + ", double \%t" +  $b.theInfo.theVar.varIndex + ")");								
								}
								else if($b.theInfo.theType == Type.CHAR){
									TextCode.add( "\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int last = varCount;
									varCount++;			
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" +  first + ", i32 \%t" + last + ")");
								}
								else if( $b.theInfo.theType == Type.CONST_FLOAT )
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" +  first + ", double " + $b.theInfo.theVar.fValue + ")" );	
								else if( $b.theInfo.theType == Type.CONST_CHAR )  
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @printf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32 \%t" +  first + ", i32 " + $b.theInfo.theVar.iValue + ")" );
								varCount++;
							}							
						}
							
					}
					;
					
					
scanf_func returns [Type attr_type]
					: SCANF '(' STRING (',' '&' a =Identifier (',' '&' b =Identifier)?)? ')' ';' 
					{	
						String id = $a.text + Integer.toString(scope);
						Info t = symtab.get(id);
						int cur = scope;
						while( t == null ){
							cur = cur - 1;
							if( cur < 0 ){
								System.out.println("Error! " + $a.getLine() + ": Undefined identifier."+ "( identifier:" +$a.text +" )");
								System.exit(0);
							} // if
							id = $a.text + Integer.toString(cur);
							t = symtab.get(id);
							if(t != null) break;
						} // while
						
						Info tfirst = symtab.get(id);
						boolean isglobal1 = symtab.get(id).isGlobal;
						
						//System.out.println($STRING.text);
						String str = $STRING.text;
						str = str.substring(1,str.length()-1); // delete ""
						String old = str;
						int count = 0;
						//System.out.println(str.length());
						int len = str.length();
						str = str.replaceFirst("\\\\n","\\\\0A");
						while( !str.equals(old) ){
							old = str;
							str = str.replaceFirst("\\\\n","\\\\0A");
							// System.out.println(old);
							count++;
						}
						//System.out.println(count);
						str = str.replaceFirst("\\\\r","\\\\0D");
						while( !str.equals(old) ){
							old = str;
							str = str.replaceFirst("\\\\r","\\\\0D");
							// System.out.println(old);
							count++;
						}
						//System.out.println(count);
						str = str.replaceFirst("\\\\t","\\\\09");
						while( !str.equals(old) ){
							old = str;
							str = str.replaceFirst("\\\\t","\\\\09");
							// System.out.println(old);
							count++;
						}
						str = str + "\\00";
						len -= (count-1);
						//System.out.println(len);
						//System.out.println(str);
						String temp = newStr();
						TextCode.add(1, "@" + temp + " = private unnamed_addr constant [" + Integer.toString(len) + " x i8] c\"" + str + "\"" );
						
						if( b == null ){
							if( isglobal1 ){
								if(tfirst.theType == Type.INT){
									if( tfirst.theKey == Key.SHORT){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* @t" + tfirst.theVar.varIndex +")");			   
									}
									else if(tfirst.theKey == Key.LONG_LONG){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* @t"+tfirst.theVar.varIndex+")");			   
									}
									else if(tfirst.theKey == Key.LONG){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* @t"+tfirst.theVar.varIndex+")");			   
									}
									else
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t"+tfirst.theVar.varIndex+")");			   
								}
								else if(tfirst.theType == Type.FLOAT){
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ")");
								}
								else if(tfirst.theType == Type.DOUBLE){
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ")");
								}
								else if(tfirst.theType == Type.CHAR){			
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" + tfirst.theVar.varIndex + ")");
								}
							} // if
							else{ // not global
								if(tfirst.theType == Type.INT){
									if( tfirst.theKey == Key.SHORT){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* \%t" + tfirst.theVar.varIndex + ")");			   
									}
									else if(tfirst.theKey == Key.LONG_LONG){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* \%t"+tfirst.theVar.varIndex+")");			   
									}
									else if(tfirst.theKey == Key.LONG){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* \%t"+tfirst.theVar.varIndex+")");			   
									}
									else
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t"+tfirst.theVar.varIndex+")");			   
								}
								else if(tfirst.theType == Type.FLOAT){
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ")");
								}
								else if(tfirst.theType == Type.DOUBLE){
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ")");
								}
								else if(tfirst.theType == Type.CHAR){			
									TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" + tfirst.theVar.varIndex + ")");
								}
								varCount++;
							} // else
						}
						else if ( b != null ){
						
							String id2 = $b.text + Integer.toString(scope);
							Info t1 = symtab.get(id2);
							int cur1 = scope;
							while( t1 == null ){
								cur1 = cur1 - 1;
								if( cur1 < 0 ){
									System.out.println("Error! " + $b.getLine() + ": Undefined identifier."+ "( identifier:" +$b.text +" )");
									System.exit(0);
								} // if
								id2 = $b.text + Integer.toString(cur1);
								t1 = symtab.get(id2);
								if(t1 != null) break;
							} // while
							
							Info tsecond = symtab.get(id2);
							boolean isglobal2 = symtab.get(id2).isGlobal;
							if( isglobal1 && !isglobal2 ){
								if( tfirst.theType == Type.INT ){
									if( tsecond.theType == Type.INT ){
										if(tfirst.theKey == Key.SHORT){
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* @t" + tfirst.theVar.varIndex + ", i16* \%t" + tsecond.theVar.varIndex  + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* @t" + tfirst.theVar.varIndex + ", i64* \%t" + tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* @t" + tfirst.theVar.varIndex + ", i32* \%t" + tsecond.theVar.varIndex+")");			   
										} // if
										else if(tfirst.theKey == Key.LONG_LONG||tfirst.theKey == Key.LONG){		   
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* @t" + tfirst.theVar.varIndex + ", i16* \%t" + tsecond.theVar.varIndex + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* @t" + tfirst.theVar.varIndex + ", i64* \%t" + tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* @t" + tfirst.theVar.varIndex + ", i32* \%t" + tsecond.theVar.varIndex+")");			   
										} // else if
										else{
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", i16* \%t" + tsecond.theVar.varIndex + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", i64* \%t" + tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", i32* \%t" + tsecond.theVar.varIndex+")");			   
										}
									}
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", float* \%t" + tsecond.theVar.varIndex + ")");								
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", double* \%t" + tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){	
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", i8* \%t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if(tfirst.theType == Type.FLOAT){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", i16* \%t" + tsecond.theVar.varIndex + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", i64* \%t" + tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", i32* \%t" + tsecond.theVar.varIndex+")");			   
									}	
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add( "\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", float* \%t" + tsecond.theVar.varIndex + ")");									
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", double* \%t" + tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){			
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", i8* \%t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if( tfirst.theType == Type.DOUBLE){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", i16* \%t" + tsecond.theVar.varIndex  + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", i64* \%t" + tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", i32* \%t" + tsecond.theVar.varIndex+")");
									}
									else if ( tsecond.theType == Type.FLOAT ){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", float* \%t" + tsecond.theVar.varIndex + ")");								
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", double* \%t" + tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", i8* \%t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if(tfirst.theType == Type.CHAR){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" + tfirst.theVar.varIndex + ", i16* \%t" + tsecond.theVar.varIndex + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" + tfirst.theVar.varIndex + ", i64* \%t" + tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" + tfirst.theVar.varIndex + ", i32* \%t" + tsecond.theVar.varIndex+")");
									}
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add( "\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" + tfirst.theVar.varIndex + ", float* \%t" + tsecond.theVar.varIndex + ")");									
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" + tfirst.theVar.varIndex + ", double* \%t" + tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" + tfirst.theVar.varIndex + ", i8* \%t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
							} // if
							else if ( !isglobal1 && isglobal2 ){
								if( tfirst.theType == Type.INT ){
									if( tsecond.theType == Type.INT ){
										if(tfirst.theKey == Key.SHORT){
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* \%t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex  + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* \%t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* \%t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");			   
										} // if
										else if(tfirst.theKey == Key.LONG_LONG||tfirst.theKey == Key.LONG){		   
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* \%t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* \%t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* \%t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");			   
										} // else if
										else{
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");			   
										}
									}
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", float* @t" +  tsecond.theVar.varIndex + ")");								
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", double* @t" + tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){	
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", i8* @t" +  tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if(tfirst.theType == Type.FLOAT){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");			   
									}	
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add( "\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", float* @t" + tsecond.theVar.varIndex + ")");									
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", double* @t" +  tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){			
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", i8* @t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if( tfirst.theType == Type.DOUBLE){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");
									}
									else if ( tsecond.theType == Type.FLOAT ){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", float* @t" + tsecond.theVar.varIndex + ")");								
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", double* @t" +  tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", i8* @t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if(tfirst.theType == Type.CHAR){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");
									}
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add( "\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" + tfirst.theVar.varIndex + ", float* @t" + tsecond.theVar.varIndex + ")");									
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" + tfirst.theVar.varIndex + ", double* @t" +  tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" + tfirst.theVar.varIndex + ", i8* @t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
							} // else if
							else if ( isglobal1 && isglobal2 ){
								if( tfirst.theType == Type.INT ){
									if( tsecond.theType == Type.INT ){
										if(tfirst.theKey == Key.SHORT){
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* @t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* @t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* @t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");			   
										} // if
										else if(tfirst.theKey == Key.LONG_LONG||tfirst.theKey == Key.LONG){		   
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* @t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* @t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* @t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");			   
										} // else if
										else{
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");			   
										}
									}
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", float* @t" +  tsecond.theVar.varIndex + ")");								
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", double* @t" + tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){	
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* @t" + tfirst.theVar.varIndex + ", i8* @t" +  tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if(tfirst.theType == Type.FLOAT){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");			   
									}	
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add( "\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", float* @t" + tsecond.theVar.varIndex + ")");									
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", double* @t" +  tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){			
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* @t" + tfirst.theVar.varIndex + ", i8* @t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if( tfirst.theType == Type.DOUBLE){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");
									}
									else if ( tsecond.theType == Type.FLOAT ){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", float* @t" + tsecond.theVar.varIndex + ")");								
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", double* @t" +  tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* @t" + tfirst.theVar.varIndex + ", i8* @t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if(tfirst.theType == Type.CHAR){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" + tfirst.theVar.varIndex + ", i16* @t" + tsecond.theVar.varIndex + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" + tfirst.theVar.varIndex + ", i64* @t"+tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" + tfirst.theVar.varIndex + ", i32* @t"+tsecond.theVar.varIndex+")");
									}
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add( "\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" +  tfirst.theVar.varIndex + ", float* @t" + tsecond.theVar.varIndex + ")");									
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" +  tfirst.theVar.varIndex + ", double* @t" +  tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* @t" +  tfirst.theVar.varIndex + ", i8* @t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
							}
							else{
								if( tfirst.theType == Type.INT ){
									if( tsecond.theType == Type.INT ){
										if(tfirst.theKey == Key.SHORT){
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* \%t" + tfirst.theVar.varIndex+ ", i16* \%t" + tsecond.theVar.varIndex + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* \%t" + tfirst.theVar.varIndex + ", i64* \%t"+tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i16* \%t" + tfirst.theVar.varIndex + ", i32* \%t"+tsecond.theVar.varIndex+")");			   
										} // if
										else if(tfirst.theKey == Key.LONG_LONG||tfirst.theKey == Key.LONG){		   
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* \%t" + tfirst.theVar.varIndex + ", i16* \%t" + tsecond.theVar.varIndex + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* \%t" + tfirst.theVar.varIndex + ", i64* \%t"+tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i64* \%t" + tfirst.theVar.varIndex + ", i32* \%t"+tsecond.theVar.varIndex+")");			   
										} // else if
										else{
											if(tsecond.theKey == Key.SHORT){
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", i16* \%t" + tsecond.theVar.varIndex + ")" );			   			   
											}
											else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", i64* \%t"+tsecond.theVar.varIndex+")");			   
											else	
												TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", i32* \%t"+tsecond.theVar.varIndex+")");			   
										}
									}
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", float* \%t" +  tsecond.theVar.varIndex + ")");								
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", double* \%t" + tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){	
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i32* \%t" + tfirst.theVar.varIndex + ", i8* \%t" +  tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if(tfirst.theType == Type.FLOAT){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", i16* \%t" + tsecond.theVar.varIndex + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", i64* \%t"+tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", i32* \%t"+tsecond.theVar.varIndex+")");			   
									}	
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add( "\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", float* \%t" + tsecond.theVar.varIndex + ")");									
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", double* \%t" +  tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){			
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), float* \%t" + tfirst.theVar.varIndex + ", i8* \%t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if( tfirst.theType == Type.DOUBLE){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", i16* \%t" + tsecond.theVar.varIndex + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", i64* \%t"+tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", i32* \%t"+tsecond.theVar.varIndex+")");
									}
									else if ( tsecond.theType == Type.FLOAT ){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", float* \%t" + tsecond.theVar.varIndex + ")");								
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", double* \%t" +  tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), double* \%t" + tfirst.theVar.varIndex + ", i8* \%t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
								else if(tfirst.theType == Type.CHAR){
									if ( tsecond.theType == Type.INT ){
										if(tsecond.theKey == Key.SHORT){
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" + tfirst.theVar.varIndex + ", i16* \%t" + tsecond.theVar.varIndex + ")" );			   			   
										}
										else if(tsecond.theKey == Key.LONG_LONG ||tsecond.theKey == Key.LONG )
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" + tfirst.theVar.varIndex + ", i64* \%t"+tsecond.theVar.varIndex+")");			   
										else	
											TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" + tfirst.theVar.varIndex + ", i32* \%t"+tsecond.theVar.varIndex+")");
									}
									else if ( tsecond.theType == Type.FLOAT ){
										TextCode.add( "\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" +  tfirst.theVar.varIndex + ", float* \%t" + tsecond.theVar.varIndex + ")");									
									}
									else if ( tsecond.theType == Type.DOUBLE ){
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" +  tfirst.theVar.varIndex + ", double* \%t" +  tsecond.theVar.varIndex + ")");								
									}
									else if(tsecond.theType == Type.CHAR){		
										TextCode.add("\%t" + varCount + " = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds (["+Integer.toString(len)+" x i8], [" + Integer.toString(len) + " x i8]* @"+temp+", i64 0, i64 0), i8* \%t" +  tfirst.theVar.varIndex + ", i8* \%t" + tsecond.theVar.varIndex + ")");
									}
									varCount++;
								}
							}
							
						}
					}
						
					;
     
// case_stmt
case_stmt : declarations ';'
          | assign_statement ';'
          | printf_func
          | scanf_func
		  |
          ;


// for_stmt
for_stmt: FOR '(' 
		 { scope = scope+1;
		   String startlabel = newLabel();
		   String for_cond = newLabel();
		   String body = newLabel();
		   String latch = newLabel();
		   String exitL = newLabel();
		   ForL.add(exitL); // 4
		   ForL.add(latch); // 3
		   ForL.add(body); // 2
		   ForL.add(for_cond); // 1
		   TextCode.add("br label \%" + startlabel);
		   TextCode.add(startlabel + ":" ); // entry
		 }
		 (a=assign_statement|declarations)';'
		 {
		   TextCode.add("br label \%" + ForL.get(ForL.size()-1));
		   TextCode.add(ForL.get(ForL.size()-1) + ":" ); // for cond
		 }
		 c=logic_arith_expression ';'
		 { 
		   if( $logic_arith_expression.theInfo.theType != Type.BOOL ) {  
				System.out.println("Error! " + $FOR.getLine() + ": condition type not boolean"); 
				System.exit(0);
	       }
		   TextCode.add("br i1 \%t" + $c.theInfo.theVar.varIndex  + ", label \%" + ForL.get(ForL.size()-2) + ", label \%"+ ForL.get(ForL.size()-4) ); 
		   TextCode.add(ForL.get(ForL.size()-3) + ":" ); // latch
		   
		 }
		 b=assign_statement 
		 {
		   TextCode.add("br label \%" + ForL.get(ForL.size()-1));
		   TextCode.add(ForL.get(ForL.size()-2) + ":"); // body
		 }
		 ')'
		 block_for_stmt
		 { TextCode.add("br label \%" + ForL.get(ForL.size()-3));
		   TextCode.add(ForL.get(ForL.size()-4) + ":");
		   ForL.remove(ForL.size()-1);
		   ForL.remove(ForL.size()-1);
		   ForL.remove(ForL.size()-1);
		   ForL.remove(ForL.size()-1);
		 }
		 ;	  		 
	   
// while_stmt
while_stmt: WHILE '('
         { scope = scope+1;
           String startlabel = newLabel();
           String body = newLabel();
           String exitL = newLabel();
           WhileL.add(exitL); // 3
           WhileL.add(body); // 2
           WhileL.add(startlabel); // 1
           TextCode.add("br label \%" + startlabel);
           TextCode.add(startlabel + ":" ); // entry
         }
         a = logic_arith_expression
         {
           if( $logic_arith_expression.theInfo.theType != Type.BOOL ) {
                System.out.println("Error! " + $WHILE.getLine() + ": condition type not boolean");
                System.exit(0);
           }
           TextCode.add("br i1 \%t" + $a.theInfo.theVar.varIndex  + ", label \%" + WhileL.get(WhileL.size()-2) + ", label \%"+ WhileL.get(WhileL.size()-3) );
           TextCode.add(WhileL.get(WhileL.size()-2) + ":" );
         }
         ')'
         block_for_stmt
         {
            TextCode.add("br label \%" + WhileL.get(WhileL.size()-1));
            TextCode.add(WhileL.get(WhileL.size()-3) + ":");
            WhileL.remove(WhileL.size()-1);
            WhileL.remove(WhileL.size()-1);
            WhileL.remove(WhileL.size()-1);
         }
         ;
    
// switch_stmt
switch_stmt: SWITCH '(' a=logic_arith_expression ')' '{'
				( 	CASE constant ':'
					{	String tmp = newLabel();
						if ($constant.theInfo.theType == Type.CONST_INT )
							CaseT.add( " i32 " + $constant.theInfo.theVar.iValue + ", label \%" + tmp) ;
						if ($constant.theInfo.theType == Type.CONST_CHAR )
							CaseT.add( " i32 " + $constant.theInfo.theVar.iValue + ", label \%" + tmp) ;
						if ($constant.theInfo.theType == Type.CONST_FLOAT ){
							Float f = Float.parseFloat($constant.theInfo.theVar.fValue);
							double dou = (double) f;
							long bits = Double.doubleToLongBits(dou);
							String s = String.format("\%16s", Long.toHexString(bits));
							s = s.toUpperCase();
							s = "0x" + s ;
							CaseT.add( " double " + s + ", label \%" + tmp) ;
						}  
						
						TextCode.add(tmp + ":");
						if(curLabel == null){
							curLabel = new String(tmp + ":");
							tmp = newLabel();
							CaseL.add(tmp);
						} // if
					}
						case_stmt
						BREAK ';'
						{
							TextCode.add("br label \%" + CaseL.get(CaseL.size()-1));	
						}
					 )+
					DEFAULT ':'
						{	String tmp = newLabel();
							CaseL.add(tmp);
							TextCode.add(tmp + ":");
						}
						case_stmt
						BREAK ';'
						{ TextCode.add("br label \%" + CaseL.get(CaseL.size()-2));}
			 '}'
			 {
				int cur = TextCode.indexOf(curLabel);
				TextCode.add( cur,"switch i32 \%t" + $a.theInfo.theVar.varIndex + ", label \%" + CaseL.get(CaseL.size()-1) + "[" );
				cur++;
				for(int i =0; i < CaseT.size() ; i++,cur++ ){
					
					TextCode.add( cur ,CaseT.get( i ));
				} 
				TextCode.add(cur,"]");
				TextCode.add(CaseL.get(CaseL.size()-2) + ":");
				CaseL.clear();
				CaseT.clear();
			 }
			 ;


if_else_stmt : IF '(' a=logic_arith_expression ')'
			   { if( $logic_arith_expression.theInfo.theType != Type.BOOL ) {  
					System.out.println("Error! " + $IF.getLine() + ": condition type not boolean"); 
					System.exit(0);
				 }
				 String truelabel = newLabel();
			     String elselabel = newLabel();
				 String endlabel = newLabel();
				 ElseL.add(elselabel);
				 EndL.add(endlabel);
				 TextCode.add("br i1 \%t" + $a.theInfo.theVar.varIndex  + ", label \%" + truelabel + ", label \%"+ elselabel );
			     TextCode.add(truelabel + ":");
			   }
			   block_stmt
			   { String endlabel = EndL.get(EndL.size()-1);
				 TextCode.add("br label \%" + endlabel);
			   }
			   ((ELSE) => ELSE
			   { String elselabel = ElseL.get(ElseL.size()-1);
			     TextCode.add(elselabel + ":");
				 ElseL.remove(ElseL.size()-1);				 
			   }
			   block_stmt
			   { String endlabel = EndL.get(EndL.size() -1 );
				 TextCode.add("br label \%" + endlabel);
			   }
			   | 
			   { String elselabel = ElseL.get(ElseL.size()-1);
			     TextCode.add(elselabel + ":");
				 ElseL.remove(ElseL.size()-1);
				 String endlabel = EndL.get(EndL.size() -1 );
				 TextCode.add("br label \%" + endlabel);
			   }
			   )
			   { String endlabel = EndL.get(EndL.size()-1);
			     TextCode.add(endlabel + ":");
				 EndL.remove(EndL.size()-1);
			   }
			   ;


				  
block_stmt: {scope = scope+1 ;} ( '{' statements '}' | statement ){scope = scope-1;}
	  ;

block_for_stmt: ( '{' statements '}' | statement ) { scope = scope-1;}
	  ;
		   
func_no_return_stmt: Identifier '(' argument ')'
                   ;


argument: arg (',' arg)*
        ;

arg: arith_expression
   | STRING
   ;
			   

// logic_arith_expression
logic_arith_expression returns [Info theInfo]
@init {theInfo = new Info();}
				: a = arith_expression {$theInfo = $a.theInfo;}
				( EQ b = arith_expression 
				 {		if (($a.theInfo.theType == Type.INT)){
							if (($b.theInfo.theType == Type.INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre2=varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + pre + ", \%t" + pre2);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp eq i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
									}
								} // if 
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp eq i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount + " = icmp eq i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp eq i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
									}
								} // else if
								else if( $a.theInfo.theKey == null ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp eq i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
									} //else
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
								} // if
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp eq i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								} // else if
								else {
									TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							} // else if
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + pre  + ", \%t" + pre1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + pre  + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + pre  + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // if
						else if (($a.theInfo.theType == Type.CONST_INT)){
							if (($b.theInfo.theType == Type.INT)){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp eq i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp eq i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount + " = icmp eq i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
								}
					
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = icmp eq i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int first = varCount;
								varCount++;
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp oeq double " + s + ", \%t" + first);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp oeq double " + s + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp oeq double " + s + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if 
						else if (($a.theInfo.theType == Type.FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fcmp oeq float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								Double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + first + ", " + s);
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + pre1 + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + pre + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CONST_FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oeq float " + s + ", \%t" + varCount);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp oeq double " + s + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp oeq double " + s + ", " + s1);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oeq double " + s + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								Float f1 = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp oeq double " + s1 + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.DOUBLE)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + $theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp oeq double \%t" + $a.theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CHAR)){
							if (($b.theInfo.theType == Type.CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int second = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + first + ", \%t" + second );
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + first + ", " + $b.theInfo.theVar.iValue);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if			
				 } 
				| LESS b = arith_expression
				 {		if (($a.theInfo.theType == Type.INT)){
							if (($b.theInfo.theType == Type.INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre2=varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + pre + ", \%t" + pre2);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp slt i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
									}
								} // if 
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp slt i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount + " = icmp slt i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp slt i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
									}
								} // else if
								else if( $a.theInfo.theKey == null ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp slt i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
									} //else
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
								} // if
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp slt i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								} // else if
								else {
									TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							} // else if
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + pre  + ", \%t" + pre1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + pre  + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + pre  + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // if
						else if (($a.theInfo.theType == Type.CONST_INT)){
							if (($b.theInfo.theType == Type.INT)){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp slt i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp slt i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount + " = icmp slt i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
								}
					
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = icmp slt i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int first = varCount;
								varCount++;
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp olt double " + s + ", \%t" + first);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp olt double " + s + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp olt double " + s + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if 
						else if (($a.theInfo.theType == Type.FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fcmp olt float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								Double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + first + ", " + s);
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + pre1 + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + pre + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CONST_FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp olt float " + s + ", \%t" + varCount);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp olt double " + s + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp olt double " + s + ", " + s1);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp olt double " + s + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								Float f1 = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp olt double " + s1 + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.DOUBLE)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + $theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp olt double \%t" + $a.theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CHAR)){
							if (($b.theInfo.theType == Type.CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int second = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + first + ", \%t" + second );
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + first + ", " + $b.theInfo.theVar.iValue);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
				 }
				| GREATER b = arith_expression
				 {		if (($a.theInfo.theType == Type.INT)){
							if (($b.theInfo.theType == Type.INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre2=varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + pre + ", \%t" + pre2);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sgt i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
									}
								} // if 
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sgt i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount + " = icmp sgt i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sgt i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
									}
								} // else if
								else if( $a.theInfo.theKey == null ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sgt i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
									} //else
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
								} // if
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp sgt i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								} // else if
								else {
									TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							} // else if
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + pre  + ", \%t" + pre1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + pre  + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + pre  + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // if
						else if (($a.theInfo.theType == Type.CONST_INT)){
							if (($b.theInfo.theType == Type.INT)){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp sgt i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp sgt i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount + " = icmp sgt i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
								}
					
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = icmp sgt i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int first = varCount;
								varCount++;
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp ogt double " + s + ", \%t" + first);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp ogt double " + s + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp ogt double " + s + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if 
						else if (($a.theInfo.theType == Type.FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fcmp ogt float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								Double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + first + ", " + s);
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + pre1 + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + pre + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CONST_FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ogt float " + s + ", \%t" + varCount);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp ogt double " + s + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp ogt double " + s + ", " + s1);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ogt double " + s + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								Float f1 = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp ogt double " + s1 + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.DOUBLE)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + $theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp ogt double \%t" + $a.theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CHAR)){
							if (($b.theInfo.theType == Type.CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int second = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + first + ", \%t" + second );
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + first + ", " + $b.theInfo.theVar.iValue);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if		
				 }
				| LE b = arith_expression
				 {		if (($a.theInfo.theType == Type.INT)){
							if (($b.theInfo.theType == Type.INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre2=varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + pre + ", \%t" + pre2);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sle i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
									}
								} // if 
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sle i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount + " = icmp sle i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sle i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
									}
								} // else if
								else if( $a.theInfo.theKey == null ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sle i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
									} //else
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
								} // if
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp sle i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								} // else if
								else {
									TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							} // else if
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + pre  + ", \%t" + pre1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + pre  + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + pre  + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // if
						else if (($a.theInfo.theType == Type.CONST_INT)){
							if (($b.theInfo.theType == Type.INT)){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp sle i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp sle i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount + " = icmp sle i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
								}
					
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = icmp sle i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int first = varCount;
								varCount++;
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp ole double " + s + ", \%t" + first);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp ole double " + s + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp ole double " + s + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if 
						else if (($a.theInfo.theType == Type.FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fcmp ole float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								Double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + first + ", " + s);
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + pre1 + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + pre + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CONST_FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ole float " + s + ", \%t" + varCount);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp ole double " + s + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp ole double " + s + ", " + s1);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ole double " + s + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								Float f1 = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp ole double " + s1 + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.DOUBLE)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + $theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp ole double \%t" + $a.theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CHAR)){
							if (($b.theInfo.theType == Type.CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int second = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + first + ", \%t" + second );
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + first + ", " + $b.theInfo.theVar.iValue);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if		
				 }
				| GE b = arith_expression
				 {		if (($a.theInfo.theType == Type.INT)){
							if (($b.theInfo.theType == Type.INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre2=varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + pre + ", \%t" + pre2);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sge i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
									}
								} // if 
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sge i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount + " = icmp sge i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sge i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
									}
								} // else if
								else if( $a.theInfo.theKey == null ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp sge i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
									} //else
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
								} // if
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp sge i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								} // else if
								else {
									TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							} // else if
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + pre  + ", \%t" + pre1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + pre  + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + pre  + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // if
						else if (($a.theInfo.theType == Type.CONST_INT)){
							if (($b.theInfo.theType == Type.INT)){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp sge i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp sge i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount + " = icmp sge i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
								}
					
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = icmp sge i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int first = varCount;
								varCount++;
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp oge double " + s + ", \%t" + first);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp oge double " + s + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp oge double " + s + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if 
						else if (($a.theInfo.theType == Type.FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fcmp oge float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								Double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + first + ", " + s);
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + pre1 + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + pre + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CONST_FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oge float " + s + ", \%t" + varCount);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp oge double " + s + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp oge double " + s + ", " + s1);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oge double " + s + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								Float f1 = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp oge double " + s1 + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.DOUBLE)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + $theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp oge double \%t" + $a.theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CHAR)){
							if (($b.theInfo.theType == Type.CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int second = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + first + ", \%t" + second );
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + first + ", " + $b.theInfo.theVar.iValue);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
				 }
				| NE b = arith_expression
				 {		if (($a.theInfo.theType == Type.INT)){
							if (($b.theInfo.theType == Type.INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre2=varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + pre + ", \%t" + pre2);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp ne i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
									}
								} // if 
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp ne i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount + " = icmp ne i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp ne i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
									}
								} // else if
								else if( $a.theInfo.theKey == null ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = icmp ne i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									}
									else{
										TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
									} //else
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
								} // if
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp ne i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								} // else if
								else {
									TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							} // else if
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + pre  + ", \%t" + pre1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + pre  + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + pre  + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // if
						else if (($a.theInfo.theType == Type.CONST_INT)){
							if (($b.theInfo.theType == Type.INT)){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = icmp ne i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = icmp ne i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount + " = icmp ne i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
								}
					
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = icmp ne i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int first = varCount;
								varCount++;
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp une double " + s + ", \%t" + first);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fcmp une double " + s + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp une double " + s + ", " + s1);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if 
						else if (($a.theInfo.theType == Type.FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fcmp une float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								Double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + first + ", " + s);
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + pre1 + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + pre + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CONST_FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp une float " + s + ", \%t" + varCount);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp une double " + s + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fcmp une double " + s + ", " + s1);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp une double " + s + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								Float f1 = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp une double " + s1 + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.DOUBLE)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + $theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fcmp une double \%t" + $a.theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CHAR)){
							if (($b.theInfo.theType == Type.CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int second = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + first + ", \%t" + second );
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + first + ", " + $b.theInfo.theVar.iValue);
								$theInfo.theType = Type.BOOL;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if			
				 }
				| AND  b=arith_expression
				 {	/*if( ($a.theInfo.theType==Type.INT)&& ($b.theInfo.theType==Type.INT)){
						TextCode.add("\%t" + varCount + " = and i1 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
						$theInfo.theType = Type.BOOL;
						$theInfo.theVar.varIndex = varCount;
						varCount++;
					}
					else if( ($a.theInfo.theType==Type.CONST_INT)&& ($b.theInfo.theType==Type.CONST_INT)){
						TextCode.add("\%t" + varCount + " = and i1 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
						$theInfo.theType = Type.BOOL;
						$theInfo.theVar.varIndex = varCount;
						varCount++;
					}
					else if( ($a.theInfo.theType==Type.INT)&& ($b.theInfo.theType==Type.CONST_INT)){
						TextCode.add("\%t" + varCount + " = and i1 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
						$theInfo.theType = Type.BOOL;
						$theInfo.theVar.varIndex = varCount;
						varCount++;
					}
					else if( ($a.theInfo.theType==Type.CONST_INT)&& ($b.theInfo.theType==Type.INT)){
						TextCode.add("\%t" + varCount + " = and i1 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
						$theInfo.theType = Type.BOOL;
						$theInfo.theVar.varIndex = varCount;
						varCount++;
					}*/	  
				 }
				| OR   b=arith_expression
				 {	if( ($a.theInfo.theType==Type.INT)&& ($b.theInfo.theType==Type.INT)){
						TextCode.add("\%t" + varCount + " = or i1 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
						$theInfo.theType = Type.BOOL;
						$theInfo.theVar.varIndex = varCount;
						varCount++;
					}
					else if( ($a.theInfo.theType==Type.CONST_INT)&& ($b.theInfo.theType==Type.CONST_INT)){
						TextCode.add("\%t" + varCount + " = or i1 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);
						$theInfo.theType = Type.BOOL;
						$theInfo.theVar.varIndex = varCount;
						varCount++;
					}
					else if( ($a.theInfo.theType==Type.INT)&& ($b.theInfo.theType==Type.CONST_INT)){
						TextCode.add("\%t" + varCount + " = or i1 \%t" + $theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
						$theInfo.theType = Type.BOOL;
						$theInfo.theVar.varIndex = varCount;
						varCount++;
					}
					else if( ($a.theInfo.theType==Type.CONST_INT)&& ($b.theInfo.theType==Type.INT)){
						TextCode.add("\%t" + varCount + " = or i1 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
						$theInfo.theType = Type.BOOL;
						$theInfo.theVar.varIndex = varCount;
						varCount++;
					}
				 }
				)*
				;
			   
arith_expression
returns [Info theInfo]
@init {theInfo = new Info();}
                : a=multExpr { $theInfo=$a.theInfo; }
                 ( PLUS b=multExpr
                    {	//System.out.println($a.theInfo.theType);
						//System.out.println($b.theInfo.theType);
                        if (($a.theInfo.theType == Type.INT)){
							if (($b.theInfo.theType == Type.INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre2=varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + pre + ", \%t" + pre2);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = add nsw i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
										int pre1 = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
									}
								} // if 
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = add nsw i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
										int pre1 = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount + " = add nsw i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
										int pre1 = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = add nsw i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
										int pre1 = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
									}
								} // else if
								else if( $a.theInfo.theKey == null ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = add nsw i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
										int pre1 = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
									}
									else{
										TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
									} //else
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.INT;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
								} // if
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = add nsw i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
								} // else if
								else {
									TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.INT;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							} // else if
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fadd double \%t" + pre  + ", \%t" + pre1);
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fadd double \%t" + pre  + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fadd double \%t" + pre  + ", " + s1);
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre1 + " to float");
								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // if
						else if (($a.theInfo.theType == Type.CONST_INT)){
							if (($b.theInfo.theType == Type.INT)){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = add nsw i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = add nsw i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount + " = add nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
								}
					
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.INT;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = add nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.INT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int first = varCount;
								varCount++;
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fadd double " + s + ", \%t" + first);
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fadd double " + s + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fadd double " + s + ", " + s1);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");
								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if 
						else if (($a.theInfo.theType == Type.FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fadd float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fadd double \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								Double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fadd double \%t" + first + ", " + s);
								int second = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + second + " to float");
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fadd double \%t" + pre1 + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fadd double \%t" + pre + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CONST_FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fadd float " + s + ", \%t" + varCount);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fadd double " + s + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fadd double " + s + ", " + s1);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fadd double " + s + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								Float f1 = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fadd double " + s1 + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.DOUBLE)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fadd double \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fadd double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fadd double \%t" + $theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fadd double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fadd double \%t" + $a.theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CHAR)){
							if (($b.theInfo.theType == Type.CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int second = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + first + ", \%t" + second );
								int third = varCount;
								varCount ++;
								TextCode.add( "\%t" + varCount + " = trunc i32 \%t" + third + " to i8");
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.CHAR;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_CHAR)) {
								
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + first + ", " + $b.theInfo.theVar.iValue);
								int second = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i32 \%t" + second + " to i8");
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.CHAR;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
					}
                | MINUS b=multExpr
                    {	
                     	if (($a.theInfo.theType == Type.INT)){
							if (($b.theInfo.theType == Type.INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre2=varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + pre + ", \%t" + pre2);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = sub nsw i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
										int pre1 = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
									}
								} // if 
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = sub nsw i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
										int pre1 = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount + " = sub nsw i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
										int pre1 = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
									}
									else{
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = sub nsw i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
										int pre1 = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
									}
								} // else if
								else if( $a.theInfo.theKey == null ){
									if ( $b.theInfo.theKey == Key.SHORT ){
										TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									} // if
									else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
										TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
										int pre = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = sub nsw i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
										int pre1 = varCount;
										varCount++;
										TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
									}
									else{
										TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
									} //else
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.INT;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								if ( $a.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
								} // if
								else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = sub nsw i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
								} // else if
								else {
									TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								}
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.INT;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							} // else if
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fsub double \%t" + pre  + ", \%t" + pre1);
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fsub double \%t" + pre  + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fsub double \%t" + pre  + ", " + s1);
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre1 + " to float");
								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // if
						else if (($a.theInfo.theType == Type.CONST_INT)){
							if (($b.theInfo.theType == Type.INT)){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = sub nsw i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = sub nsw i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount + " = sub nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
								}
					
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.INT;
								$theInfo.theKey = null;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = sub nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.INT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int first = varCount;
								varCount++;
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fsub double " + s + ", \%t" + first);
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								//System.out.println(s);
								TextCode.add("\%t" + varCount + " = fsub double " + s + ", \%t" + $b.theInfo.theVar.varIndex);
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								double dou = (double) $a.theInfo.theVar.iValue;
								System.out.println("je");
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fsub double " + s + ", " + s1);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");
								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if 
						else if (($a.theInfo.theType == Type.FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fsub float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fsub double \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								Double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fsub double \%t" + first + ", " + s);
								int second = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + second + " to float");
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fsub double \%t" + pre1 + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fsub double \%t" + pre + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CONST_FLOAT)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fsub float " + s + ", \%t" + varCount);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fsub double " + s + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								TextCode.add("\%t" + varCount + " = fsub double " + s + ", " + s1);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

								$theInfo.theType = Type.FLOAT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								Float f = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fsub double " + s + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								Float f1 = Float.parseFloat($a.theInfo.theVar.fValue);
								double dou1 = (double) f1;
								long bits1 = Double.doubleToLongBits(dou1);
								String s1 = String.format("\%16s", Long.toHexString(bits1));
								s1 = s1.toUpperCase();
								s1 = "0x" + s1 ;
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fsub double " + s1 + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.DOUBLE)){
							if (($b.theInfo.theType == Type.FLOAT)) {
								TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fsub double \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);

								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.DOUBLE)) {
								TextCode.add("\%t" + varCount + " = fsub double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
							
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
								Float f = Float.parseFloat($b.theInfo.theVar.fValue);
								double dou = (double) f;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fsub double \%t" + $theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.INT)){
								TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = fsub double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + pre);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_INT)) {
								double dou = (double) $b.theInfo.theVar.iValue;
								long bits = Double.doubleToLongBits(dou);
								String s = String.format("\%16s", Long.toHexString(bits));
								s = s.toUpperCase();
								s = "0x" + s ;
								TextCode.add("\%t" + varCount + " = fsub double \%t" + $a.theInfo.theVar.varIndex + ", " + s);
						
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.DOUBLE;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
						else if (($a.theInfo.theType == Type.CHAR)){
							if (($b.theInfo.theType == Type.CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int second = varCount;
								varCount ++;
								TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + first + ", \%t" + second );
								int third = varCount;
								varCount ++;
								TextCode.add( "\%t" + varCount + " = trunc i32 \%t" + third + " to i8");
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.CHAR;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
							else if (($b.theInfo.theType == Type.CONST_CHAR)) {
								TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
								int first = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + first + ", " + $b.theInfo.theVar.iValue);
								int second = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i32 \%t" + second + " to i8");
								// Update arith_expression's theInfo.
								$theInfo.theType = Type.CHAR;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
							}
						} // else if
                    }
				| BITAND b = multExpr
				  { 
					if ( ( ($a.theInfo.theType != Type.INT) && ($a.theInfo.theType != Type.CONST_INT) ) || ( ($b.theInfo.theType != Type.INT) && ($b.theInfo.theType != Type.CONST_INT) ) ){
                    	System.out.println("Error! " + $BITAND.getLine() + ": Type mismatch for the two silde operands in a logic expression.");
						System.exit(0);
					} // if 
					if (($a.theInfo.theType == Type.INT)){
						if (($b.theInfo.theType == Type.INT)) {
							if ( $a.theInfo.theKey == Key.SHORT ){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre2=varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = and i32 \%t" + pre + ", \%t" + pre2);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = and i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = and i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
								}
							} // if 
							else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = and i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = and i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = and i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
							} // else if
							else if( $a.theInfo.theKey == null ){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = and i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = and i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount + " = and i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
								} //else
							}
							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theKey = null;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						}
						else if (($b.theInfo.theType == Type.CONST_INT)) {
							if ( $a.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = and i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
							} // if
							else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount + " = and i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
							} // else if
							else {
								TextCode.add("\%t" + varCount + " = and i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
							}
							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theKey = null;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						} // else if					
					} // if
					else if (($a.theInfo.theType == Type.CONST_INT)){
						if (($b.theInfo.theType == Type.INT)){
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = and  i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount + " = and  i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount + " = and  i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
							}
				
							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theKey = null;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						}
						else if (($b.theInfo.theType == Type.CONST_INT)) {
							TextCode.add("\%t" + varCount + " = and  i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						}
					} // else if
				  }  
				| BITXOR b = multExpr
				 {
					if ( ( ($a.theInfo.theType != Type.INT) && ($a.theInfo.theType != Type.CONST_INT) ) || ( ($b.theInfo.theType != Type.INT) && ($b.theInfo.theType != Type.CONST_INT) ) ){
                    	System.out.println("Error! " + $BITXOR.getLine() + ": Type mismatch for the two silde operands in a logic expression.");
						System.exit(0);
					} // if 
					if (($a.theInfo.theType == Type.INT)){
						if (($b.theInfo.theType == Type.INT)) {
							if ( $a.theInfo.theKey == Key.SHORT ){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre2=varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = xor i32 \%t" + pre + ", \%t" + pre2);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = xor i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = xor i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
								}
							} // if 
							else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = xor i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = xor i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = xor i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
							} // else if
							else if( $a.theInfo.theKey == null ){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = xor i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = xor i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount + " = xor i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
								} //else
							}
							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theKey = null;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						}
						else if (($b.theInfo.theType == Type.CONST_INT)) {
							if ( $a.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = xor i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
							} // if
							else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount + " = xor i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
							} // else if
							else {
								TextCode.add("\%t" + varCount + " = xor i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
							}
							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theKey = null;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						} // else if					
					} // if
					else if (($a.theInfo.theType == Type.CONST_INT)){
						if (($b.theInfo.theType == Type.INT)){
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = xor  i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount + " = xor  i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount + " = xor  i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
							}
				
							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theKey = null;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						}
						else if (($b.theInfo.theType == Type.CONST_INT)) {
							TextCode.add("\%t" + varCount + " = xor  i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						}
					} // else if
				 }  				
				| BITOR b = multExpr
				 {	
					if ( ( ($a.theInfo.theType != Type.INT) && ($a.theInfo.theType != Type.CONST_INT) ) || ( ($b.theInfo.theType != Type.INT) && ($b.theInfo.theType != Type.CONST_INT) ) ){
                    	System.out.println("Error! " + $BITOR.getLine() + ": Type mismatch for the two silde operands in a logic expression.");
						System.exit(0);
					} // if 
					if (($a.theInfo.theType == Type.INT)){
						if (($b.theInfo.theType == Type.INT)) {
							if ( $a.theInfo.theKey == Key.SHORT ){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre2=varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = or i32 \%t" + pre + ", \%t" + pre2);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = or i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = or i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
								}
							} // if 
							else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = or i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount + " = or i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = or i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
							} // else if
							else if( $a.theInfo.theKey == null ){
								if ( $b.theInfo.theKey == Key.SHORT ){
									TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = or i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
								} // if
								else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
									TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
									int pre = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = or i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
									int pre1 = varCount;
									varCount++;
									TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
								}
								else{
									TextCode.add("\%t" + varCount + " = or i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
								} //else
							}
							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theKey = null;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						}
						else if (($b.theInfo.theType == Type.CONST_INT)) {
							if ( $a.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = or i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
							} // if
							else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount + " = or i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
							} // else if
							else {
								TextCode.add("\%t" + varCount + " = or i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
							}
							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theKey = null;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						} // else if					
					} // if
					else if (($a.theInfo.theType == Type.CONST_INT)){
						if (($b.theInfo.theType == Type.INT)){
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = or  i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount + " = or  i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount + " = or  i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
							}
				
							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theKey = null;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						}
						else if (($b.theInfo.theType == Type.CONST_INT)) {
							TextCode.add("\%t" + varCount + " = or  i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

							// Update arith_expression's theInfo.
							$theInfo.theType = Type.INT;
							$theInfo.theVar.varIndex = varCount;
							varCount ++;
						}
					} // else if
				 }  	
				)*
                ;

multExpr
returns [Info theInfo]
@init {theInfo = new Info();}
          : a = signExpr { $theInfo=$a.theInfo; }
          ( MULTI b = signExpr
			{					   
				if (($a.theInfo.theType == Type.INT)) { 
					if (($b.theInfo.theType == Type.INT)) {
						if ( $a.theInfo.theKey == Key.SHORT ){
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int pre2=varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + pre + ", \%t" + pre2);
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = mul nsw i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
							}
						} // if 
						else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = mul nsw i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount + " = mul nsw i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = mul nsw i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
						} // else if
						else if( $a.theInfo.theKey == null ){
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = mul nsw i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
							} //else
						}
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theKey = null;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						if ( $a.theInfo.theKey == Key.SHORT ){
							TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
						} // if
						else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
							TextCode.add("\%t" + varCount + " = mul nsw i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
						} // else if
						else {
							TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
						}
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theKey = null;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					} // else if
					else if (($b.theInfo.theType == Type.FLOAT)) {
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
						int pre1 = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fmul double \%t" + pre  + ", \%t" + pre1);
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.DOUBLE)) {
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fmul double \%t" + pre  + ", \%t" + $b.theInfo.theVar.varIndex);
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
						double dou1 = (double) f1;
						long bits1 = Double.doubleToLongBits(dou1);
						String s1 = String.format("\%16s", Long.toHexString(bits1));
						s1 = s1.toUpperCase();
						s1 = "0x" + s1 ;
						TextCode.add("\%t" + varCount + " = fmul double \%t" + pre  + ", " + s1);
						int pre1 = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre1 + " to float");
						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				} // if
				else if (($a.theInfo.theType == Type.CONST_INT)){
					if (($b.theInfo.theType == Type.INT)){
						if ( $b.theInfo.theKey == Key.SHORT ){
							TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = mul nsw i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
						} // if
						else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
							TextCode.add("\%t" + varCount + " = mul nsw i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
						}
						else{
							TextCode.add("\%t" + varCount + " = mul nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
						}
			
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theKey = null;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						TextCode.add("\%t" + varCount + " = mul nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.FLOAT)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
						int first = varCount;
						varCount++;
						double dou = (double) $a.theInfo.theVar.iValue;
						System.out.println("je");
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						//System.out.println(s);
						TextCode.add("\%t" + varCount + " = fmul double " + s + ", \%t" + first);
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.DOUBLE)) {
						double dou = (double) $a.theInfo.theVar.iValue;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						//System.out.println(s);
						TextCode.add("\%t" + varCount + " = fmul double " + s + ", \%t" + $b.theInfo.theVar.varIndex);
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
						double dou = (double) $a.theInfo.theVar.iValue;
						System.out.println("je");
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
						double dou1 = (double) f1;
						long bits1 = Double.doubleToLongBits(dou1);
						String s1 = String.format("\%16s", Long.toHexString(bits1));
						s1 = s1.toUpperCase();
						s1 = "0x" + s1 ;
						TextCode.add("\%t" + varCount + " = fmul double " + s + ", " + s1);
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");
						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				} // else if 
				else if (($a.theInfo.theType == Type.FLOAT)){
					if (($b.theInfo.theType == Type.FLOAT)) {
					   TextCode.add("\%t" + varCount + " = fmul float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
				   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.FLOAT;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
					}
					else if (($b.theInfo.theType == Type.DOUBLE)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
					    TextCode.add("\%t" + varCount + " = fmul double \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
				   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
						Float f = Float.parseFloat($b.theInfo.theVar.fValue);
						Double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						int first = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fmul double \%t" + first + ", " + s);
						int second = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + second + " to float");
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.INT)){
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre1 = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fmul double \%t" + pre1 + ", \%t" + pre);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						double dou = (double) $b.theInfo.theVar.iValue;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = fmul double \%t" + pre + ", " + s);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				} // else if
				else if (($a.theInfo.theType == Type.CONST_FLOAT)){
					if (($b.theInfo.theType == Type.FLOAT)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
						Float f = Float.parseFloat($a.theInfo.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						int first = varCount;
						varCount++;
					   	TextCode.add("\%t" + varCount + " = fmul float " + s + ", \%t" + varCount);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.DOUBLE)) {
						Float f = Float.parseFloat($a.theInfo.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = fmul double " + s + ", \%t" + $b.theInfo.theVar.varIndex );
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
						Float f = Float.parseFloat($b.theInfo.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
						double dou1 = (double) f1;
						long bits1 = Double.doubleToLongBits(dou1);
						String s1 = String.format("\%16s", Long.toHexString(bits1));
						s1 = s1.toUpperCase();
						s1 = "0x" + s1 ;
						TextCode.add("\%t" + varCount + " = fmul double " + s + ", " + s1);
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.INT)){
						Float f = Float.parseFloat($a.theInfo.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fmul double " + s + ", \%t" + pre);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						Float f1 = Float.parseFloat($a.theInfo.theVar.fValue);
						double dou1 = (double) f1;
						long bits1 = Double.doubleToLongBits(dou1);
						String s1 = String.format("\%16s", Long.toHexString(bits1));
						s1 = s1.toUpperCase();
						s1 = "0x" + s1 ;
						double dou = (double) $b.theInfo.theVar.iValue;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = fmul double " + s1 + ", " + s);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				} // else if
				else if (($a.theInfo.theType == Type.DOUBLE)){
					if (($b.theInfo.theType == Type.FLOAT)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fmul double \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);

						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					if (($b.theInfo.theType == Type.DOUBLE)) {
					   TextCode.add("\%t" + varCount + " = fmul double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
				   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
						Float f = Float.parseFloat($b.theInfo.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = fmul double \%t" + $theInfo.theVar.varIndex + ", " + s);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.INT)){
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fmul double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + pre);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						double dou = (double) $b.theInfo.theVar.iValue;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = fmul double \%t" + $a.theInfo.theVar.varIndex + ", " + s);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				} // else if
				else if (($a.theInfo.theType == Type.CHAR)){
					if (($b.theInfo.theType == Type.CHAR)) {
					   TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
					   int first = varCount;
					   varCount ++;
					   TextCode.add("\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
					   int second = varCount;
					   varCount ++;
					   TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + first + ", \%t" + second );
					   int third = varCount;
					   varCount ++;
					   TextCode.add( "\%t" + varCount + " = trunc i32 \%t" + third + " to i8");
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.CHAR;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_CHAR)) {
					   TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
					   int first = varCount;
					   varCount++;
					   TextCode.add("\%t" + varCount + " = mul nsw i32 \%t" + first + ", " + $b.theInfo.theVar.iValue);
						int second = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = trunc i32 \%t" + second + " to i8");
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.CHAR;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
					}
				} // else if
			}
          | DIV b = signExpr
			{				   
				if (($a.theInfo.theType == Type.INT)) { 
					if (($b.theInfo.theType == Type.INT)) {
						if ( $a.theInfo.theKey == Key.SHORT ){
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int pre2=varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = sdiv nsw i32 \%t" + pre + ", \%t" + pre2);
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = sdiv nsw i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = sdiv nsw i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
							}
						} // if 
						else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = sdiv nsw i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount + " = sdiv nsw i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = sdiv nsw i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
						} // else if
						else if( $a.theInfo.theKey == null ){
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = sdiv nsw i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = sdiv nsw i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount + " = sdiv nsw i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
							} //else
						}
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theKey = null;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						if ( $a.theInfo.theKey == Key.SHORT ){
							TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = sdiv nsw i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
						} // if
						else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
							TextCode.add("\%t" + varCount + " = sdiv nsw i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
						} // else if
						else {
							TextCode.add("\%t" + varCount + " = sdiv nsw i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
						}
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theKey = null;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					} // else if
					else if (($b.theInfo.theType == Type.FLOAT)) {
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
						int pre1 = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fdiv double \%t" + pre  + ", \%t" + pre1);
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.DOUBLE)) {
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fdiv double \%t" + pre  + ", \%t" + $b.theInfo.theVar.varIndex);
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
						double dou1 = (double) f1;
						long bits1 = Double.doubleToLongBits(dou1);
						String s1 = String.format("\%16s", Long.toHexString(bits1));
						s1 = s1.toUpperCase();
						s1 = "0x" + s1 ;
						TextCode.add("\%t" + varCount + " = fdiv double \%t" + pre  + ", " + s1);
						int pre1 = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre1 + " to float");
						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				} // if
				else if (($a.theInfo.theType == Type.CONST_INT)){
					if (($b.theInfo.theType == Type.INT)){
						if ( $b.theInfo.theKey == Key.SHORT ){
							TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = sdiv nsw i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
						} // if
						else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
							TextCode.add("\%t" + varCount + " = sdiv nsw i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
						}
						else{
							TextCode.add("\%t" + varCount + " = sdiv nsw i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
						}
			
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theKey = null;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						TextCode.add("\%t" + varCount + " = sdiv nsw i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.FLOAT)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
						int first = varCount;
						varCount++;
						double dou = (double) $a.theInfo.theVar.iValue;
						System.out.println("je");
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						//System.out.println(s);
						TextCode.add("\%t" + varCount + " = fdiv double " + s + ", \%t" + first);
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.DOUBLE)) {
						double dou = (double) $a.theInfo.theVar.iValue;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						//System.out.println(s);
						TextCode.add("\%t" + varCount + " = fdiv double " + s + ", \%t" + $b.theInfo.theVar.varIndex);
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
						double dou = (double) $a.theInfo.theVar.iValue;
						System.out.println("je");
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
						double dou1 = (double) f1;
						long bits1 = Double.doubleToLongBits(dou1);
						String s1 = String.format("\%16s", Long.toHexString(bits1));
						s1 = s1.toUpperCase();
						s1 = "0x" + s1 ;
						TextCode.add("\%t" + varCount + " = fdiv double " + s + ", " + s1);
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");
						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				} // else if 
				else if (($a.theInfo.theType == Type.FLOAT)){
					if (($b.theInfo.theType == Type.FLOAT)) {
					   TextCode.add("\%t" + varCount + " = fdiv float \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
				   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.FLOAT;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
					}
					else if (($b.theInfo.theType == Type.DOUBLE)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
					    TextCode.add("\%t" + varCount + " = fdiv double \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
				   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $theInfo.theVar.varIndex + " to double");
						Float f = Float.parseFloat($b.theInfo.theVar.fValue);
						Double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						int first = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fdiv double \%t" + first + ", " + s);
						int second = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + second + " to float");
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.INT)){
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre1 = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fdiv double \%t" + pre1 + ", \%t" + pre);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $a.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						double dou = (double) $b.theInfo.theVar.iValue;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = fdiv double \%t" + pre + ", " + s);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				} // else if
				else if (($a.theInfo.theType == Type.CONST_FLOAT)){
					if (($b.theInfo.theType == Type.FLOAT)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
						Float f = Float.parseFloat($a.theInfo.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						int first = varCount;
						varCount++;
					   	TextCode.add("\%t" + varCount + " = fdiv float " + s + ", \%t" + varCount);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.DOUBLE)) {
						Float f = Float.parseFloat($a.theInfo.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = fdiv double " + s + ", \%t" + $b.theInfo.theVar.varIndex );
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
						Float f = Float.parseFloat($b.theInfo.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						Float f1 = Float.parseFloat($b.theInfo.theVar.fValue);
						double dou1 = (double) f1;
						long bits1 = Double.doubleToLongBits(dou1);
						String s1 = String.format("\%16s", Long.toHexString(bits1));
						s1 = s1.toUpperCase();
						s1 = "0x" + s1 ;
						TextCode.add("\%t" + varCount + " = fdiv double " + s + ", " + s1);
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fptrunc double \%t" + pre + " to float");

						$theInfo.theType = Type.FLOAT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.INT)){
						Float f = Float.parseFloat($a.theInfo.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fdiv double " + s + ", \%t" + pre);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						Float f1 = Float.parseFloat($a.theInfo.theVar.fValue);
						double dou1 = (double) f1;
						long bits1 = Double.doubleToLongBits(dou1);
						String s1 = String.format("\%16s", Long.toHexString(bits1));
						s1 = s1.toUpperCase();
						s1 = "0x" + s1 ;
						double dou = (double) $b.theInfo.theVar.iValue;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = fdiv double " + s1 + ", " + s);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				} // else if
				else if (($a.theInfo.theType == Type.DOUBLE)){
					if (($b.theInfo.theType == Type.FLOAT)) {
						TextCode.add("\%t" + varCount + " = fpext float \%t" + $b.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fdiv double \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);

						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					if (($b.theInfo.theType == Type.DOUBLE)) {
					   TextCode.add("\%t" + varCount + " = fdiv double \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
				   
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.DOUBLE;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
						Float f = Float.parseFloat($b.theInfo.theVar.fValue);
						double dou = (double) f;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = fdiv double \%t" + $theInfo.theVar.varIndex + ", " + s);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.INT)){
						TextCode.add("\%t" + varCount + " = sitofp i32 \%t" + $b.theInfo.theVar.varIndex + " to double");
						int pre = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = fdiv double \%t" + $a.theInfo.theVar.varIndex + ", \%t" + pre);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						double dou = (double) $b.theInfo.theVar.iValue;
						long bits = Double.doubleToLongBits(dou);
						String s = String.format("\%16s", Long.toHexString(bits));
						s = s.toUpperCase();
						s = "0x" + s ;
						TextCode.add("\%t" + varCount + " = fdiv double \%t" + $a.theInfo.theVar.varIndex + ", " + s);
				   
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.DOUBLE;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				} // else if
				else if (($a.theInfo.theType == Type.CHAR)){
					if (($b.theInfo.theType == Type.CHAR)) {
					   TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
					   int first = varCount;
					   varCount ++;
					   TextCode.add("\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
					   int second = varCount;
					   varCount ++;
					   TextCode.add("\%t" + varCount + " = sdiv nsw i32 \%t" + first + ", \%t" + second );
					   int third = varCount;
					   varCount ++;
					   TextCode.add( "\%t" + varCount + " = trunc i32 \%t" + third + " to i8");
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.CHAR;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_CHAR)) {
					   TextCode.add("\%t" + varCount + " = sext i8 \%t" + $theInfo.theVar.varIndex + " to i32");
					   int first = varCount;
					   varCount++;
					   TextCode.add("\%t" + varCount + " = sdiv nsw i32 \%t" + first + ", " + $b.theInfo.theVar.iValue);
						int second = varCount;
						varCount++;
						TextCode.add("\%t" + varCount + " = trunc i32 \%t" + second + " to i8");
					   // Update arith_expression's theInfo.
					   $theInfo.theType = Type.CHAR;
					   $theInfo.theVar.varIndex = varCount;
					   varCount ++;
					}
				} // else if
			} 
		  | MOD b = signExpr
			{	
				if ( ( ($a.theInfo.theType != Type.INT) && ($a.theInfo.theType != Type.CONST_INT) ) || ( ($b.theInfo.theType != Type.INT) && ($b.theInfo.theType != Type.CONST_INT) ) ){
                    	System.out.println("Error! " + $MOD.getLine() + ": Type mismatch for the two silde operands in a arith expression.");
						System.exit(0);
					} // if 			   
				if (($a.theInfo.theType == Type.INT)){
					if (($b.theInfo.theType == Type.INT)) {
						if ( $a.theInfo.theKey == Key.SHORT ){
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int pre2=varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = srem i32 \%t" + pre + ", \%t" + pre2);
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = srem i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = srem i32 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex);
							}
						} // if 
						else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){ 
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = srem i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount + " = srem i64 \%t" + $theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount +" = sext i32 \%t" + $b.theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = srem i64 \%t" + $theInfo.theVar.varIndex  + ", \%t" + pre);
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
						} // else if
						else if( $a.theInfo.theKey == null ){
							if ( $b.theInfo.theKey == Key.SHORT ){
								TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = srem i32 \%t" + $theInfo.theVar.varIndex + ", \%t" + pre);
							} // if
							else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
								TextCode.add("\%t" + varCount +" = sext i32 \%t" + $theInfo.theVar.varIndex + " to i64");
								int pre = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = srem i64 \%t" + pre + ", \%t" + $b.theInfo.theVar.varIndex );
								int pre1 = varCount;
								varCount++;
								TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre1 + " to i32");
							}
							else{
								TextCode.add("\%t" + varCount + " = srem i32 \%t" + $theInfo.theVar.varIndex  + ", \%t" + $b.theInfo.theVar.varIndex);
							} //else
						}
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theKey = null;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						if ( $a.theInfo.theKey == Key.SHORT ){
							TextCode.add("\%t" + varCount +" = sext i16 \%t" + $theInfo.theVar.varIndex + " to i32");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = srem i32 \%t" + pre + ", " + $b.theInfo.theVar.iValue);
						} // if
						else if ( $a.theInfo.theKey == Key.LONG_LONG || $a.theInfo.theKey == Key.LONG ){
							TextCode.add("\%t" + varCount + " = srem i64 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
						} // else if
						else {
							TextCode.add("\%t" + varCount + " = srem i32 \%t" + $theInfo.theVar.varIndex  + ", " + $b.theInfo.theVar.iValue);
						}
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theKey = null;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					} // else if					
				} // if
				else if (($a.theInfo.theType == Type.CONST_INT)){
					 if (($b.theInfo.theType == Type.INT)){
						if ( $b.theInfo.theKey == Key.SHORT ){
							TextCode.add("\%t" + varCount +" = sext i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = srem  i32 " + $theInfo.theVar.iValue + ", \%t" + pre);
						} // if
						else if ( $b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
							TextCode.add("\%t" + varCount + " = srem  i64 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex );
							int pre = varCount;
							varCount++;
							TextCode.add("\%t" + varCount + " = trunc i64 \%t" + pre + " to i32");
						}
						else{
							TextCode.add("\%t" + varCount + " = srem  i32 " + $theInfo.theVar.iValue + ", \%t" + $b.theInfo.theVar.varIndex);
						}
			
						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theKey = null;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if (($b.theInfo.theType == Type.CONST_INT)) {
						TextCode.add("\%t" + varCount + " = srem  i32 " + $theInfo.theVar.iValue + ", " + $b.theInfo.theVar.iValue);

						// Update arith_expression's theInfo.
						$theInfo.theType = Type.INT;
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				} // else if				
			} 
		  )*
		  ;

signExpr
returns [Info theInfo]
@init {theInfo = new Info();}
        : a = primaryExpr { $theInfo=$a.theInfo; } 
        | '-' b = primaryExpr 
		{
			// We need to do type checking first.
			// ...

			// code generation.
			if (($b.theInfo.theType == Type.INT)) {
			   if($b.theInfo.theKey == Key.SHORT){
			   		TextCode.add("\%t" + varCount + " = i16 \%t" + $b.theInfo.theVar.varIndex + " to i32");
			   		int pre = varCount;
					varCount++;
					TextCode.add("\%t" + varCount + " = sub nsw i32 0" + ", \%t" + pre);
			   }
			   else if($b.theInfo.theKey == Key.LONG_LONG || $b.theInfo.theKey == Key.LONG ){
					TextCode.add("\%t" + varCount + " = sub nsw i64 0" + ", \%t" + $b.theInfo.theVar.varIndex );
			   }
			   else TextCode.add("\%t" + varCount + " = sub nsw i32 0" + ", \%t" + $b.theInfo.theVar.varIndex );
			  
			   // Update arith_expression's theInfo.
			   $theInfo.theType = Type.INT;
			   $theInfo.theKey = $b.theInfo.theKey;
			   $theInfo.theVar.varIndex = varCount;
			   varCount ++;
			} 
			else if (($b.theInfo.theType == Type.CONST_INT)) {
			   TextCode.add("\%t" + varCount + " = sub nsw i32 0" + ", " + $b.theInfo.theVar.iValue);

			   // Update arith_expression's theInfo.
			   $theInfo.theType = Type.CONST_INT;
			   $theInfo.theVar.varIndex = varCount;
			   varCount ++;
			}//else if
			else if (($b.theInfo.theType == Type.FLOAT)) {
			   TextCode.add("\%t" + varCount + " = fneg float \%t" + $b.theInfo.theVar.varIndex );
		   
			   // Update arith_expression's theInfo.
			   $theInfo.theType = Type.FLOAT;
			   $theInfo.theVar.varIndex = varCount;
			   varCount ++;
			} // else if
			else if (($b.theInfo.theType == Type.CONST_FLOAT)) {
				double tmp = 0 - Double.parseDouble($b.theInfo.theVar.fValue); 
 				String s = String.format("\%e", tmp);
				$theInfo.theVar.fValue = s;
				//System.out.println(s);
				$theInfo.theType = Type.CONST_FLOAT;
				$theInfo.theVar.varIndex = varCount;
				varCount ++;
			}//else if
			else if (($b.theInfo.theType == Type.DOUBLE)) {
			   TextCode.add("\%t" + varCount + " = fneg double \%t" + $b.theInfo.theVar.varIndex );
		   
			   // Update arith_expression's theInfo.
			   $theInfo.theType = Type.DOUBLE;
			   $theInfo.theVar.varIndex = varCount;
			   varCount ++;
			} // else if
			else if (($b.theInfo.theType == Type.CHAR)) {
			   TextCode.add("\%t" + varCount + " = sext i8 \%t" + $b.theInfo.theVar.varIndex + " to i32");
			   int first = varCount;
			   varCount++;
			   TextCode.add("\%t" + varCount + " = sub nsw i32 0" + ", \%t" + first );
			   int second = varCount;
			   varCount++;
			   TextCode.add("\%t" + varCount + " = trunc i32 \%t" + second + " to i8");
			   // Update arith_expression's theInfo.
			   $theInfo.theType = Type.CHAR;
			   $theInfo.theVar.varIndex = varCount;
			   varCount ++;
			} // else if
			else if (($b.theInfo.theType == Type.CONST_CHAR)) {
				$theInfo.theVar.iValue = 0 - $b.theInfo.theVar.iValue;
				$theInfo.theType = Type.CONST_CHAR;
			}//else if
		}    
	;
		  
primaryExpr
returns [Info theInfo]
@init {theInfo = new Info();}
           : Integer_constant
			{
					$theInfo.theType = Type.CONST_INT;
					$theInfo.theVar.iValue = Integer.parseInt($Integer_constant.text);
					//System.out.println($theInfo.theVar.iValue);
			}
           | Floating_point_constant
			{
					$theInfo.theType = Type.CONST_FLOAT;
					String s = String.format("\%e", Float.parseFloat($Floating_point_constant.text));
					// int i = Float.floatToIntBits($theInfo.theVar.fValue);
					$theInfo.theVar.fValue = s;
					//System.out.println(s);
			}
           | Char
          	 	{    $theInfo.theType = Type.CONST_CHAR;
               		 //$Char.text.charAt(1);
               		 $theInfo.theVar.iValue = $Char.text.charAt(1);
               		 //System.out.println($theInfo.theVar.iValue);
           		}
		   | b=Identifier
			'('( c=Identifier
				{		
					String str = $b.text;
					if (!symtab.containsKey(str)){ // identifier already exist
						System.out.println("Error! " + $b.getLine() + ": Undefined  func name." + "( identifier:" +$b.text +" )"); 
						System.exit(0);
					}
					Info t = symtab.get(str);
		
					boolean isFunc = symtab.get(str).isFunc;
					int Index =  symtab.get(str).theVar.varIndex;
					if(!isFunc){
						System.out.println("Error! " + $b.getLine() + ": identifier is not func name."+ "( identifier:" +$b.text +" )");
						System.exit(0);
					}

					String s = $c.text + Integer.toString(scope);
					Info t1 = symtab.get(s);
					int cur1 = scope;
					while( t1 == null ){
						cur1 = cur1 - 1;
						if( cur1 < 0 ){
							System.out.println("Error! " + $c.getLine() + ": Undefined identifier."+ "( identifier:" +$c.text +" )");
							System.exit(0);
						} // if
						s = $c.text + Integer.toString(cur1);
						t1 = symtab.get(s);
						if(t1 != null) break;
					} // while

					Info Id =symtab.get(s);
					TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + Id.theVar.varIndex + ", align 4");
					int pre = varCount;
					varCount ++;
					TextCode.add("\%t" + varCount + " = call i32 @t" + Index + "(i32 \%t" + pre + ")" ); 
					$theInfo.theVar.varIndex = varCount;
					$theInfo.theType = Type.INT;
					varCount++;
				} 
			| Integer_constant
				{
					String str = $b.text;
					if (!symtab.containsKey(str)){ // identifier already exist
						System.out.println("Error! " + $b.getLine() + ": Undefined  func name." + "( identifier:" +$b.text +" )"); 
						System.exit(0);
					}
					boolean isFunc = symtab.get(str).isFunc;
					int Index =  symtab.get(str).theVar.varIndex;
					if(!isFunc){
						System.out.println("Error! " + $b.getLine() + ": identifier is not func name."+ "( identifier:" +$b.text +" )");
						System.exit(0);
					}

					TextCode.add("\%t" + varCount + " = call i32 @t" + Index + "(i32 " + Integer.parseInt($Integer_constant.text) + ")" ); 
					$theInfo.theVar.varIndex = varCount;
					$theInfo.theType = Type.INT;
					varCount++;
				}
			 )
		   ')'
           | Identifier
              {
                // get type information from symtab.
				String str = $Identifier.text;
				if (symtab.containsKey(str)){ // identifier already exist
					System.out.println("Error! " + $Identifier.getLine() + ": identifier is func name." + "( identifier:" +$Identifier.text +" )"); 
					System.exit(0);
				}
				str = $Identifier.text + Integer.toString(scope);
				
				Info t = symtab.get(str);
				int cur = scope;
				while( t == null ){
					cur = cur - 1;
					if( cur < 0 ){
						System.out.println("Error! " + $Identifier.getLine() + ": Undefined identifier."+ "( identifier:" +$Identifier.text +" )");
						System.exit(0);
					}
					str = $Identifier.text + Integer.toString(cur);
					t = symtab.get(str);
					if(t != null) break;
				}
				
                Type the_type = symtab.get(str).theType;
				$theInfo.theType = the_type;
                Key tkey = symtab.get(str).theKey;
				boolean isglobal = symtab.get(str).isGlobal;
				boolean isFunc = symtab.get(str).isFunc;
				
                // get variable index from symtab.
                int vIndex = symtab.get(str).theVar.varIndex;
                switch (the_type) {
					case INT: 
							 // get a new temporary variable and
							 // load the variable into the temporary variable.
							 // Ex: \%tx = load i32, i32* \%ty.
							 if ( isglobal ) {
								 if (tkey==Key.LONG)
									TextCode.add("\%t" + varCount + " = load i64, i64* @t" + vIndex + ", align 8");
								 else if (tkey==Key.LONG_LONG)
									TextCode.add("\%t" + varCount + " = load i64, i64* @t" + vIndex + ", align 8");
								 else if (tkey==Key.SHORT)
									TextCode.add("\%t" + varCount + " = load i16, i16* @t" + vIndex + ", align 2");
								 else TextCode.add("\%t" + varCount + " = load i32, i32* @t" + vIndex + ", align 4");
							 }
							 else{
								 if (tkey==Key.LONG)
									TextCode.add("\%t" + varCount + " = load i64, i64* \%t" + vIndex + ", align 8");
								 else if (tkey==Key.LONG_LONG)
									TextCode.add("\%t" + varCount + " = load i64, i64* \%t" + vIndex + ", align 8");
								 else if (tkey==Key.SHORT)
									TextCode.add("\%t" + varCount + " = load i16, i16* \%t" + vIndex + ", align 2");
								 else TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + vIndex + ", align 4");
							 }
							 // Now, Identifier's value is at the temporary variable \%t[varCount].
							 // Therefore, update it.
							 $theInfo.theKey = tkey;
							 $theInfo.theVar.varIndex = varCount;
							 varCount ++;
							 break;
					case FLOAT:
                             // get a new temporary variable and
                             // load the variable into the temporary variable.
                             // Ex: \%tx = load i32, i32* \%ty.
							 if ( isglobal )
								TextCode.add("\%t" + varCount + " = load float, float* @t" + vIndex + ", align 4");
                             else 
								TextCode.add("\%t" + varCount + " = load float, float* \%t" + vIndex + ", align 4");
                             // Now, Identifier's value is at the temporary variable \%t[varCount].
                             // Therefore, update it.
                             $theInfo.theVar.varIndex = varCount;
                             varCount ++;
							 break;
                    case DOUBLE:
                             // get a new temporary variable and
                             // load the variable into the temporary variable.
                             
                             // Ex: \%tx = load i32, i32* \%ty.
							 if ( isglobal )
								TextCode.add("\%t" + varCount + " = load double, double* @t" + vIndex + ", align 8");
                             else
								TextCode.add("\%t" + varCount + " = load double, double* \%t" + vIndex + ", align 8");
                             // Now, Identifier's value is at the temporary variable \%t[varCount].
                             // Therefore, update it.
                             $theInfo.theVar.varIndex = varCount;
                             varCount ++;
                             break;
					case CHAR:
                             // get a new temporary variable and
                             // load the variable into the temporary variable.
                             
                             // Ex: \%tx = load i32, i32* \%ty.
							 if ( isglobal )
								TextCode.add("\%t" + varCount + " = load i8, i8* @t" + vIndex + ", align 1");
                             else
								TextCode.add("\%t" + varCount + " = load i8, i8* \%t" + vIndex + ", align 1");
                             // Now, Identifier's value is at the temporary variable \%t[varCount].
                             // Therefore, update it.
                             $theInfo.theVar.varIndex = varCount;
                             varCount ++;
                             break;
				
                }
              }
		   | '&' Identifier
				{  
					// get type information from symtab.
					String str = $Identifier.text + Integer.toString(scope);
					
					Info t = symtab.get(str);
					int cur = scope;
					while( t == null ){
						cur = cur - 1;
						if( cur < 0 ){
							System.out.println("Error! " + $Identifier.getLine() + ": Undefined identifier."+ "( identifier:" +$Identifier.text +" )");
							System.exit(0);
						}
						str = $Identifier.text + Integer.toString(cur);
						t = symtab.get(str);
						if(t != null) break;
					}
					
					Type the_type = symtab.get(str).theType;
					$theInfo.theType = the_type;
					Key tkey = symtab.get(str).theKey;
					boolean isglobal = symtab.get(str).isGlobal;
					int vIndex = symtab.get(str).theVar.varIndex;
					if ( isglobal ){
						System.out.println("Error! " + $Identifier.getLine() + ": no provide & globel variable");
						System.exit(0);
					} // if
					switch (the_type) {
						case INT: 
								// get a new temporary variable and
								// load the variable into the temporary variable.
								// Ex: \%tx = load i32, i32* \%ty.
							
								if (tkey==Key.LONG)
									TextCode.add("\%t" + varCount + " = ptrtoint i64* \%t" + vIndex + " to i32");
								else if (tkey==Key.LONG_LONG)
									TextCode.add("\%t" + varCount + " = ptrtoint i64* \%t" + vIndex + " to i32");
								else if (tkey==Key.SHORT)
									TextCode.add("\%t" + varCount + " = ptrtoint i16* \%t" + vIndex + " to i32");
								else TextCode.add("\%t" + varCount + " = ptrtoint i32* \%t" + vIndex + " to i32");
							
								// Now, Identifier's value is at the temporary variable \%t[varCount].
								// Therefore, update it.
								$theInfo.theKey = null;
								$theInfo.theType = Type.INT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
								break;
						case FLOAT:
								// get a new temporary variable and
								// load the variable into the temporary variable.
								// Ex: \%tx = load i32, i32* \%ty.
							
								TextCode.add("\%t" + varCount + " = ptrtoint float* \%t" + vIndex + " to i32");
								// Now, Identifier's value is at the temporary variable \%t[varCount].
								// Therefore, update it.
								$theInfo.theKey = null;
								$theInfo.theType = Type.INT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
								break;
						case DOUBLE:
								// get a new temporary variable and
								// load the variable into the temporary variable.
							
								TextCode.add("\%t" + varCount + " = ptrtoint double* \%t" + vIndex + " to i32");
								// Now, Identifier's value is at the temporary variable \%t[varCount].
								// Therefore, update it.
								$theInfo.theKey = null;
								$theInfo.theType = Type.INT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
								break;
						case CHAR:
								// get a new temporary variable and
								// load the variable into the temporary variable.
								
								TextCode.add("\%t" + varCount + " = ptrtoint i8* \%t" + vIndex + " to i32");
								// Now, Identifier's value is at the temporary variable \%t[varCount].
								// Therefore, update it.
								$theInfo.theKey = null;
								$theInfo.theType = Type.INT;
								$theInfo.theVar.varIndex = varCount;
								varCount ++;
								break;
					
					}
				}
		   | '(' a = logic_arith_expression ')' 
				{
					$theInfo = a;
				}
           ;

constant 
returns [Info theInfo]
@init {theInfo = new Info();}
	: Integer_constant
				{
						$theInfo.theType = Type.CONST_INT;
						$theInfo.theVar.iValue = Integer.parseInt($Integer_constant.text);
						//System.out.println($theInfo.theVar.iValue);
				}
			| Floating_point_constant
				{
						$theInfo.theType = Type.CONST_FLOAT;
						String s = String.format("\%e", Float.parseFloat($Floating_point_constant.text));
						// int i = Float.floatToIntBits($theInfo.theVar.fValue);
						$theInfo.theVar.fValue = s;
						//System.out.println(s);
				}
			| Char
				{    $theInfo.theType = Type.CONST_CHAR;
					//$Char.text.charAt(1);
					$theInfo.theVar.iValue = $Char.text.charAt(1);
					//System.out.println($theInfo.theVar.iValue);
				}
			;
		   
// logic
logic: AND {if (TRACEON) System.out.println("logic: &&");}
	 | OR {if (TRACEON) System.out.println("logic: ||");}
	 | EQ {if (TRACEON) System.out.println("logic: ==");}
	 | LESS {if (TRACEON) System.out.println("logic: <");}
	 | GREATER  {if (TRACEON) System.out.println("logic: >");}
	 | LE  {if (TRACEON) System.out.println("logic: <=");}
	 | GE  {if (TRACEON) System.out.println("logic: >=");}
	 | NE  {if (TRACEON) System.out.println("logic: !=");}
	 ;
	 
// key
key returns [Key keytype]
   : STATIC { if (TRACEON) System.out.println("key: STATIC"); $keytype = Key.STATIC; }
   | SHORT { if (TRACEON) System.out.println("key: SHORT"); $keytype = Key.SHORT; }
   | CONST { if (TRACEON) System.out.println("key: CONST"); $keytype = Key.CONST; }
   | LONG LONG { if (TRACEON) System.out.println("key: LONG LONG"); $keytype = Key.LONG_LONG; }
   | LONG { if (TRACEON) System.out.println("key: LONG"); $keytype = Key.LONG; }
   | SIGNED { if (TRACEON) System.out.println("key: SIGNED"); $keytype = Key.SIGNED; }
   | UNSIGNED { if (TRACEON) System.out.println("key: UNSIGNED"); $keytype = Key.UNSIGNED; }
   | EXTERN { if (TRACEON) System.out.println("key: EXTERN"); $keytype = Key.EXTERN; }
   ;
		   
/* description of the tokens */
FLOAT : 'float';
INT : 'int';
CHAR : 'char';
STRUCT : 'struct';
MAIN : 'main';
VOID : 'void';
DOUBLE : 'double';
BOOL : 'bool';
INCLUDE : 'include';
DEFINE : 'define';

IF : 'if';
ELSE : 'else';

/* function */
PRINTF : 'printf';
SCANF : 'scanf';
STRCMP : 'strcmp';
STRCPY : 'strcpy';
ISDIGIT : 'isdigit';
EXP : 'exp';
LOG : 'log';
LOG10 : 'log10';
POW : 'pow';
SQRT : 'sqrt';
CEIL : 'ceil';
FABS : 'fabs';
FLOOR : 'floor';
RAISE : 'raise';
GETCHAR : 'getchar';
PUTCHAR : 'putchar';
ATOI : 'atoi';
ATOF : 'atof';
ABORT : 'abort';
EXIT : 'exit';
ABS : 'abs';
RAND : 'rand';
STRCAT : 'strcat';
STRCHR : 'strchr';
STRTOK : 'strtok';
STRERROR : 'strerror';
STRSTR : 'strstr';
PERROR : 'perror';

SWITCH : 'switch';
CASE : 'case';
BREAK : 'break';
GOTO : 'goto';
CONTINUE : 'continue';
DEFAULT : 'default';
DO : 'do';
WHILE : 'while';
FOR : 'for';
RETURN : 'return';

SIGNED : 'signed';
UNSIGNED : 'unsigned';
LONG : 'long';
SHORT : 'short';
CONST : 'const';
STATIC : 'static';
EXTERN : 'extern';


BITAND : '&';
BITXOR : '^';
BITOR : '|';
AND : '&&';
OR : '||';
PLUS : '+';
MINUS : '-';
MULTI : '*';
DIV : '/';
MOD : '%';
ASSIGN : '='; 
EQ : '==';
LESS : '<';
GREATER : '>';
LE : '<=';
GE : '>=';
NE : '!=';
PP : '++';
MM : '--';
DIVISA : '/=';
MULTIA : '*=';
MODA : '%=';
PLUSA : '+=';
MINUSA : '-=';
NOT : '!';


LPAREM : '(';
RPAREM : ')';
LBRACKET : '[';
RBRACKET : ']';
LBRACE : '{';
RBRACE : '}';
COMMA : ',';
SEMICOLON : ';';
COLON : ':';
QUE : '\?';
POUND : '#';

LIBRARY :( 'assert.h' | 'ctype.h' | 'errno.h' | 'float.h'
		| 'limits.h' | 'locale.h' | 'math.h' | 'setjmp.h'
		| 'signal.h' | 'stdarg.h' | 'stddef.h' | 'stdio.h'
		| 'stdlib.h' | 'string.h' | 'time.h' ) ;
	
STRING: '"' ( ESCAPE_SEQ | '""' | ~('\\'|'"') )* '"' ;
fragment ESCAPE_SEQ : '\\' ('b'|'t'|'n'|'f'|'r'|'"'|'\''|'\\') ;
fragment OctalEscape : '\\' ( ('0'..'3')
							| ('0'..'3')('0'..'3')
							| ('0'..'3')('0'..'3')('0'..'3') )
					 ;
					 
					 
Identifier:('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;
Integer_constant:'0'..'9'+;
Floating_point_constant:'0'..'9'+ '.' '0'..'9'+;
Char : '\'' ('\\\''|~'\'') '\'';

WS:( ' ' | '\t' | '\r' | '\n' ) {$channel=HIDDEN;};
COMMENT: '/*' .* '*/' {$channel=HIDDEN;};
COMMENT1: '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;};
