(*===-- llvm_hc.ml - LLVM OCaml Interface --------------------*- OCaml -*-===*
 *
 *                     The LLVM Compiler Infrastructure
 *
 * This file is distributed under the University of Illinois Open Source
 * License. See LICENSE.TXT for details.
 *
 *===----------------------------------------------------------------------===*)

external add_select_accelerator_code
  : [< Llvm.PassManager.any ] Llvm.PassManager.t -> unit
  = "llvm_add_select_accelerator_code"