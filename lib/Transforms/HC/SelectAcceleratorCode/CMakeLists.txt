add_llvm_library(LLVMSelectAcceleratorCode
  SelectAcceleratorCode.cpp

  ADDITIONAL_HEADER_DIRS
  ${LLVM_MAIN_INCLUDE_DIR}/llvm/Transforms
  ${LLVM_MAIN_INCLUDE_DIR}/llvm/Transforms/HC

  DEPENDS
  intrinsics_gen
  )