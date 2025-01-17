; RUN: llc -mtriple=arm64-apple-darwin -mattr=+reserve-x18                             < %s | FileCheck %s
; RUN: llc -mtriple=arm64-apple-darwin -mattr=+reserve-x18 -fast-isel -fast-isel-abort=1 < %s | FileCheck %s
;
; Note: Print verbose stackmaps using -debug-only=stackmaps.

; We are not getting the correct stack alignment when cross compiling for arm64.
; So specify a datalayout here.
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"

; CHECK-LABEL:  .section  __LLVM_STACKMAPS,__llvm_stackmaps
; CHECK-NEXT:  __LLVM_StackMaps:
; Header
; CHECK-NEXT:   .byte 3
; CHECK-NEXT:   .byte 0
; CHECK-NEXT:   .short 0
; Num Functions
; CHECK-NEXT:   .long 11
; Num LargeConstants
; CHECK-NEXT:   .long 3
; Num Callsites
; CHECK-NEXT:   .long 11

; Functions and stack size
; CHECK-NEXT:   .quad _constantargs
; CHECK-NEXT:   .quad 16
; CHECK-NEXT:   .quad 1
; CHECK-NEXT:   .quad _osrinline
; CHECK-NEXT:   .quad 32
; CHECK-NEXT:   .quad 1
; CHECK-NEXT:   .quad _osrcold
; CHECK-NEXT:   .quad 16
; CHECK-NEXT:   .quad 1
; CHECK-NEXT:   .quad _propertyRead
; CHECK-NEXT:   .quad 16
; CHECK-NEXT:   .quad 1
; CHECK-NEXT:   .quad _propertyWrite
; CHECK-NEXT:   .quad 16
; CHECK-NEXT:   .quad 1
; CHECK-NEXT:   .quad _jsVoidCall
; CHECK-NEXT:   .quad 16
; CHECK-NEXT:   .quad 1
; CHECK-NEXT:   .quad _jsIntCall
; CHECK-NEXT:   .quad 16
; CHECK-NEXT:   .quad 1
; CHECK-NEXT:   .quad _spilledValue
; CHECK-NEXT:   .quad 160
; CHECK-NEXT:   .quad 1
; CHECK-NEXT:   .quad _spilledStackMapValue
; CHECK-NEXT:   .quad 128
; CHECK-NEXT:   .quad 1
; CHECK-NEXT:   .quad _liveConstant
; CHECK-NEXT:   .quad 16
; CHECK-NEXT:   .quad 1
; CHECK-NEXT:   .quad _clobberLR
; CHECK-NEXT:   .quad 112
; CHECK-NEXT:   .quad 1

; Num LargeConstants
; CHECK-NEXT:   .quad   4294967295
; CHECK-NEXT:   .quad   4294967296
; CHECK-NEXT:   .quad   4294967297

; Constant arguments
;
; CHECK-NEXT:   .quad   1
; CHECK-NEXT:   .long   L{{.*}}-_constantargs
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  6
; SmallConstant
; CHECK-NEXT:   .byte   4
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   65535
; SmallConstant
; CHECK-NEXT:   .byte   4
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   65536
; LargeConstant at index 0
; CHECK-NEXT:   .byte   5
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   0
; LargeConstant at index 1
; CHECK-NEXT:   .byte   5
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   1
; SmallConstant
; CHECK-NEXT:   .byte   4
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   66
; LargeConstant at index 2
; CHECK-NEXT:   .byte   5
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   2

define void @constantargs() {
entry:
  %0 = inttoptr i64 244837814094590 to i8*
  tail call void (i64, i32, i8*, i32, ...) @llvm.experimental.patchpoint.void(i64 1, i32 20, i8* %0, i32 0, i64 65535, i64 65536, i64 4294967295, i64 4294967296, i128 66, i128 4294967297)
  ret void
}

; Inline OSR Exit
;
; CHECK-LABEL:  .long   L{{.*}}-_osrinline
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  2
; CHECK-NEXT:   .byte   1
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  {{[0-9]+}}
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   0
; CHECK-NEXT:   .byte   1
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  {{[0-9]+}}
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long  0
define void @osrinline(i64 %a, i64 %b) {
entry:
  ; Runtime void->void call.
  call void inttoptr (i64 244837814094590 to void ()*)()
  ; Followed by inline OSR patchpoint with 12-byte shadow and 2 live vars.
  call void (i64, i32, ...) @llvm.experimental.stackmap(i64 3, i32 12, i64 %a, i64 %b)
  ret void
}

; Cold OSR Exit
;
; 2 live variables in register.
;
; CHECK-LABEL:  .long   L{{.*}}-_osrcold
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  2
; CHECK-NEXT:   .byte   1
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  {{[0-9]+}}
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   0
; CHECK-NEXT:   .byte   1
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  {{[0-9]+}}
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long  0
define void @osrcold(i64 %a, i64 %b) {
entry:
  %test = icmp slt i64 %a, %b
  br i1 %test, label %ret, label %cold
cold:
  ; OSR patchpoint with 12-byte nop-slide and 2 live vars.
  %thunk = inttoptr i64 244837814094590 to i8*
  call void (i64, i32, i8*, i32, ...) @llvm.experimental.patchpoint.void(i64 4, i32 20, i8* %thunk, i32 0, i64 %a, i64 %b)
  unreachable
ret:
  ret void
}

; Property Read
; CHECK-LABEL:  .long   L{{.*}}-_propertyRead
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  0
;
; FIXME: There are currently no stackmap entries. After moving to
; AnyRegCC, we will have entries for the object and return value.
define i64 @propertyRead(i64* %obj) {
entry:
  %resolveRead = inttoptr i64 244837814094590 to i8*
  %result = call i64 (i64, i32, i8*, i32, ...) @llvm.experimental.patchpoint.i64(i64 5, i32 20, i8* %resolveRead, i32 1, i64* %obj)
  %add = add i64 %result, 3
  ret i64 %add
}

; Property Write
; CHECK-LABEL:  .long   L{{.*}}-_propertyWrite
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  2
; CHECK-NEXT:   .byte   1
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  {{[0-9]+}}
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   0
; CHECK-NEXT:   .byte   1
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  {{[0-9]+}}
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   0
define void @propertyWrite(i64 %dummy1, i64* %obj, i64 %dummy2, i64 %a) {
entry:
  %resolveWrite = inttoptr i64 244837814094590 to i8*
  call anyregcc void (i64, i32, i8*, i32, ...) @llvm.experimental.patchpoint.void(i64 6, i32 20, i8* %resolveWrite, i32 2, i64* %obj, i64 %a)
  ret void
}

; Void JS Call
;
; 2 live variables in registers.
;
; CHECK-LABEL:  .long   L{{.*}}-_jsVoidCall
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  2
; CHECK-NEXT:   .byte   1
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  {{[0-9]+}}
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   0
; CHECK-NEXT:   .byte   1
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  {{[0-9]+}}
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   0
define void @jsVoidCall(i64 %dummy1, i64* %obj, i64 %arg, i64 %l1, i64 %l2) {
entry:
  %resolveCall = inttoptr i64 244837814094590 to i8*
  call void (i64, i32, i8*, i32, ...) @llvm.experimental.patchpoint.void(i64 7, i32 20, i8* %resolveCall, i32 2, i64* %obj, i64 %arg, i64 %l1, i64 %l2)
  ret void
}

; i64 JS Call
;
; 2 live variables in registers.
;
; CHECK-LABEL:  .long   L{{.*}}-_jsIntCall
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  2
; CHECK-NEXT:   .byte   1
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  {{[0-9]+}}
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   0
; CHECK-NEXT:   .byte   1
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  {{[0-9]+}}
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   0
define i64 @jsIntCall(i64 %dummy1, i64* %obj, i64 %arg, i64 %l1, i64 %l2) {
entry:
  %resolveCall = inttoptr i64 244837814094590 to i8*
  %result = call i64 (i64, i32, i8*, i32, ...) @llvm.experimental.patchpoint.i64(i64 8, i32 20, i8* %resolveCall, i32 2, i64* %obj, i64 %arg, i64 %l1, i64 %l2)
  %add = add i64 %result, 3
  ret i64 %add
}

; Spilled stack map values.
;
; Verify 28 stack map entries.
;
; CHECK-LABEL:  .long L{{.*}}-_spilledValue
; CHECK-NEXT:   .short 0
; CHECK-NEXT:   .short 28
;
; Check that at least one is a spilled entry from RBP.
; Location: Indirect FP + ...
; CHECK:        .byte 3
; CHECK-NEXT:   .byte 0
; CHECK-NEXT:   .short 
; CHECK-NEXT:   .short 29
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long
define void @spilledValue(i64 %arg0, i64 %arg1, i64 %arg2, i64 %arg3, i64 %arg4, i64 %l0, i64 %l1, i64 %l2, i64 %l3, i64 %l4, i64 %l5, i64 %l6, i64 %l7, i64 %l8, i64 %l9, i64 %l10, i64 %l11, i64 %l12, i64 %l13, i64 %l14, i64 %l15, i64 %l16, i64 %l17, i64 %l18, i64 %l19, i64 %l20, i64 %l21, i64 %l22, i64 %l23, i64 %l24, i64 %l25, i64 %l26, i64 %l27) {
entry:
  call void (i64, i32, i8*, i32, ...) @llvm.experimental.patchpoint.void(i64 11, i32 20, i8* null, i32 5, i64 %arg0, i64 %arg1, i64 %arg2, i64 %arg3, i64 %arg4, i64 %l0, i64 %l1, i64 %l2, i64 %l3, i64 %l4, i64 %l5, i64 %l6, i64 %l7, i64 %l8, i64 %l9, i64 %l10, i64 %l11, i64 %l12, i64 %l13, i64 %l14, i64 %l15, i64 %l16, i64 %l17, i64 %l18, i64 %l19, i64 %l20, i64 %l21, i64 %l22, i64 %l23, i64 %l24, i64 %l25, i64 %l26, i64 %l27)
  ret void
}

; Spilled stack map values.
;
; Verify 23 stack map entries.
;
; CHECK-LABEL:  .long L{{.*}}-_spilledStackMapValue
; CHECK-NEXT:   .short 0
; CHECK-NEXT:   .short 30
;
; Check that at least one is a spilled entry from RBP.
; Location: Indirect FP + ...
; CHECK:        .byte 3
; CHECK-NEXT:   .byte 0
; CHECK-NEXT:   .short 
; CHECK-NEXT:   .short 29
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long
define webkit_jscc void @spilledStackMapValue(i64 %l0, i64 %l1, i64 %l2, i64 %l3, i64 %l4, i64 %l5, i64 %l6, i64 %l7, i64 %l8, i64 %l9, i64 %l10, i64 %l11, i64 %l12, i64 %l13, i64 %l14, i64 %l15, i64 %l16, i64 %l17, i64 %l18, i64 %l19, i64 %l20, i64 %l21, i64 %l22, i64 %l23, i64 %l24, i64 %l25, i64 %l26, i64 %l27, i64 %l28, i64 %l29) {
entry:
  call void (i64, i32, ...) @llvm.experimental.stackmap(i64 12, i32 16, i64 %l0, i64 %l1, i64 %l2, i64 %l3, i64 %l4, i64 %l5, i64 %l6, i64 %l7, i64 %l8, i64 %l9, i64 %l10, i64 %l11, i64 %l12, i64 %l13, i64 %l14, i64 %l15, i64 %l16, i64 %l17, i64 %l18, i64 %l19, i64 %l20, i64 %l21, i64 %l22, i64 %l23, i64 %l24, i64 %l25, i64 %l26, i64 %l27, i64 %l28, i64 %l29)
  ret void
}


; Map a constant value.
;
; CHECK-LABEL:  .long L{{.*}}-_liveConstant
; CHECK-NEXT:   .short 0
; 1 location
; CHECK-NEXT:   .short 1
; Loc 0: SmallConstant
; CHECK-NEXT:   .byte   4
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  8
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   33

define void @liveConstant() {
  tail call void (i64, i32, ...) @llvm.experimental.stackmap(i64 15, i32 8, i32 33)
  ret void
}

; Map a value when LR is the only free register.
;
; CHECK-LABEL:  .long L{{.*}}-_clobberLR
; CHECK-NEXT:   .short 0
; 1 location
; CHECK-NEXT:   .short 1
; Loc 0: Indirect FP (r29) - offset
; CHECK-NEXT:   .byte   3
; CHECK-NEXT:   .byte   0
; CHECK-NEXT:   .short  4
; CHECK-NEXT:   .short  29
; CHECK-NEXT:   .short  0
; CHECK-NEXT:   .long   -{{[0-9]+}}
define void @clobberLR(i32 %a) {
  tail call void asm sideeffect "nop", "~{x0},~{x1},~{x2},~{x3},~{x4},~{x5},~{x6},~{x7},~{x8},~{x9},~{x10},~{x11},~{x12},~{x13},~{x14},~{x15},~{x16},~{x17},~{x18},~{x19},~{x20},~{x21},~{x22},~{x23},~{x24},~{x25},~{x26},~{x27},~{x28},~{x29},~{x31}"() nounwind
  tail call void (i64, i32, ...) @llvm.experimental.stackmap(i64 16, i32 8, i32 %a)
  ret void
}

declare void @llvm.experimental.stackmap(i64, i32, ...)
declare void @llvm.experimental.patchpoint.void(i64, i32, i8*, i32, ...)
declare i64 @llvm.experimental.patchpoint.i64(i64, i32, i8*, i32, ...)
