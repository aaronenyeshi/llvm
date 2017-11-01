/*===-- hc_ocaml.c - LLVM OCaml Glue ----------------------------*- C++ -*-===*\
|*                                                                            *|
|*                     The LLVM Compiler Infrastructure                       *|
|*                                                                            *|
|* This file is distributed under the University of Illinois Open Source      *|
|* License. See LICENSE.TXT for details.                                      *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* This file glues LLVM's OCaml interface to its C interface. These functions *|
|* are by and large transparent wrappers to the corresponding C functions.    *|
|*                                                                            *|
|* Note that these functions intentionally take liberties with the CAMLparamX *|
|* macros, since most of the parameters are not GC heap objects.              *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

#include "llvm-c/Transforms/HC.h"
#include "caml/mlvalues.h"
#include "caml/misc.h"

/* [<Llvm.PassManager.any] Llvm.PassManager.t -> unit */
CAMLprim value llvm_add_select_accelerator_code(LLVMPassManagerRef PM) {
  LLVMAddSelectAcceleratorCodePass(PM);
  return Val_unit;
}

