; === prologue ====
@str7 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@str6 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@str5 = private unnamed_addr constant [4 x i8] c"%c\0A\00"
@str4 = private unnamed_addr constant [8 x i8] c"odd:%d\0A\00"
@str3 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@str2 = private unnamed_addr constant [9 x i8] c"even:%d\0A\00"
@str1 = private unnamed_addr constant [12 x i8] c"func b: %d\0A\00"
declare dso_local i32 @scanf(i8*, ...)

declare dso_local i32 @printf(i8*, ...)

define dso_local i32 @t0(i32 %t1) {
%t2 = alloca i32, align 4
store i32 %t1, i32* %t2, align 4
%t3 = load i32, i32* %t2, align 4
%t4 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([12 x i8], [12 x i8]* @str1, i64 0, i64 0), i32 %t3)
%t5 = load i32, i32* %t2, align 4
%t6 = add nsw i32 %t5, 10
store i32 %t6, i32* %t2, align 4
%t7 = load i32, i32* %t2, align 4
ret i32 %t7
}
%D1 = type { i32, i8, float}
define dso_local i32 @main()
{
%t9 = alloca i32, align 4
store i32 10, i32* %t9, align 4
br label %L1
L1:
%t10 = load i32, i32* %t9, align 4
%t11 = icmp sgt i32 %t10, 0
br i1 %t11, label %L2, label %L3
L2:
%t12 = load i32, i32* %t9, align 4
%t13 = srem i32 %t12, 2
%t14 = icmp eq i32 %t13, 0
br i1 %t14, label %L4, label %L5
L4:
%t15 = load i32, i32* %t9, align 4
%t16 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([9 x i8], [9 x i8]* @str2, i64 0, i64 0), i32 %t15)
br label %L6
L5:
%t17 = load i32, i32* %t9, align 4
%t18 = icmp sgt i32 %t17, 5
br i1 %t18, label %L7, label %L8
L7:
%t19 = load i32, i32* %t9, align 4
%t20 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str3, i64 0, i64 0), i32 %t19)
br label %L9
L8:
%t21 = load i32, i32* %t9, align 4
%t22 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([8 x i8], [8 x i8]* @str4, i64 0, i64 0), i32 %t21)
br label %L9
L9:
br label %L6
L6:
%t23 = load i32, i32* %t9, align 4
%t24 = sub nsw i32 %t23, 1
store i32 %t24, i32* %t9, align 4
br label %L1
L3:
%t25 = alloca i8, align 1
store i8 65, i8* %t25, align 1
%t26 = load i8, i8* %t25, align 1
%t27 = sext i8 %t26 to i32
%t28 = add nsw i32 %t27, 49
%t29 = trunc i32 %t28 to i8
store i8 %t29, i8* %t25, align 1
%t30 = load i8, i8* %t25, align 1
%t31 = sext i8 %t30 to i32
%t32 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str5, i64 0, i64 0), i32 %t31)
%t33 = alloca i32, align 4
%t34 = load i32, i32* %t9, align 4
%t35 = call i32 @t0(i32 %t34)
store i32 %t35, i32* %t33, align 4
%t36 = load i32, i32* %t33, align 4
%t37 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str6, i64 0, i64 0), i32 %t36)
%t38 = call i32 @t0(i32 10)
store i32 %t38, i32* %t33, align 4
%t39 = load i32, i32* %t33, align 4
%t40 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str7, i64 0, i64 0), i32 %t39)

; === epilogue ===
ret i32 0
}
