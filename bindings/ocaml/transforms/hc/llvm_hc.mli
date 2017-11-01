(*===-- llvm_hc.mli - LLVM OCaml Interface -------------------*- OCaml -*-===*
 *
 *                     The LLVM Compiler Infrastructure
 *
 * This file is distributed under the University of Illinois Open Source
 * License. See LICENSE.TXT for details.
 *
 *===----------------------------------------------------------------------===*)

(** HC Transforms.

    This interface provides an OCaml API for LLVM hc transforms, the
    classes in the [LLVMHC] library. *)

(** See the [llvm::createSelectAcceleratorCodePass] function. *)
external add_select_accelerator_code
  : [< Llvm.PassManager.any ] Llvm.PassManager.t -> unit
  = "llvm_add_select_accelerator_code"