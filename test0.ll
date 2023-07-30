; === prologue ====
@str14 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@str13 = private unnamed_addr constant [11 x i8] c"case 0:%d\0A\00"
@str12 = private unnamed_addr constant [12 x i8] c"case 10:%d\0A\00"
@str11 = private unnamed_addr constant [11 x i8] c"case 9:%d\0A\00"
@str10 = private unnamed_addr constant [11 x i8] c"case 8:%d\0A\00"
@str9 = private unnamed_addr constant [11 x i8] c"case 7:%d\0A\00"
@str8 = private unnamed_addr constant [11 x i8] c"case 6:%d\0A\00"
@str7 = private unnamed_addr constant [11 x i8] c"case 5:%d\0A\00"
@str6 = private unnamed_addr constant [11 x i8] c"case 4:%d\0A\00"
@str5 = private unnamed_addr constant [11 x i8] c"case 3:%d\0A\00"
@str4 = private unnamed_addr constant [11 x i8] c"case 2:%d\0A\00"
@str3 = private unnamed_addr constant [11 x i8] c"case 1:%d\0A\00"
@str2 = private unnamed_addr constant [12 x i8] c"cur a = %d\0A\00"
@str1 = private unnamed_addr constant [3 x i8] c"%d\00"
declare dso_local i32 @scanf(i8*, ...)

declare dso_local i32 @printf(i8*, ...)

define dso_local i32 @main()
{
%t0 = alloca i32, align 4
%t1 = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds ([3 x i8], [3 x i8]* @str1, i64 0, i64 0), i32* %t0)
br label %L1
L1:
%t2 = alloca i32, align 4
%t3 = load i32, i32* %t0, align 4
store i32 %t3, i32* %t2, align 4
br label %L2
L2:
%t4 = load i32, i32* %t2, align 4
%t5 = icmp slt i32 %t4, 11
br i1 %t5, label %L3, label %L5
L4:
%t6 = load i32, i32* %t2, align 4
%t7 = add nsw i32 %t6, 1
store i32 %t7, i32* %t2, align 4
br label %L2
L3:
%t8 = load i32, i32* %t2, align 4
store i32 %t8, i32* %t0, align 4
%t9 = load i32, i32* %t0, align 4
%t10 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @str2, i64 0, i64 0), i32 %t9)
%t11 = load i32, i32* %t0, align 4
switch i32 %t11, label %L18[
 i32 1, label %L6
 i32 2, label %L8
 i32 3, label %L9
 i32 4, label %L10
 i32 5, label %L11
 i32 6, label %L12
 i32 7, label %L13
 i32 8, label %L14
 i32 9, label %L15
 i32 10, label %L16
 i32 0, label %L17
]
L6:
%t12 = load i32, i32* %t0, align 4
%t13 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @str3, i64 0, i64 0), i32 %t12)
br label %L7
L8:
%t14 = load i32, i32* %t0, align 4
%t15 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @str4, i64 0, i64 0), i32 %t14)
br label %L7
L9:
%t16 = load i32, i32* %t0, align 4
%t17 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @str5, i64 0, i64 0), i32 %t16)
br label %L7
L10:
%t18 = load i32, i32* %t0, align 4
%t19 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @str6, i64 0, i64 0), i32 %t18)
br label %L7
L11:
%t20 = load i32, i32* %t0, align 4
%t21 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @str7, i64 0, i64 0), i32 %t20)
br label %L7
L12:
%t22 = load i32, i32* %t0, align 4
%t23 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @str8, i64 0, i64 0), i32 %t22)
br label %L7
L13:
%t24 = load i32, i32* %t0, align 4
%t25 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @str9, i64 0, i64 0), i32 %t24)
br label %L7
L14:
%t26 = load i32, i32* %t0, align 4
%t27 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @str10, i64 0, i64 0), i32 %t26)
br label %L7
L15:
%t28 = load i32, i32* %t0, align 4
%t29 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @str11, i64 0, i64 0), i32 %t28)
br label %L7
L16:
%t30 = load i32, i32* %t0, align 4
%t31 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @str12, i64 0, i64 0), i32 %t30)
br label %L7
L17:
%t32 = load i32, i32* %t0, align 4
%t33 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @str13, i64 0, i64 0), i32 %t32)
br label %L7
L18:
br label %L7
L7:
br label %L4
L5:
%t34 = load i32, i32* %t0, align 4
%t35 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str14, i64 0, i64 0), i32 %t34)

; === epilogue ===
ret i32 0
}
