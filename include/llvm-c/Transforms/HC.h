/*===------------------------------HC.h ------------------------- -*- C -*-===*\
|*===----------------- HC Transformation Library C Interface --------------===*|
|*                                                                            *|
|*                     The LLVM Compiler Infrastructure                       *|
|*                                                                            *|
|* This file is distributed under the University of Illinois Open Source      *|
|* License. See LICENSE.TXT for details.                                      *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* This header declares the C interface to libLLVMHC.a, which                 *|
|* implements various HC transformations of the LLVM IR.                      *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

#ifndef LLVM_C_TRANSFORMS_HC_H
#define LLVM_C_TRANSFORMS_HC_H

#include "llvm-c/Types.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @defgroup LLVMCTransformsHC HC transformations
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::createSelectAcceleratorCodePass function. */
void LLVMAddSelectAcceleratorCodePass(LLVMPassManagerRef PM);

/**
 * @}
 */

#ifdef __cplusplus
}
#endif /* defined(__cplusplus) */

#endif
