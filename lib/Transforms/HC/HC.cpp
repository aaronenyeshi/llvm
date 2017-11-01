//===-- HC.cpp ------------------------------------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements common infrastructure for libLLVMHC.a, which
// implements several passes.
//
//===----------------------------------------------------------------------===//

#include "llvm/Transforms/HC.h"
#include "llvm-c/Initialization.h"
#include "llvm-c/Transforms/HC.h"
#include "llvm/Analysis/Passes.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Verifier.h"
#include "llvm/InitializePasses.h"

using namespace llvm;

/// initializeHCPasses - Initialize all passes linked into the
/// HC library.
void llvm::initializeHC(PassRegistry &Registry) {
  initializeSelectAcceleratorCodePass(Registry);
}

void LLVMInitializeHC(LLVMPassRegistryRef R) {
  initializeHC(*unwrap(R));
}

void LLVMAddSelectAcceleratorCodePass(LLVMPassManagerRef PM) {
  unwrap(PM)->add(createSelectAcceleratorCodePass());
}
