add_llvm_library(LLVMHC
  HC.cpp
  SelectAcceleratorCode.cpp

  ADDITIONAL_HEADER_DIRS
  ${LLVM_MAIN_INCLUDE_DIR}/llvm/Transforms

  DEPENDS
  intrinsics_gen
  )

add_subdirectory(DirectFuncCall)
add_subdirectory(WrapperGen)