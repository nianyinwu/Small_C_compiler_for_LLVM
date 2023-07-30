; ModuleID = 'test2.c'
source_filename = "test2.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@f = global i32 1, align 4
@.str = private unnamed_addr constant [10 x i8] c"%ld %lld\0A\00", align 1
@.str.1 = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1
@.str.2 = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1
@.str.3 = private unnamed_addr constant [7 x i8] c"%f %f\0A\00", align 1
@.str.4 = private unnamed_addr constant [7 x i8] c"%c %c\0A\00", align 1

; Function Attrs: noinline nounwind optnone
define void @main() #0 {
entry:
  %p = alloca i64, align 8
  %pp = alloca i64, align 8
  %gj = alloca i16, align 2
  %b = alloca i16, align 2
  %fk = alloca float, align 4
  %dol = alloca double, align 8
  %ti = alloca i8, align 1
  store i64 123465, i64* %p, align 8
  %0 = load i64, i64* %p, align 8
  %1 = load i64, i64* %p, align 8
  %add = add nsw i64 %0, %1
  store i64 %add, i64* %pp, align 8
  store i16 213, i16* %gj, align 2
  %2 = load i16, i16* %gj, align 2
  %conv = sext i16 %2 to i64
  %3 = load i64, i64* %p, align 8
  %sub = sub nsw i64 %conv, %3
  %conv1 = trunc i64 %sub to i16
  store i16 %conv1, i16* %b, align 2
  store float -5.000000e-01, float* %fk, align 4
  %4 = load float, float* %fk, align 4
  %inc = fadd float %4, 1.000000e+00
  store float %inc, float* %fk, align 4
  %5 = load i32, i32* @f, align 4
  %add2 = add nsw i32 %5, 2
  store i32 %add2, i32* @f, align 4
  %6 = load float, float* %fk, align 4
  %conv3 = fpext float %6 to double
  store double %conv3, double* %dol, align 8
  %7 = load double, double* %dol, align 8
  %inc4 = fadd double %7, 1.000000e+00
  store double %inc4, double* %dol, align 8
  store i8 65, i8* %ti, align 1
  %8 = load i8, i8* %ti, align 1
  %dec = add i8 %8, -1
  store i8 %dec, i8* %ti, align 1
  %9 = load i64, i64* %p, align 8
  %10 = load i64, i64* %pp, align 8
  %call = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([10 x i8], [10 x i8]* @.str, i64 0, i64 0), i64 %9, i64 %10)
  %11 = load i16, i16* %gj, align 2
  %conv5 = sext i16 %11 to i32
  %12 = load i16, i16* %b, align 2
  %conv6 = sext i16 %12 to i32
  %call7 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str.1, i64 0, i64 0), i32 %conv5, i32 %conv6)
  %13 = load i32, i32* @f, align 4
  %call8 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.2, i64 0, i64 0), i32 %13)
  %14 = load float, float* %fk, align 4
  %conv9 = fpext float %14 to double
  %15 = load double, double* %dol, align 8
  %call10 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str.3, i64 0, i64 0), double %conv9, double %15)
  %16 = load i8, i8* %ti, align 1
  %conv11 = sext i8 %16 to i32
  %17 = load i8, i8* %ti, align 1
  %conv12 = sext i8 %17 to i32
  %sub13 = sub nsw i32 %conv12, 46
  %call14 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str.4, i64 0, i64 0), i32 %conv11, i32 %sub13)
  ret void
}

declare i32 @printf(i8*, ...) #1

attributes #0 = { noinline nounwind optnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-features"="+cx8,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pointer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-features"="+cx8,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 10.0.0-4ubuntu1 "}
