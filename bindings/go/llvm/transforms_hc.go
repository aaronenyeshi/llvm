//===- transforms_hc.go - Bindings for hc --------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines bindings for the hc component.
//
//===----------------------------------------------------------------------===//

package llvm

/*
#include "llvm-c/Transforms/HC.h"
*/
import "C"

func (pm PassManager) AddSelectAcceleratorCodePass()           { C.LLVMAddSelectAcceleratorCodePass(pm.C) }