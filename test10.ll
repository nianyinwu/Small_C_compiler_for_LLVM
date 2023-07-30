; === prologue ====
@str5 = private unnamed_addr constant [13 x i8] c"Hello World\0A\00"
@str4 = private unnamed_addr constant [7 x i8] c"%d %d\0A\00"
@str3 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@str2 = private unnamed_addr constant [3 x i8] c"%d\00"
@str1 = private unnamed_addr constant [4 x i8] c"%d\0A\00"
declare dso_local i32 @scanf(i8*, ...)

declare dso_local i32 @printf(i8*, ...)

define dso_local i32 @main()
{
%t0 = alloca i32, align 4
%t1 = alloca i32, align 4
store i32 3, i32* %t1, align 4
store i32 5, i32* %t0, align 4
%t2 = load i32, i32* %t0, align 4
%t3 = load i32, i32* %t1, align 4
%t4 = and i32 %t2, %t3
store i32 %t4, i32* %t0, align 4
%t5 = load i32, i32* %t1, align 4
%t6 = sub nsw i32 100, 1
%t7 = mul nsw i32 2, %t6
%t8 = add nsw i32 %t5, %t7
store i32 %t8, i32* %t0, align 4
%t9 = load i32, i32* %t0, align 4
%t10 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str1, i64 0, i64 0), i32 %t9)
%t11 = call i32 (i8*, ...) @scanf(i8* getelementptr inbounds ([3 x i8], [3 x i8]* @str2, i64 0, i64 0), i32* %t0)
br label %L1
L1:
%t12 = load i32, i32* %t0, align 4
%t13 = icmp slt i32 %t12, 100
br i1 %t13, label %L2, label %L3
L2:
%t14 = load i32, i32* %t0, align 4
%t15 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str3, i64 0, i64 0), i32 %t14)
br label %L4
L4:
%t16 = alloca i32, align 4
store i32 10, i32* %t16, align 4
br label %L5
L5:
%t17 = load i32, i32* %t16, align 4
%t18 = icmp sgt i32 %t17, 0
br i1 %t18, label %L6, label %L8
L7:
%t19 = load i32, i32* %t16, align 4
%t20 = sub nsw i32 %t19, 1
store i32 %t20, i32* %t16, align 4
br label %L5
L6:
br label %L9
L9:
%t21 = alloca i32, align 4
store i32 0, i32* %t21, align 4
br label %L10
L10:
%t22 = load i32, i32* %t21, align 4
%t23 = icmp slt i32 %t22, 5
br i1 %t23, label %L11, label %L13
L12:
%t24 = load i32, i32* %t21, align 4
%t25 = add nsw i32 %t24, 1
store i32 %t25, i32* %t21, align 4
br label %L10
L11:
%t26 = load i32, i32* %t16, align 4
%t27 = load i32, i32* %t21, align 4
%t28 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @str4, i64 0, i64 0), i32 %t26, i32 %t27)
br label %L12
L13:
br label %L7
L8:
%t29 = load i32, i32* %t0, align 4
%t30 = add nsw i32 %t29, 20
store i32 %t30, i32* %t0, align 4
br label %L1
L3:
%t31 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([13 x i8], [13 x i8]* @str5, i64 0, i64 0))

; === epilogue ===
ret i32 0
}
