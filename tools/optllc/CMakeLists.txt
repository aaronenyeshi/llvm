set(LLVM_LINK_COMPONENTS
  ${LLVM_TARGETS_TO_BUILD}
  Analysis
  AsmPrinter
  BitWriter
  CodeGen
  Core
  Coroutines
  IPO
  IRReader
  InstCombine
  Instrumentation
  MC
  MIRParser
  ObjCARCOpts
  ScalarOpts
  SelectionDAG
  Support
  Target
  TransformUtils
  Vectorize
  Passes
  )

# Support plugins.
set(LLVM_NO_DEAD_STRIP 1)

add_llvm_tool(optllc
  AnalysisWrappers.cpp
  BreakpointPrinter.cpp
  GraphPrinters.cpp
  NewPMDriver.cpp
  PassPrinters.cpp
  PrintSCC.cpp
  optllc.cpp

  DEPENDS
  intrinsics_gen
  )
export_executable_symbols(optllc)

if(WITH_POLLY AND LINK_POLLY_INTO_TOOLS)
  target_link_libraries(opt Polly)
endif(WITH_POLLY AND LINK_POLLY_INTO_TOOLS)
