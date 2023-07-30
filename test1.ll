; === prologue ====
@str9 = private unnamed_addr constant [15 x i8] c"a Less than b\0A\00"
@str8 = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@str7 = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@str6 = private unnamed_addr constant [11 x i8] c"a Equal b\0A\00"
@str5 = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@str4 = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@str3 = private unnamed_addr constant [18 x i8] c"a Greater than b\0A\00"
@str2 = private unnamed_addr constant [4 x i8] c"%f\0A\00"
@str1 = private unnamed_addr constant [4 x i8] c"%f\0A\00"
declare dso_local i32 @scanf(i8*, ...)

declare dso_local i32 @printf(i8*, ...)

define dso_local i32 @main()
{
%t0 = alloca float, align 4
store float 1.500000e+01, float* %t0, align 4
%t1 = alloca double, align 8
%t2 = load float, float* %t0, align 4
%t3 = load float, float* %t0, align 4
%t4 = fadd float %t2, %t3
%t5 = fpext float %t4 to double
store double %t5, double* %t1, align 8
%t6 = alloca i32, align 4
store i32 5, i32* %t6, align 4
%t7 = load float, float* %t0, align 4
%t8 = load double, double* %t1, align 8
%t9 = fpext float %t7 to double
%t10 = fcmp ogt double %t9, %t8
br i1 %t10, label %L1, label %L2
L1:
%t11 = load float, float* %t0, align 4
%t12 = fpext float %t11 to double
%t13 = fcmp oeq double %t12, 0x402E000000000000
br i1 %t13, label %L4, label %L5
L4:
%t14 = load float, float* %t0, align 4
%t15 = fpext float %t14 to double
%t16 = fmul double %t15, 0x4000000000000000
%t17 = fptrunc double %t16 to float
store float %t17, float* %t0, align 4
%t18 = load float, float* %t0, align 4
%t19 = fpext float %t18 to double
%t20 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str1, i64 0, i64 0), double %t19)
br label %L6
L5:
%t21 = load float, float* %t0, align 4
%t22 = fpext float %t21 to double
%t23 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str2, i64 0, i64 0), double %t22)
br label %L6
L6:
%t24 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([18 x i8], [18 x i8]* @str3, i64 0, i64 0))
br label %L3
L2:
%t25 = load float, float* %t0, align 4
%t26 = load double, double* %t1, align 8
%t27 = fpext float %t25 to double
%t28 = fcmp oeq double %t27, %t26
br i1 %t28, label %L7, label %L8
L7:
%t29 = load float, float* %t0, align 4
%t30 = fpext float %t29 to double
%t31 = fcmp oeq double %t30, 0x402E000000000000
br i1 %t31, label %L10, label %L11
L10:
%t32 = load float, float* %t0, align 4
%t33 = fpext float %t32 to double
%t34 = fmul double %t33, 0x4000000000000000
%t35 = fptrunc double %t34 to float
store float %t35, float* %t0, align 4
%t36 = load float, float* %t0, align 4
%t37 = fpext float %t36 to double
%t38 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str4, i64 0, i64 0), double %t37)
br label %L12
L11:
%t39 = load float, float* %t0, align 4
%t40 = fpext float %t39 to double
%t41 = fdiv double %t40, 0x4000000000000000
%t42 = fptrunc double %t41 to float
store float %t42, float* %t0, align 4
%t43 = load float, float* %t0, align 4
%t44 = fpext float %t43 to double
%t45 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str5, i64 0, i64 0), double %t44)
br label %L12
L12:
%t46 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @str6, i64 0, i64 0))
br label %L9
L8:
%t47 = load float, float* %t0, align 4
%t48 = fpext float %t47 to double
%t49 = fcmp oeq double %t48, 0x402E000000000000
br i1 %t49, label %L13, label %L14
L13:
%t50 = load float, float* %t0, align 4
%t51 = fpext float %t50 to double
%t52 = fmul double %t51, 0x4000000000000000
%t53 = fptrunc double %t52 to float
store float %t53, float* %t0, align 4
%t54 = load float, float* %t0, align 4
%t55 = fpext float %t54 to double
%t56 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str7, i64 0, i64 0), double %t55)
br label %L15
L14:
%t57 = load float, float* %t0, align 4
%t58 = fpext float %t57 to double
%t59 = fdiv double %t58, 0x4000000000000000
%t60 = fptrunc double %t59 to float
store float %t60, float* %t0, align 4
%t61 = load float, float* %t0, align 4
%t62 = fpext float %t61 to double
%t63 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str8, i64 0, i64 0), double %t62)
br label %L15
L15:
%t64 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([15 x i8], [15 x i8]* @str9, i64 0, i64 0))
br label %L9
L9:
br label %L3
L3:

; === epilogue ===
ret i32 0
}
