; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; NOTE: Assertions have been autogenerated by update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+sse2 | FileCheck %s

@c = external global i32*, align 8

; %val1 = load <2 x i8>
; %op1 = zext<2 x i32> %val1
; %val2 = load <2 x i8>
; %op2 = zext<2 x i32> %val2
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi8(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_2xi8:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movzwl (%rdi,%rdx), %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    movzwl (%rsi,%rdx), %ecx
; CHECK-NEXT:    movd %ecx, %xmm1
; CHECK-NEXT:    pxor %xmm2, %xmm2
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3],xmm0[4],xmm2[4],xmm0[5],xmm2[5],xmm0[6],xmm2[6],xmm0[7],xmm2[7]
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1],xmm1[2],xmm2[2],xmm1[3],xmm2[3],xmm1[4],xmm2[4],xmm1[5],xmm2[5],xmm1[6],xmm2[6],xmm1[7],xmm2[7]
; CHECK-NEXT:    pmullw %xmm0, %xmm1
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1],xmm1[2],xmm2[2],xmm1[3],xmm2[3]
; CHECK-NEXT:    movq %xmm1, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i8>*
  %wide.load = load <2 x i8>, <2 x i8>* %tmp7, align 1
  %tmp8 = zext <2 x i8> %wide.load to <2 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <2 x i8>*
  %wide.load17 = load <2 x i8>, <2 x i8>* %tmp11, align 1
  %tmp12 = zext <2 x i8> %wide.load17 to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <4 x i8>
; %op1 = zext<4 x i32> %val1
; %val2 = load <4 x i8>
; %op2 = zext<4 x i32> %val2
; %rst = mul <4 x i32> %op1, %op2
;
define void @mul_4xi8(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_4xi8:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movd {{.*#+}} xmm0 = mem[0],zero,zero,zero
; CHECK-NEXT:    movd {{.*#+}} xmm1 = mem[0],zero,zero,zero
; CHECK-NEXT:    pxor %xmm2, %xmm2
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3],xmm0[4],xmm2[4],xmm0[5],xmm2[5],xmm0[6],xmm2[6],xmm0[7],xmm2[7]
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1],xmm1[2],xmm2[2],xmm1[3],xmm2[3],xmm1[4],xmm2[4],xmm1[5],xmm2[5],xmm1[6],xmm2[6],xmm1[7],xmm2[7]
; CHECK-NEXT:    pmullw %xmm0, %xmm1
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1],xmm1[2],xmm2[2],xmm1[3],xmm2[3]
; CHECK-NEXT:    movdqu %xmm1, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <4 x i8>*
  %wide.load = load <4 x i8>, <4 x i8>* %tmp7, align 1
  %tmp8 = zext <4 x i8> %wide.load to <4 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <4 x i8>*
  %wide.load17 = load <4 x i8>, <4 x i8>* %tmp11, align 1
  %tmp12 = zext <4 x i8> %wide.load17 to <4 x i32>
  %tmp13 = mul nuw nsw <4 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <4 x i32>*
  store <4 x i32> %tmp13, <4 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <8 x i8>
; %op1 = zext<8 x i32> %val1
; %val2 = load <8 x i8>
; %op2 = zext<8 x i32> %val2
; %rst = mul <8 x i32> %op1, %op2
;
define void @mul_8xi8(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_8xi8:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; CHECK-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; CHECK-NEXT:    pxor %xmm2, %xmm2
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3],xmm0[4],xmm2[4],xmm0[5],xmm2[5],xmm0[6],xmm2[6],xmm0[7],xmm2[7]
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1],xmm1[2],xmm2[2],xmm1[3],xmm2[3],xmm1[4],xmm2[4],xmm1[5],xmm2[5],xmm1[6],xmm2[6],xmm1[7],xmm2[7]
; CHECK-NEXT:    pmullw %xmm0, %xmm1
; CHECK-NEXT:    movdqa %xmm1, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3]
; CHECK-NEXT:    punpckhwd {{.*#+}} xmm1 = xmm1[4],xmm2[4],xmm1[5],xmm2[5],xmm1[6],xmm2[6],xmm1[7],xmm2[7]
; CHECK-NEXT:    movdqu %xmm1, 16(%rax,%rdx,4)
; CHECK-NEXT:    movdqu %xmm0, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <8 x i8>*
  %wide.load = load <8 x i8>, <8 x i8>* %tmp7, align 1
  %tmp8 = zext <8 x i8> %wide.load to <8 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <8 x i8>*
  %wide.load17 = load <8 x i8>, <8 x i8>* %tmp11, align 1
  %tmp12 = zext <8 x i8> %wide.load17 to <8 x i32>
  %tmp13 = mul nuw nsw <8 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <8 x i32>*
  store <8 x i32> %tmp13, <8 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <16 x i8>
; %op1 = zext<16 x i32> %val1
; %val2 = load <16 x i8>
; %op2 = zext<16 x i32> %val2
; %rst = mul <16 x i32> %op1, %op2
;
define void @mul_16xi8(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_16xi8:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movdqu (%rdi,%rdx), %xmm0
; CHECK-NEXT:    movdqu (%rsi,%rdx), %xmm1
; CHECK-NEXT:    pxor %xmm2, %xmm2
; CHECK-NEXT:    movdqa %xmm0, %xmm3
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm3 = xmm3[0],xmm2[0],xmm3[1],xmm2[1],xmm3[2],xmm2[2],xmm3[3],xmm2[3],xmm3[4],xmm2[4],xmm3[5],xmm2[5],xmm3[6],xmm2[6],xmm3[7],xmm2[7]
; CHECK-NEXT:    movdqa %xmm1, %xmm4
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm4 = xmm4[0],xmm2[0],xmm4[1],xmm2[1],xmm4[2],xmm2[2],xmm4[3],xmm2[3],xmm4[4],xmm2[4],xmm4[5],xmm2[5],xmm4[6],xmm2[6],xmm4[7],xmm2[7]
; CHECK-NEXT:    pmullw %xmm3, %xmm4
; CHECK-NEXT:    movdqa %xmm4, %xmm3
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm3 = xmm3[0],xmm2[0],xmm3[1],xmm2[1],xmm3[2],xmm2[2],xmm3[3],xmm2[3]
; CHECK-NEXT:    punpckhwd {{.*#+}} xmm4 = xmm4[4],xmm2[4],xmm4[5],xmm2[5],xmm4[6],xmm2[6],xmm4[7],xmm2[7]
; CHECK-NEXT:    punpckhbw {{.*#+}} xmm0 = xmm0[8],xmm2[8],xmm0[9],xmm2[9],xmm0[10],xmm2[10],xmm0[11],xmm2[11],xmm0[12],xmm2[12],xmm0[13],xmm2[13],xmm0[14],xmm2[14],xmm0[15],xmm2[15]
; CHECK-NEXT:    punpckhbw {{.*#+}} xmm1 = xmm1[8],xmm2[8],xmm1[9],xmm2[9],xmm1[10],xmm2[10],xmm1[11],xmm2[11],xmm1[12],xmm2[12],xmm1[13],xmm2[13],xmm1[14],xmm2[14],xmm1[15],xmm2[15]
; CHECK-NEXT:    pmullw %xmm0, %xmm1
; CHECK-NEXT:    movdqa %xmm1, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3]
; CHECK-NEXT:    punpckhwd {{.*#+}} xmm1 = xmm1[4],xmm2[4],xmm1[5],xmm2[5],xmm1[6],xmm2[6],xmm1[7],xmm2[7]
; CHECK-NEXT:    movdqu %xmm1, 48(%rax,%rdx,4)
; CHECK-NEXT:    movdqu %xmm0, 32(%rax,%rdx,4)
; CHECK-NEXT:    movdqu %xmm4, 16(%rax,%rdx,4)
; CHECK-NEXT:    movdqu %xmm3, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <16 x i8>*
  %wide.load = load <16 x i8>, <16 x i8>* %tmp7, align 1
  %tmp8 = zext <16 x i8> %wide.load to <16 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <16 x i8>*
  %wide.load17 = load <16 x i8>, <16 x i8>* %tmp11, align 1
  %tmp12 = zext <16 x i8> %wide.load17 to <16 x i32>
  %tmp13 = mul nuw nsw <16 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <16 x i32>*
  store <16 x i32> %tmp13, <16 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <2 x i16>
; %op1 = zext<2 x i32> %val1
; %val2 = load <2 x i16>
; %op2 = zext<2 x i32> %val2
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi16(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_2xi16:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movd {{.*#+}} xmm0 = mem[0],zero,zero,zero
; CHECK-NEXT:    movd {{.*#+}} xmm1 = mem[0],zero,zero,zero
; CHECK-NEXT:    movdqa %xmm1, %xmm2
; CHECK-NEXT:    pmulhuw %xmm0, %xmm2
; CHECK-NEXT:    pmullw %xmm0, %xmm1
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1],xmm1[2],xmm2[2],xmm1[3],xmm2[3]
; CHECK-NEXT:    movq %xmm1, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i16>*
  %wide.load = load <2 x i16>, <2 x i16>* %tmp7, align 1
  %tmp8 = zext <2 x i16> %wide.load to <2 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <2 x i16>*
  %wide.load17 = load <2 x i16>, <2 x i16>* %tmp11, align 1
  %tmp12 = zext <2 x i16> %wide.load17 to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <4 x i16>
; %op1 = zext<4 x i32> %val1
; %val2 = load <4 x i16>
; %op2 = zext<4 x i32> %val2
; %rst = mul <4 x i32> %op1, %op2
;
define void @mul_4xi16(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_4xi16:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movq {{.*#+}} xmm0 = mem[0],zero
; CHECK-NEXT:    movq {{.*#+}} xmm1 = mem[0],zero
; CHECK-NEXT:    movdqa %xmm1, %xmm2
; CHECK-NEXT:    pmulhuw %xmm0, %xmm2
; CHECK-NEXT:    pmullw %xmm0, %xmm1
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1],xmm1[2],xmm2[2],xmm1[3],xmm2[3]
; CHECK-NEXT:    movdqu %xmm1, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <4 x i16>*
  %wide.load = load <4 x i16>, <4 x i16>* %tmp7, align 1
  %tmp8 = zext <4 x i16> %wide.load to <4 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <4 x i16>*
  %wide.load17 = load <4 x i16>, <4 x i16>* %tmp11, align 1
  %tmp12 = zext <4 x i16> %wide.load17 to <4 x i32>
  %tmp13 = mul nuw nsw <4 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <4 x i32>*
  store <4 x i32> %tmp13, <4 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <8 x i16>
; %op1 = zext<8 x i32> %val1
; %val2 = load <8 x i16>
; %op2 = zext<8 x i32> %val2
; %rst = mul <8 x i32> %op1, %op2
;
define void @mul_8xi16(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_8xi16:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movdqu (%rdi,%rdx), %xmm0
; CHECK-NEXT:    movdqu (%rsi,%rdx), %xmm1
; CHECK-NEXT:    movdqa %xmm1, %xmm2
; CHECK-NEXT:    pmulhuw %xmm0, %xmm2
; CHECK-NEXT:    pmullw %xmm0, %xmm1
; CHECK-NEXT:    movdqa %xmm1, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3]
; CHECK-NEXT:    punpckhwd {{.*#+}} xmm1 = xmm1[4],xmm2[4],xmm1[5],xmm2[5],xmm1[6],xmm2[6],xmm1[7],xmm2[7]
; CHECK-NEXT:    movdqu %xmm1, 16(%rax,%rdx,4)
; CHECK-NEXT:    movdqu %xmm0, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <8 x i16>*
  %wide.load = load <8 x i16>, <8 x i16>* %tmp7, align 1
  %tmp8 = zext <8 x i16> %wide.load to <8 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <8 x i16>*
  %wide.load17 = load <8 x i16>, <8 x i16>* %tmp11, align 1
  %tmp12 = zext <8 x i16> %wide.load17 to <8 x i32>
  %tmp13 = mul nuw nsw <8 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <8 x i32>*
  store <8 x i32> %tmp13, <8 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <16 x i16>
; %op1 = zext<16 x i32> %val1
; %val2 = load <16 x i16>
; %op2 = zext<16 x i32> %val2
; %rst = mul <16 x i32> %op1, %op2
;
define void @mul_16xi16(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_16xi16:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movdqu (%rdi,%rdx), %xmm0
; CHECK-NEXT:    movdqu 16(%rdi,%rdx), %xmm1
; CHECK-NEXT:    movdqu (%rsi,%rdx), %xmm2
; CHECK-NEXT:    movdqu 16(%rsi,%rdx), %xmm3
; CHECK-NEXT:    movdqa %xmm2, %xmm4
; CHECK-NEXT:    pmulhuw %xmm0, %xmm4
; CHECK-NEXT:    pmullw %xmm0, %xmm2
; CHECK-NEXT:    movdqa %xmm2, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm4[0],xmm0[1],xmm4[1],xmm0[2],xmm4[2],xmm0[3],xmm4[3]
; CHECK-NEXT:    punpckhwd {{.*#+}} xmm2 = xmm2[4],xmm4[4],xmm2[5],xmm4[5],xmm2[6],xmm4[6],xmm2[7],xmm4[7]
; CHECK-NEXT:    movdqa %xmm3, %xmm4
; CHECK-NEXT:    pmulhuw %xmm1, %xmm4
; CHECK-NEXT:    pmullw %xmm1, %xmm3
; CHECK-NEXT:    movdqa %xmm3, %xmm1
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm4[0],xmm1[1],xmm4[1],xmm1[2],xmm4[2],xmm1[3],xmm4[3]
; CHECK-NEXT:    punpckhwd {{.*#+}} xmm3 = xmm3[4],xmm4[4],xmm3[5],xmm4[5],xmm3[6],xmm4[6],xmm3[7],xmm4[7]
; CHECK-NEXT:    movdqu %xmm3, 48(%rax,%rdx,4)
; CHECK-NEXT:    movdqu %xmm1, 32(%rax,%rdx,4)
; CHECK-NEXT:    movdqu %xmm2, 16(%rax,%rdx,4)
; CHECK-NEXT:    movdqu %xmm0, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <16 x i16>*
  %wide.load = load <16 x i16>, <16 x i16>* %tmp7, align 1
  %tmp8 = zext <16 x i16> %wide.load to <16 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <16 x i16>*
  %wide.load17 = load <16 x i16>, <16 x i16>* %tmp11, align 1
  %tmp12 = zext <16 x i16> %wide.load17 to <16 x i32>
  %tmp13 = mul nuw nsw <16 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <16 x i32>*
  store <16 x i32> %tmp13, <16 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <2 x i8>
; %op1 = sext<2 x i32> %val1
; %val2 = load <2 x i8>
; %op2 = sext<2 x i32> %val2
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi8_sext(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_2xi8_sext:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movzwl (%rdi,%rdx), %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    movzwl (%rsi,%rdx), %ecx
; CHECK-NEXT:    movd %ecx, %xmm1
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7]
; CHECK-NEXT:    psraw $8, %xmm0
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7]
; CHECK-NEXT:    psraw $8, %xmm1
; CHECK-NEXT:    pmullw %xmm0, %xmm1
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1],xmm0[2],xmm1[2],xmm0[3],xmm1[3]
; CHECK-NEXT:    psrad $16, %xmm0
; CHECK-NEXT:    movq %xmm0, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i8>*
  %wide.load = load <2 x i8>, <2 x i8>* %tmp7, align 1
  %tmp8 = sext <2 x i8> %wide.load to <2 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <2 x i8>*
  %wide.load17 = load <2 x i8>, <2 x i8>* %tmp11, align 1
  %tmp12 = sext <2 x i8> %wide.load17 to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <2 x i8>
; %op1 = sext<2 x i32> %val1
; %val2 = load <2 x i8>
; %op2 = zext<2 x i32> %val2
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi8_sext_zext(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_2xi8_sext_zext:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movzwl (%rdi,%rdx), %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    movzwl (%rsi,%rdx), %ecx
; CHECK-NEXT:    movd %ecx, %xmm1
; CHECK-NEXT:    pxor %xmm2, %xmm2
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1],xmm1[2],xmm2[2],xmm1[3],xmm2[3],xmm1[4],xmm2[4],xmm1[5],xmm2[5],xmm1[6],xmm2[6],xmm1[7],xmm2[7]
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7]
; CHECK-NEXT:    psraw $8, %xmm0
; CHECK-NEXT:    movdqa %xmm1, %xmm2
; CHECK-NEXT:    pmulhw %xmm0, %xmm2
; CHECK-NEXT:    pmullw %xmm1, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3]
; CHECK-NEXT:    movq %xmm0, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i8>*
  %wide.load = load <2 x i8>, <2 x i8>* %tmp7, align 1
  %tmp8 = sext <2 x i8> %wide.load to <2 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <2 x i8>*
  %wide.load17 = load <2 x i8>, <2 x i8>* %tmp11, align 1
  %tmp12 = zext <2 x i8> %wide.load17 to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <2 x i16>
; %op1 = sext<2 x i32> %val1
; %val2 = load <2 x i16>
; %op2 = sext<2 x i32> %val2
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi16_sext(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_2xi16_sext:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movd {{.*#+}} xmm0 = mem[0],zero,zero,zero
; CHECK-NEXT:    movd {{.*#+}} xmm1 = mem[0],zero,zero,zero
; CHECK-NEXT:    movdqa %xmm1, %xmm2
; CHECK-NEXT:    pmulhw %xmm0, %xmm2
; CHECK-NEXT:    pmullw %xmm0, %xmm1
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1],xmm1[2],xmm2[2],xmm1[3],xmm2[3]
; CHECK-NEXT:    movq %xmm1, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i16>*
  %wide.load = load <2 x i16>, <2 x i16>* %tmp7, align 1
  %tmp8 = sext <2 x i16> %wide.load to <2 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <2 x i16>*
  %wide.load17 = load <2 x i16>, <2 x i16>* %tmp11, align 1
  %tmp12 = sext <2 x i16> %wide.load17 to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <2 x i16>
; %op1 = sext<2 x i32> %val1
; %val2 = load <2 x i16>
; %op2 = zext<2 x i32> %val2
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi16_sext_zext(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_2xi16_sext_zext:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movd {{.*#+}} xmm0 = mem[0],zero,zero,zero
; CHECK-NEXT:    pshuflw {{.*#+}} xmm0 = xmm0[0,0,2,1,4,5,6,7]
; CHECK-NEXT:    psrad $16, %xmm0
; CHECK-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,1,1,3]
; CHECK-NEXT:    movd {{.*#+}} xmm1 = mem[0],zero,zero,zero
; CHECK-NEXT:    pxor %xmm2, %xmm2
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1],xmm1[2],xmm2[2],xmm1[3],xmm2[3]
; CHECK-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,1,1,3]
; CHECK-NEXT:    movdqa %xmm1, %xmm2
; CHECK-NEXT:    psrlq $32, %xmm2
; CHECK-NEXT:    pmuludq %xmm0, %xmm2
; CHECK-NEXT:    movdqa %xmm0, %xmm3
; CHECK-NEXT:    psrlq $32, %xmm3
; CHECK-NEXT:    pmuludq %xmm1, %xmm3
; CHECK-NEXT:    paddq %xmm2, %xmm3
; CHECK-NEXT:    psllq $32, %xmm3
; CHECK-NEXT:    pmuludq %xmm0, %xmm1
; CHECK-NEXT:    paddq %xmm3, %xmm1
; CHECK-NEXT:    pshufd {{.*#+}} xmm0 = xmm1[0,2,2,3]
; CHECK-NEXT:    movq %xmm0, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i16>*
  %wide.load = load <2 x i16>, <2 x i16>* %tmp7, align 1
  %tmp8 = sext <2 x i16> %wide.load to <2 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <2 x i16>*
  %wide.load17 = load <2 x i16>, <2 x i16>* %tmp11, align 1
  %tmp12 = zext <2 x i16> %wide.load17 to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val1 = load <16 x i16>
; %op1 = sext<16 x i32> %val1
; %val2 = load <16 x i16>
; %op2 = sext<16 x i32> %val2
; %rst = mul <16 x i32> %op1, %op2
;
define void @mul_16xi16_sext(i8* nocapture readonly %a, i8* nocapture readonly %b, i64 %index) {
; CHECK-LABEL: mul_16xi16_sext:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movdqu (%rdi,%rdx), %xmm0
; CHECK-NEXT:    movdqu 16(%rdi,%rdx), %xmm1
; CHECK-NEXT:    movdqu (%rsi,%rdx), %xmm2
; CHECK-NEXT:    movdqu 16(%rsi,%rdx), %xmm3
; CHECK-NEXT:    movdqa %xmm2, %xmm4
; CHECK-NEXT:    pmulhw %xmm0, %xmm4
; CHECK-NEXT:    pmullw %xmm0, %xmm2
; CHECK-NEXT:    movdqa %xmm2, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm4[0],xmm0[1],xmm4[1],xmm0[2],xmm4[2],xmm0[3],xmm4[3]
; CHECK-NEXT:    punpckhwd {{.*#+}} xmm2 = xmm2[4],xmm4[4],xmm2[5],xmm4[5],xmm2[6],xmm4[6],xmm2[7],xmm4[7]
; CHECK-NEXT:    movdqa %xmm3, %xmm4
; CHECK-NEXT:    pmulhw %xmm1, %xmm4
; CHECK-NEXT:    pmullw %xmm1, %xmm3
; CHECK-NEXT:    movdqa %xmm3, %xmm1
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm1 = xmm1[0],xmm4[0],xmm1[1],xmm4[1],xmm1[2],xmm4[2],xmm1[3],xmm4[3]
; CHECK-NEXT:    punpckhwd {{.*#+}} xmm3 = xmm3[4],xmm4[4],xmm3[5],xmm4[5],xmm3[6],xmm4[6],xmm3[7],xmm4[7]
; CHECK-NEXT:    movdqu %xmm3, 48(%rax,%rdx,4)
; CHECK-NEXT:    movdqu %xmm1, 32(%rax,%rdx,4)
; CHECK-NEXT:    movdqu %xmm2, 16(%rax,%rdx,4)
; CHECK-NEXT:    movdqu %xmm0, (%rax,%rdx,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <16 x i16>*
  %wide.load = load <16 x i16>, <16 x i16>* %tmp7, align 1
  %tmp8 = sext <16 x i16> %wide.load to <16 x i32>
  %tmp10 = getelementptr inbounds i8, i8* %b, i64 %index
  %tmp11 = bitcast i8* %tmp10 to <16 x i16>*
  %wide.load17 = load <16 x i16>, <16 x i16>* %tmp11, align 1
  %tmp12 = sext <16 x i16> %wide.load17 to <16 x i32>
  %tmp13 = mul nuw nsw <16 x i32> %tmp12, %tmp8
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <16 x i32>*
  store <16 x i32> %tmp13, <16 x i32>* %tmp15, align 4
  ret void
}

; %val = load <2 x i8>
; %op1 = zext<2 x i32> %val
; %op2 = const <2 x i32> {c1, c2} // c1 and c2 are within (0 ~ 255)
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi8_varconst1(i8* nocapture readonly %a, i64 %index) {
; CHECK-LABEL: mul_2xi8_varconst1:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movzwl (%rdi,%rsi), %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    pxor %xmm1, %xmm1
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1],xmm0[2],xmm1[2],xmm0[3],xmm1[3],xmm0[4],xmm1[4],xmm0[5],xmm1[5],xmm0[6],xmm1[6],xmm0[7],xmm1[7]
; CHECK-NEXT:    pmullw {{.*}}(%rip), %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1],xmm0[2],xmm1[2],xmm0[3],xmm1[3]
; CHECK-NEXT:    movq %xmm0, (%rax,%rsi,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i8>*
  %wide.load = load <2 x i8>, <2 x i8>* %tmp7, align 1
  %tmp8 = zext <2 x i8> %wide.load to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp8, <i32 0, i32 255>
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val = load <2 x i8>
; %op1 = sext<2 x i32> %val
; %op2 = const <2 x i32> {c1, c2} // c1 and c2 are within (-128 ~ 127)
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi8_varconst2(i8* nocapture readonly %a, i64 %index) {
; CHECK-LABEL: mul_2xi8_varconst2:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movzwl (%rdi,%rsi), %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7]
; CHECK-NEXT:    psraw $8, %xmm0
; CHECK-NEXT:    pmullw {{.*}}(%rip), %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3]
; CHECK-NEXT:    psrad $16, %xmm0
; CHECK-NEXT:    movq %xmm0, (%rax,%rsi,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i8>*
  %wide.load = load <2 x i8>, <2 x i8>* %tmp7, align 1
  %tmp8 = sext <2 x i8> %wide.load to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp8, <i32 -128, i32 127>
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val = load <2 x i8>
; %op1 = zext<2 x i32> %val
; %op2 = const <2 x i32> {c1, c2} // c1 and c2 are within (0 ~ 256)
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi8_varconst3(i8* nocapture readonly %a, i64 %index) {
; CHECK-LABEL: mul_2xi8_varconst3:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movzwl (%rdi,%rsi), %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    pxor %xmm1, %xmm1
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1],xmm0[2],xmm1[2],xmm0[3],xmm1[3],xmm0[4],xmm1[4],xmm0[5],xmm1[5],xmm0[6],xmm1[6],xmm0[7],xmm1[7]
; CHECK-NEXT:    movdqa {{.*#+}} xmm1 = <0,256,u,u,u,u,u,u>
; CHECK-NEXT:    movdqa %xmm0, %xmm2
; CHECK-NEXT:    pmulhw %xmm1, %xmm2
; CHECK-NEXT:    pmullw %xmm1, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3]
; CHECK-NEXT:    movq %xmm0, (%rax,%rsi,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i8>*
  %wide.load = load <2 x i8>, <2 x i8>* %tmp7, align 1
  %tmp8 = zext <2 x i8> %wide.load to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp8, <i32 0, i32 256>
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val = load <2 x i8>
; %op1 = zext<2 x i32> %val
; %op2 = const <2 x i32> {c1, c2} // c1 and c2 are within (-1 ~ 255)
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi8_varconst4(i8* nocapture readonly %a, i64 %index) {
; CHECK-LABEL: mul_2xi8_varconst4:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movzwl (%rdi,%rsi), %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    pxor %xmm1, %xmm1
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1],xmm0[2],xmm1[2],xmm0[3],xmm1[3],xmm0[4],xmm1[4],xmm0[5],xmm1[5],xmm0[6],xmm1[6],xmm0[7],xmm1[7]
; CHECK-NEXT:    movdqa {{.*#+}} xmm1 = <65535,255,u,u,u,u,u,u>
; CHECK-NEXT:    movdqa %xmm0, %xmm2
; CHECK-NEXT:    pmulhw %xmm1, %xmm2
; CHECK-NEXT:    pmullw %xmm1, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3]
; CHECK-NEXT:    movq %xmm0, (%rax,%rsi,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i8>*
  %wide.load = load <2 x i8>, <2 x i8>* %tmp7, align 1
  %tmp8 = zext <2 x i8> %wide.load to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp8, <i32 -1, i32 255>
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val = load <2 x i8>
; %op1 = sext<2 x i32> %val
; %op2 = const <2 x i32> {c1, c2} // c1 and c2 are within (-129 ~ 127)
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi8_varconst5(i8* nocapture readonly %a, i64 %index) {
; CHECK-LABEL: mul_2xi8_varconst5:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movzwl (%rdi,%rsi), %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7]
; CHECK-NEXT:    psraw $8, %xmm0
; CHECK-NEXT:    movdqa {{.*#+}} xmm1 = <65407,127,u,u,u,u,u,u>
; CHECK-NEXT:    movdqa %xmm0, %xmm2
; CHECK-NEXT:    pmulhw %xmm1, %xmm2
; CHECK-NEXT:    pmullw %xmm1, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3]
; CHECK-NEXT:    movq %xmm0, (%rax,%rsi,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i8>*
  %wide.load = load <2 x i8>, <2 x i8>* %tmp7, align 1
  %tmp8 = sext <2 x i8> %wide.load to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp8, <i32 -129, i32 127>
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val = load <2 x i8>
; %op1 = sext<2 x i32> %val
; %op2 = const <2 x i32> {c1, c2} // c1 and c2 are within (-128 ~ 128)
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi8_varconst6(i8* nocapture readonly %a, i64 %index) {
; CHECK-LABEL: mul_2xi8_varconst6:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movzwl (%rdi,%rsi), %ecx
; CHECK-NEXT:    movd %ecx, %xmm0
; CHECK-NEXT:    punpcklbw {{.*#+}} xmm0 = xmm0[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7]
; CHECK-NEXT:    psraw $8, %xmm0
; CHECK-NEXT:    movdqa {{.*#+}} xmm1 = <65408,128,u,u,u,u,u,u>
; CHECK-NEXT:    movdqa %xmm0, %xmm2
; CHECK-NEXT:    pmulhw %xmm1, %xmm2
; CHECK-NEXT:    pmullw %xmm1, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3]
; CHECK-NEXT:    movq %xmm0, (%rax,%rsi,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i8>*
  %wide.load = load <2 x i8>, <2 x i8>* %tmp7, align 1
  %tmp8 = sext <2 x i8> %wide.load to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp8, <i32 -128, i32 128>
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val = load <2 x i16>
; %op1 = zext<2 x i32> %val
; %op2 = const <2 x i32> {c1, c2} // c1 and c2 are within (0 ~ 65535)
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi16_varconst1(i8* nocapture readonly %a, i64 %index) {
; CHECK-LABEL: mul_2xi16_varconst1:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movd {{.*#+}} xmm0 = mem[0],zero,zero,zero
; CHECK-NEXT:    movdqa {{.*#+}} xmm1 = <0,65535,u,u,u,u,u,u>
; CHECK-NEXT:    movdqa %xmm0, %xmm2
; CHECK-NEXT:    pmulhuw %xmm1, %xmm2
; CHECK-NEXT:    pmullw %xmm1, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3]
; CHECK-NEXT:    movq %xmm0, (%rax,%rsi,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i16>*
  %wide.load = load <2 x i16>, <2 x i16>* %tmp7, align 1
  %tmp8 = zext <2 x i16> %wide.load to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp8, <i32 0, i32 65535>
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val = load <2 x i16>
; %op1 = sext<2 x i32> %val
; %op2 = const <2 x i32> {c1, c2} // c1 and c2 are within (-32768 ~ 32767)
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi16_varconst2(i8* nocapture readonly %a, i64 %index) {
; CHECK-LABEL: mul_2xi16_varconst2:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movd {{.*#+}} xmm0 = mem[0],zero,zero,zero
; CHECK-NEXT:    movdqa {{.*#+}} xmm1 = <32768,32767,u,u,u,u,u,u>
; CHECK-NEXT:    movdqa %xmm0, %xmm2
; CHECK-NEXT:    pmulhw %xmm1, %xmm2
; CHECK-NEXT:    pmullw %xmm1, %xmm0
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm2[0],xmm0[1],xmm2[1],xmm0[2],xmm2[2],xmm0[3],xmm2[3]
; CHECK-NEXT:    movq %xmm0, (%rax,%rsi,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i16>*
  %wide.load = load <2 x i16>, <2 x i16>* %tmp7, align 1
  %tmp8 = sext <2 x i16> %wide.load to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp8, <i32 -32768, i32 32767>
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val = load <2 x i16>
; %op1 = zext<2 x i32> %val
; %op2 = const <2 x i32> {c1, c2} // c1 and c2 are within (0 ~ 65536)
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi16_varconst3(i8* nocapture readonly %a, i64 %index) {
; CHECK-LABEL: mul_2xi16_varconst3:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movd {{.*#+}} xmm0 = mem[0],zero,zero,zero
; CHECK-NEXT:    pxor %xmm1, %xmm1
; CHECK-NEXT:    punpcklwd {{.*#+}} xmm0 = xmm0[0],xmm1[0],xmm0[1],xmm1[1],xmm0[2],xmm1[2],xmm0[3],xmm1[3]
; CHECK-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,1,1,3]
; CHECK-NEXT:    movl $65536, %ecx # imm = 0x10000
; CHECK-NEXT:    movd %rcx, %xmm1
; CHECK-NEXT:    pslldq {{.*#+}} xmm1 = zero,zero,zero,zero,zero,zero,zero,zero,xmm1[0,1,2,3,4,5,6,7]
; CHECK-NEXT:    movdqa %xmm0, %xmm2
; CHECK-NEXT:    pmuludq %xmm1, %xmm2
; CHECK-NEXT:    psrlq $32, %xmm0
; CHECK-NEXT:    pmuludq %xmm1, %xmm0
; CHECK-NEXT:    psllq $32, %xmm0
; CHECK-NEXT:    paddq %xmm2, %xmm0
; CHECK-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; CHECK-NEXT:    movq %xmm0, (%rax,%rsi,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i16>*
  %wide.load = load <2 x i16>, <2 x i16>* %tmp7, align 1
  %tmp8 = zext <2 x i16> %wide.load to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp8, <i32 0, i32 65536>
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}

; %val = load <2 x i16>
; %op1 = sext<2 x i32> %val
; %op2 = const <2 x i32> {c1, c2} // c1 and c2 are within (0 ~ 32768)
; %rst = mul <2 x i32> %op1, %op2
;
define void @mul_2xi16_varconst4(i8* nocapture readonly %a, i64 %index) {
; CHECK-LABEL: mul_2xi16_varconst4:
; CHECK:       # BB#0: # %entry
; CHECK-NEXT:    movq {{.*}}(%rip), %rax
; CHECK-NEXT:    movd {{.*#+}} xmm0 = mem[0],zero,zero,zero
; CHECK-NEXT:    pshuflw {{.*#+}} xmm0 = xmm0[0,0,2,1,4,5,6,7]
; CHECK-NEXT:    psrad $16, %xmm0
; CHECK-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,1,1,3]
; CHECK-NEXT:    movl $32768, %ecx # imm = 0x8000
; CHECK-NEXT:    movd %rcx, %xmm1
; CHECK-NEXT:    pslldq {{.*#+}} xmm1 = zero,zero,zero,zero,zero,zero,zero,zero,xmm1[0,1,2,3,4,5,6,7]
; CHECK-NEXT:    movdqa %xmm0, %xmm2
; CHECK-NEXT:    pmuludq %xmm1, %xmm2
; CHECK-NEXT:    psrlq $32, %xmm0
; CHECK-NEXT:    pmuludq %xmm1, %xmm0
; CHECK-NEXT:    psllq $32, %xmm0
; CHECK-NEXT:    paddq %xmm2, %xmm0
; CHECK-NEXT:    pshufd {{.*#+}} xmm0 = xmm0[0,2,2,3]
; CHECK-NEXT:    movq %xmm0, (%rax,%rsi,4)
; CHECK-NEXT:    retq
entry:
  %pre = load i32*, i32** @c
  %tmp6 = getelementptr inbounds i8, i8* %a, i64 %index
  %tmp7 = bitcast i8* %tmp6 to <2 x i16>*
  %wide.load = load <2 x i16>, <2 x i16>* %tmp7, align 1
  %tmp8 = sext <2 x i16> %wide.load to <2 x i32>
  %tmp13 = mul nuw nsw <2 x i32> %tmp8, <i32 0, i32 32768>
  %tmp14 = getelementptr inbounds i32, i32* %pre, i64 %index
  %tmp15 = bitcast i32* %tmp14 to <2 x i32>*
  store <2 x i32> %tmp13, <2 x i32>* %tmp15, align 4
  ret void
}
