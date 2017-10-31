//===----------------------- HC.h - HC Transformations -------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
///
/// \file
/// Provides passes to HC specific target
///
//===----------------------------------------------------------------------===//

#ifndef LLVM_TRANSFORMS_HC_H
#define LLVM_TRANSFORMS_HC_H

#include <functional>

namespace llvm {

class ModulePass;

/// Create a pass manager instance of a pass which selects only code which is
/// expected to be run by an accelerator
ModulePass *createSelectAcceleratorCodePass();

}

#endif // LLVM_TRANSFORMS_HC_H
