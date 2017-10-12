//===- optllc.cpp - The LLVM Modular Optimizer and Native Code Generator --===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Optimizations may be specified an arbitrary number of times on the command
// line, They are run in the order specified.
// This includes the llc code generator driver. It provides a convenient
// command-line interface for generating native assembly-language code
// or C code, given LLVM bitcode.
//
//===----------------------------------------------------------------------===//

#include "BreakpointPrinter.h"
#include "NewPMDriver.h"
#include "PassPrinters.h"
#include "llvm/ADT/Triple.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Analysis/CallGraph.h"
#include "llvm/Analysis/CallGraphSCCPass.h"
#include "llvm/Analysis/LoopPass.h"
#include "llvm/Analysis/RegionPass.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/Bitcode/BitcodeWriterPass.h"
#include "llvm/CodeGen/CommandFlags.h"
#include "llvm/CodeGen/LinkAllAsmWriterComponents.h"
#include "llvm/CodeGen/LinkAllCodegenComponents.h"
#include "llvm/CodeGen/MIRParser/MIRParser.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DebugInfo.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/DiagnosticPrinter.h"
#include "llvm/IR/IRPrintingPasses.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/LegacyPassNameParser.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/InitializePasses.h"
#include "llvm/LinkAllIR.h"
#include "llvm/LinkAllPasses.h"
#include "llvm/MC/SubtargetFeature.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Host.h"
#include "llvm/Support/ManagedStatic.h"
#include "llvm/Support/PluginLoader.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/Signals.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/SystemUtils.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/YAMLTraits.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetSubtargetInfo.h"
#include "llvm/Transforms/Coroutines.h"
#include "llvm/Transforms/IPO/AlwaysInliner.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include <algorithm>
#include <memory>
using namespace llvm;
using namespace opt_tool;

// The OptimizationList is automatically populated with registered Passes by the
// PassNameParser.
//
static cl::list<const PassInfo*, bool, PassNameParser>
PassList(cl::desc("Optimizations available:"));

// This flag specifies a textual description of the optimization pass pipeline
// to run over the module. This flag switches opt to use the new pass manager
// infrastructure, completely disabling all of the flags specific to the old
// pass management.
static cl::opt<std::string> PassPipeline(
    "passes",
    cl::desc("A textual description of the pass pipeline for optimizing"),
    cl::Hidden);

// Other command line options...
//
static cl::opt<std::string>
InputFilename(cl::Positional, cl::desc("<input bitcode file>"),
    cl::init("-"), cl::value_desc("filename"));

static cl::opt<std::string>
OutputFilename("o", cl::desc("Override output filename"),
               cl::value_desc("filename"));

static cl::opt<bool>
Force("f", cl::desc("Enable binary output on terminals"));

static cl::opt<bool>
PrintEachXForm("p", cl::desc("Print module after each transformation"));

static cl::opt<bool>
NoOutput("disable-output",
         cl::desc("Do not write result bitcode file"), cl::Hidden);

static cl::opt<bool>
OutputAssembly("S", cl::desc("Write output as LLVM assembly"));

static cl::opt<bool>
    OutputThinLTOBC("thinlto-bc",
                    cl::desc("Write output as ThinLTO-ready bitcode"));

static cl::opt<std::string> ThinLinkBitcodeFile(
    "thin-link-bitcode-file", cl::value_desc("filename"),
    cl::desc(
        "A file in which to write minimized bitcode for the thin link only"));

static cl::opt<bool>
NoVerify("disable-verify", cl::desc("Do not run the verifier"), cl::Hidden);

static cl::opt<bool>
VerifyEach("verify-each", cl::desc("Verify after each transform"));

static cl::opt<bool>
    DisableDITypeMap("disable-debug-info-type-map",
                     cl::desc("Don't use a uniquing type map for debug info"));

static cl::opt<bool>
StripDebug("strip-debug",
           cl::desc("Strip debugger symbol info from translation unit"));

static cl::opt<bool>
DisableInline("disable-inlining", cl::desc("Do not run the inliner pass"));

static cl::opt<bool>
DisableOptimizations("disable-opt",
                     cl::desc("Do not run any optimization passes"));

static cl::opt<bool>
StandardLinkOpts("std-link-opts",
                 cl::desc("Include the standard link time optimizations"));

static cl::opt<bool>
OptLevelO0("O0",
  cl::desc("Optimization level 0. Similar to clang -O0"));

static cl::opt<bool>
OptLevelO1("O1",
           cl::desc("Optimization level 1. Similar to clang -O1"));

static cl::opt<bool>
OptLevelO2("O2",
           cl::desc("Optimization level 2. Similar to clang -O2"));

static cl::opt<bool>
OptLevelOs("Os",
           cl::desc("Like -O2 with extra optimizations for size. Similar to clang -Os"));

static cl::opt<bool>
OptLevelOz("Oz",
           cl::desc("Like -Os but reduces code size further. Similar to clang -Oz"));

static cl::opt<bool>
OptLevelO3("O3",
           cl::desc("Optimization level 3. Similar to clang -O3"));

static cl::opt<unsigned>
CodeGenOptLevel("codegen-opt-level",
                cl::desc("Override optimization level for codegen hooks"));

static cl::opt<std::string>
TargetTriple("mtriple", cl::desc("Override target triple for module"));

static cl::opt<bool>
UnitAtATime("funit-at-a-time",
            cl::desc("Enable IPO. This corresponds to gcc's -funit-at-a-time"),
            cl::init(true));

static cl::opt<bool>
DisableLoopUnrolling("disable-loop-unrolling",
                     cl::desc("Disable loop unrolling in all relevant passes"),
                     cl::init(false));
static cl::opt<bool>
DisableLoopVectorization("disable-loop-vectorization",
                     cl::desc("Disable the loop vectorization pass"),
                     cl::init(false));

static cl::opt<bool>
DisableSLPVectorization("disable-slp-vectorization",
                        cl::desc("Disable the slp vectorization pass"),
                        cl::init(false));

static cl::opt<bool> EmitSummaryIndex("module-summary",
                                      cl::desc("Emit module summary index"),
                                      cl::init(false));

static cl::opt<bool> EmitModuleHash("module-hash", cl::desc("Emit module hash"),
                                    cl::init(false));

static cl::opt<bool>
DisableSimplifyLibCalls("disable-simplify-libcalls",
                        cl::desc("Disable simplify-libcalls"));

static cl::opt<bool>
Quiet("q", cl::desc("Obsolete option"), cl::Hidden);

static cl::alias
QuietA("quiet", cl::desc("Alias for -q"), cl::aliasopt(Quiet));

static cl::opt<bool>
AnalyzeOnly("analyze", cl::desc("Only perform analysis, no optimization"));

static cl::opt<bool>
PrintBreakpoints("print-breakpoints-for-testing",
                 cl::desc("Print select breakpoints location for testing"));

static cl::opt<std::string> ClDataLayout("data-layout",
                                         cl::desc("data layout string to use"),
                                         cl::value_desc("layout-string"),
                                         cl::init(""));

static cl::opt<bool> PreserveBitcodeUseListOrder(
    "preserve-bc-uselistorder",
    cl::desc("Preserve use-list order when writing LLVM bitcode."),
    cl::init(true), cl::Hidden);

static cl::opt<bool> PreserveAssemblyUseListOrder(
    "preserve-ll-uselistorder",
    cl::desc("Preserve use-list order when writing LLVM assembly."),
    cl::init(false), cl::Hidden);

static cl::opt<bool>
    RunTwice("run-twice",
             cl::desc("Run all passes twice, re-using the same pass manager."),
             cl::init(false), cl::Hidden);

static cl::opt<bool> DiscardValueNames(
    "discard-value-names",
    cl::desc("Discard names from Value (other than GlobalValue)."),
    cl::init(false), cl::Hidden);

static cl::opt<bool> Coroutines(
  "enable-coroutines",
  cl::desc("Enable coroutine passes."),
  cl::init(false), cl::Hidden);

static cl::opt<bool> PassRemarksWithHotness(
    "pass-remarks-with-hotness",
    cl::desc("With PGO, include profile count in optimization remarks"),
    cl::Hidden);

static cl::opt<unsigned> PassRemarksHotnessThreshold(
    "pass-remarks-hotness-threshold",
    cl::desc("Minimum profile count required for an optimization remark to be output"),
    cl::Hidden);

static cl::opt<std::string>
    RemarksFilename("pass-remarks-output",
                    cl::desc("YAML output filename for pass remarks"),
                    cl::value_desc("filename"));


// General options for llc.  Other pass-specific options are specified
// within the corresponding llc passes, and target-specific options
// and back-end code generation options are specified with the target machine.
//
static cl::opt<std::string>
InputLanguage("x", cl::desc("Input language ('ir' or 'mir')"));

static cl::opt<unsigned>
TimeCompilations("time-compilations", cl::Hidden, cl::init(1u),
                 cl::value_desc("N"),
                 cl::desc("Repeat compilation N times for timing"));

static cl::opt<bool>
NoIntegratedAssembler("no-integrated-as", cl::Hidden,
                      cl::desc("Disable integrated assembler"));

static cl::opt<bool>
    PreserveComments("preserve-as-comments", cl::Hidden,
                     cl::desc("Preserve Comments in outputted assembly"),
                     cl::init(true));

// Determine optimization level.
static cl::opt<char>
OptLevel("O",
         cl::desc("Optimization level. [-O0, -O1, -O2, or -O3] "
                  "(default = '-O2')"),
         cl::Prefix,
         cl::ZeroOrMore,
         cl::init(' '));

static cl::opt<std::string> SplitDwarfFile(
    "split-dwarf-file",
    cl::desc(
        "Specify the name of the .dwo file to encode in the DWARF output"));

static cl::opt<bool> ShowMCEncoding("show-mc-encoding", cl::Hidden,
                                    cl::desc("Show encoding in .s output"));

static cl::opt<bool> EnableDwarfDirectory(
    "enable-dwarf-directory", cl::Hidden,
    cl::desc("Use .file directives with an explicit directory."));

static cl::opt<bool> AsmVerbose("asm-verbose",
                                cl::desc("Add comments to directives."),
                                cl::init(true));

static cl::opt<bool>
    CompileTwice("compile-twice", cl::Hidden,
                 cl::desc("Run everything twice, re-using the same pass "
                          "manager and verify the result is the same."),
                 cl::init(false));

static cl::list<std::string> IncludeDirs("I", cl::desc("include search path"));


namespace {
static ManagedStatic<std::vector<std::string>> RunPassNames;

struct RunPassOption {
  void operator=(const std::string &Val) const {
    if (Val.empty())
      return;
    SmallVector<StringRef, 8> PassNames;
    StringRef(Val).split(PassNames, ',', -1, false);
    for (auto PassName : PassNames)
      RunPassNames->push_back(PassName);
  }
};
}

static RunPassOption RunPassOpt;

static cl::opt<RunPassOption, true, cl::parser<std::string>> RunPass(
    "run-pass",
    cl::desc("Run compiler only for specified passes (comma separated list)"),
    cl::value_desc("pass-name"), cl::ZeroOrMore, cl::location(RunPassOpt));

static int llc_main(int, char **, std::unique_ptr<Module>&, std::unique_ptr<tool_output_file> &, std::unique_ptr<tool_output_file> &);
static int compileModule(char **, LLVMContext &, std::unique_ptr<Module>&, std::unique_ptr<tool_output_file> &);

static std::unique_ptr<tool_output_file> GetOutputStream(const char *TargetName,
                                                       Triple::OSType OS,
                                                       const char *ProgName) {
  // If we don't yet have an output filename, make one.
  if (OutputFilename.empty()) {
    if (InputFilename == "-")
      OutputFilename = "-";
    else {
      // If InputFilename ends in .bc or .ll, remove it.
      StringRef IFN = InputFilename;
      if (IFN.endswith(".bc") || IFN.endswith(".ll"))
        OutputFilename = IFN.drop_back(3);
      else if (IFN.endswith(".mir"))
        OutputFilename = IFN.drop_back(4);
      else
        OutputFilename = IFN;

      switch (FileType) {
      case TargetMachine::CGFT_AssemblyFile:
        if (TargetName[0] == 'c') {
          if (TargetName[1] == 0)
            OutputFilename += ".cbe.c";
          else if (TargetName[1] == 'p' && TargetName[2] == 'p')
            OutputFilename += ".cpp";
          else
            OutputFilename += ".s";
        } else
          OutputFilename += ".s";
        break;
      case TargetMachine::CGFT_ObjectFile:
        if (OS == Triple::Win32)
          OutputFilename += ".obj";
        else
          OutputFilename += ".o";
        break;
      case TargetMachine::CGFT_Null:
        OutputFilename += ".null";
        break;
      }
    }
  }

  // Decide if we need "binary" output.
  bool Binary = false;
  switch (FileType) {
  case TargetMachine::CGFT_AssemblyFile:
    break;
  case TargetMachine::CGFT_ObjectFile:
  case TargetMachine::CGFT_Null:
    Binary = true;
    break;
  }

  // Open the file.
  std::error_code EC;
  sys::fs::OpenFlags OpenFlags = sys::fs::F_None;
  if (!Binary)
    OpenFlags |= sys::fs::F_Text;
  auto FDOut = llvm::make_unique<tool_output_file>(OutputFilename, EC, OpenFlags);
  if (EC) {
    errs() << EC.message() << '\n';
    return nullptr;
  }

  return FDOut;
}

struct LLCDiagnosticHandler : public DiagnosticHandler {
  bool *HasError;
  LLCDiagnosticHandler(bool *HasErrorPtr) : HasError(HasErrorPtr) {}
  bool handleDiagnostics(const DiagnosticInfo &DI) override {
    if (DI.getSeverity() == DS_Error)
      *HasError = true;

    if (auto *Remark = dyn_cast<DiagnosticInfoOptimizationBase>(&DI))
      if (!Remark->isEnabled())
        return true;

    DiagnosticPrinterRawOStream DP(errs());
    errs() << LLVMContext::getDiagnosticMessagePrefix(DI.getSeverity()) << ": ";
    DI.print(DP);
    errs() << "\n";
    return true;
  }
};

static void InlineAsmDiagHandler(const SMDiagnostic &SMD, void *Context,
                                 unsigned LocCookie) {
  bool *HasError = static_cast<bool *>(Context);
  if (SMD.getKind() == SourceMgr::DK_Error)
    *HasError = true;

  SMD.print(nullptr, errs());

  // For testing purposes, we print the LocCookie here.
  if (LocCookie)
    errs() << "note: !srcloc = " << LocCookie << "\n";
}

static inline void addPass(legacy::PassManagerBase &PM, Pass *P) {
  // Add the pass to the pass manager...
  PM.add(P);

  // If we are verifying all of the intermediate steps, add the verifier...
  if (VerifyEach)
    PM.add(createVerifierPass());
}

static bool addPass(PassManagerBase &PM, const char *argv0,
                    StringRef PassName, TargetPassConfig &TPC) {
  if (PassName == "none")
    return false;

  const PassRegistry *PR = PassRegistry::getPassRegistry();
  const PassInfo *PI = PR->getPassInfo(PassName);
  if (!PI) {
    errs() << argv0 << ": run-pass " << PassName << " is not registered.\n";
    return true;
  }

  Pass *P;
  if (PI->getNormalCtor())
    P = PI->getNormalCtor()();
  else {
    errs() << argv0 << ": cannot create pass: " << PI->getPassName() << "\n";
    return true;
  }
  std::string Banner = std::string("After ") + std::string(P->getPassName());
  PM.add(P);
  TPC.printAndVerify(Banner);

  return false;
}

/// This routine adds optimization passes based on selected optimization level,
/// OptLevel.
///
/// OptLevel - Optimization Level
static void AddOptimizationPasses(legacy::PassManagerBase &MPM,
                                  legacy::FunctionPassManager &FPM,
                                  TargetMachine *TM, unsigned OptLevel,
                                  unsigned SizeLevel) {
  if (!NoVerify || VerifyEach)
    FPM.add(createVerifierPass()); // Verify that input is correct

  PassManagerBuilder Builder;
  Builder.OptLevel = OptLevel;
  Builder.SizeLevel = SizeLevel;

  if (DisableInline) {
    // No inlining pass
  } else if (OptLevel > 1) {
    Builder.Inliner = createFunctionInliningPass(OptLevel, SizeLevel, false);
  } else {
    Builder.Inliner = createAlwaysInlinerLegacyPass();
  }
  Builder.DisableUnitAtATime = !UnitAtATime;
  Builder.DisableUnrollLoops = (DisableLoopUnrolling.getNumOccurrences() > 0) ?
                               DisableLoopUnrolling : OptLevel == 0;

  // This is final, unless there is a #pragma vectorize enable
  if (DisableLoopVectorization)
    Builder.LoopVectorize = false;
  // If option wasn't forced via cmd line (-vectorize-loops, -loop-vectorize)
  else if (!Builder.LoopVectorize)
    Builder.LoopVectorize = OptLevel > 1 && SizeLevel < 2;

  // When #pragma vectorize is on for SLP, do the same as above
  Builder.SLPVectorize =
      DisableSLPVectorization ? false : OptLevel > 1 && SizeLevel < 2;

  if (TM)
    TM->adjustPassManager(Builder);

  if (Coroutines)
    addCoroutinePassesToExtensionPoints(Builder);

  Builder.populateFunctionPassManager(FPM);
  Builder.populateModulePassManager(MPM);
}

static void AddStandardLinkPasses(legacy::PassManagerBase &PM) {
  PassManagerBuilder Builder;
  Builder.VerifyInput = true;
  if (DisableOptimizations)
    Builder.OptLevel = 0;

  if (!DisableInline)
    Builder.Inliner = createFunctionInliningPass();
  Builder.populateLTOPassManager(PM);
}

//===----------------------------------------------------------------------===//
// CodeGen-related helper functions.
//

static CodeGenOpt::Level GetCodeGenOptLevel() {
  if (CodeGenOptLevel.getNumOccurrences())
    return static_cast<CodeGenOpt::Level>(unsigned(CodeGenOptLevel));
  if (OptLevelO1)
    return CodeGenOpt::Less;
  if (OptLevelO2)
    return CodeGenOpt::Default;
  if (OptLevelO3)
    return CodeGenOpt::Aggressive;
  return CodeGenOpt::None;
}

// Returns the TargetMachine instance or zero if no triple is provided.
static TargetMachine* GetTargetMachine(Triple TheTriple, StringRef CPUStr,
                                       StringRef FeaturesStr,
                                       const TargetOptions &Options) {
  std::string Error;
  const Target *TheTarget = TargetRegistry::lookupTarget(MArch, TheTriple,
                                                         Error);
  // Some modules don't specify a triple, and this is okay.
  if (!TheTarget) {
    return nullptr;
  }

  return TheTarget->createTargetMachine(TheTriple.getTriple(), CPUStr,
                                        FeaturesStr, Options, getRelocModel(),
                                        getCodeModel(), GetCodeGenOptLevel());
}

#ifdef LINK_POLLY_INTO_TOOLS
namespace polly {
void initializePollyPasses(llvm::PassRegistry &Registry);
}
#endif

//===----------------------------------------------------------------------===//
// main for opt
//
int main(int argc, char **argv) {
  sys::PrintStackTraceOnErrorSignal(argv[0]);
  int argc_llc = 0;
  char **argv_llc;
  for (int i=0; i<argc; i++){
    if (strcmp(argv[i], "-llc-options") == 0){
      argc_llc = argc - i;
      argv_llc = &argv[i];
      argc = i;
      strcpy(argv[i], "llc");
    }
  }
  llvm::PrettyStackTraceProgram X(argc, argv);

  // Enable debug stream buffering.
  EnableDebugBuffering = true;

  llvm_shutdown_obj Y;  // Call llvm_shutdown() on exit.
  LLVMContext Context;
  //Triple TheTriple;

  InitializeAllTargets();
  InitializeAllTargetMCs();
  InitializeAllAsmPrinters();
  InitializeAllAsmParsers();

  // Initialize passes
  PassRegistry &Registry = *PassRegistry::getPassRegistry();
  initializeCore(Registry);
  initializeCoroutines(Registry);
  initializeScalarOpts(Registry);
  initializeObjCARCOpts(Registry);
  initializeVectorization(Registry);
  initializeIPO(Registry);
  initializeAnalysis(Registry);
  initializeTransformUtils(Registry);
  initializeInstCombine(Registry);
  initializeInstrumentation(Registry);
  initializeTarget(Registry);
  // For codegen passes, only passes that do IR to IR transformation are
  // supported.
  initializeScalarizeMaskedMemIntrinPass(Registry);
  initializeCodeGenPreparePass(Registry);
  initializeAtomicExpandPass(Registry);
  initializeRewriteSymbolsLegacyPassPass(Registry);
  initializeWinEHPreparePass(Registry);
  initializeDwarfEHPreparePass(Registry);
  initializeSafeStackLegacyPassPass(Registry);
  initializeSjLjEHPreparePass(Registry);
  initializePreISelIntrinsicLoweringLegacyPassPass(Registry);
  initializeGlobalMergePass(Registry);
  initializeInterleavedAccessPass(Registry);
  initializeCountingFunctionInserterPass(Registry);
  initializeUnreachableBlockElimLegacyPassPass(Registry);
  initializeExpandReductionsPass(Registry);

#ifdef LINK_POLLY_INTO_TOOLS
  polly::initializePollyPasses(Registry);
#endif

  cl::ParseCommandLineOptions(argc, argv,
    "llvm .bc -> .bc modular optimizer and analysis printer\n");

  if (AnalyzeOnly && NoOutput) {
    errs() << argv[0] << ": analyze mode conflicts with no-output mode.\n";
    return 1;
  }

  SMDiagnostic Err;

  Context.setDiscardValueNames(DiscardValueNames);
  if (!DisableDITypeMap)
    Context.enableDebugTypeODRUniquing();

  if (PassRemarksWithHotness)
    Context.setDiagnosticsHotnessRequested(true);

  if (PassRemarksHotnessThreshold)
    Context.setDiagnosticsHotnessThreshold(PassRemarksHotnessThreshold);

  std::unique_ptr<tool_output_file> OptRemarkFile;
  if (RemarksFilename != "") {
    std::error_code EC;
    OptRemarkFile =
        llvm::make_unique<tool_output_file>(RemarksFilename, EC, sys::fs::F_None);
    if (EC) {
      errs() << EC.message() << '\n';
      return 1;
    }
    Context.setDiagnosticsOutputFile(
        llvm::make_unique<yaml::Output>(OptRemarkFile->os()));
  }

  // Load the input module...
  std::unique_ptr<Module> M = parseIRFile(InputFilename, Err, Context);

  if (!M) {
    Err.print(argv[0], errs());
    return 1;
  }

  // Strip debug info before running the verifier.
  if (StripDebug)
    StripDebugInfo(*M);

  // Immediately run the verifier to catch any problems before starting up the
  // pass pipelines.  Otherwise we can crash on broken code during
  // doInitialization().
  if (!NoVerify && verifyModule(*M, &errs())) {
    errs() << argv[0] << ": " << InputFilename
           << ": error: input module is broken!\n";
    return 1;
  }

  // If we are supposed to override the target triple or data layout, do so now.
  if (!TargetTriple.empty()){
    M->setTargetTriple(Triple::normalize(TargetTriple));
    //TheTriple = Triple(M->getTargetTriple());
  }
  if (!ClDataLayout.empty())
    M->setDataLayout(ClDataLayout);
  //const Target *TheTarget = TargetRegistry::lookupTarget(MArch, TheTriple, Error);
  // Figure out what stream we are supposed to write to...
  std::unique_ptr<tool_output_file> Out;
  std::unique_ptr<tool_output_file> ThinLinkOut;
  if (NoOutput) {
    if (!OutputFilename.empty())
      errs() << "WARNING: The -o (output filename) option is ignored when\n"
                "the --disable-output option is used.\n";
  } else {
    // Default to standard output.
    if (OutputFilename.empty())
      OutputFilename = "-";

    std::error_code EC;
    Out.reset(new tool_output_file(OutputFilename, EC, sys::fs::F_None));
    //Out = GetOutputStream(TheTarget->getName(), TheTriple.getOS(), argv[0]);
    if (EC) {
      errs() << EC.message() << '\n';
      return 1;
    }

    if (!ThinLinkBitcodeFile.empty()) {
      ThinLinkOut.reset(
          new tool_output_file(ThinLinkBitcodeFile, EC, sys::fs::F_None));
      if (EC) {
        errs() << EC.message() << '\n';
        return 1;
      }
    }
  }

  Triple ModuleTriple(M->getTargetTriple());
  std::string CPUStr, FeaturesStr;
  TargetMachine *Machine = nullptr;
  const TargetOptions Options = InitTargetOptionsFromCodeGenFlags();

  if (ModuleTriple.getArch()) {
    CPUStr = getCPUStr();
    FeaturesStr = getFeaturesStr();
    Machine = GetTargetMachine(ModuleTriple, CPUStr, FeaturesStr, Options);
  }

  std::unique_ptr<TargetMachine> TM(Machine);

  // Override function attributes based on CPUStr, FeaturesStr, and command line
  // flags.
  setFunctionAttributes(CPUStr, FeaturesStr, *M);

  // If the output is set to be emitted to standard out, and standard out is a
  // console, print out a warning message and refuse to do it.  We don't
  // impress anyone by spewing tons of binary goo to a terminal.
  if (!Force && !NoOutput && !AnalyzeOnly && !OutputAssembly)
    if (CheckBitcodeOutputToConsole(Out->os(), !Quiet))
      NoOutput = true;

  if (PassPipeline.getNumOccurrences() > 0) {
    OutputKind OK = OK_NoOutput;
    if (!NoOutput)
      OK = OutputAssembly
               ? OK_OutputAssembly
               : (OutputThinLTOBC ? OK_OutputThinLTOBitcode : OK_OutputBitcode);

    VerifierKind VK = VK_VerifyInAndOut;
    if (NoVerify)
      VK = VK_NoVerifier;
    else if (VerifyEach)
      VK = VK_VerifyEachPass;

    // The user has asked to use the new pass manager and provided a pipeline
    // string. Hand off the rest of the functionality to the new code for that
    // layer.
    return runPassPipeline(argv[0], *M, TM.get(), Out.get(), ThinLinkOut.get(),
                           OptRemarkFile.get(), PassPipeline, OK, VK,
                           PreserveAssemblyUseListOrder,
                           PreserveBitcodeUseListOrder, EmitSummaryIndex,
                           EmitModuleHash)
               ? 0
               : 1;
  }

  // Create a PassManager to hold and optimize the collection of passes we are
  // about to build.
  //
  legacy::PassManager Passes;

  // Add an appropriate TargetLibraryInfo pass for the module's triple.
  TargetLibraryInfoImpl TLII(ModuleTriple);

  // The -disable-simplify-libcalls flag actually disables all builtin optzns.
  if (DisableSimplifyLibCalls)
    TLII.disableAllFunctions();
  Passes.add(new TargetLibraryInfoWrapperPass(TLII));

  // Add internal analysis passes from the target machine.
  Passes.add(createTargetTransformInfoWrapperPass(TM ? TM->getTargetIRAnalysis()
                                                     : TargetIRAnalysis()));

  std::unique_ptr<legacy::FunctionPassManager> FPasses;
  if (OptLevelO0 || OptLevelO1 || OptLevelO2 || OptLevelOs || OptLevelOz ||
      OptLevelO3) {
    FPasses.reset(new legacy::FunctionPassManager(M.get()));
    FPasses->add(createTargetTransformInfoWrapperPass(
        TM ? TM->getTargetIRAnalysis() : TargetIRAnalysis()));
  }

  if (PrintBreakpoints) {
    // Default to standard output.
    if (!Out) {
      if (OutputFilename.empty())
        OutputFilename = "-";

      std::error_code EC;
      Out = llvm::make_unique<tool_output_file>(OutputFilename, EC,
                                              sys::fs::F_None);
      if (EC) {
        errs() << EC.message() << '\n';
        return 1;
      }
    }
    Passes.add(createBreakpointPrinter(Out->os()));
    NoOutput = true;
  }

  if (TM) {
    // FIXME: We should dyn_cast this when supported.
    auto &LTM = static_cast<LLVMTargetMachine &>(*TM);
    Pass *TPC = LTM.createPassConfig(Passes);
    Passes.add(TPC);
  }

  // Create a new optimization pass for each one specified on the command line
  for (unsigned i = 0; i < PassList.size(); ++i) {
    if (StandardLinkOpts &&
        StandardLinkOpts.getPosition() < PassList.getPosition(i)) {
      AddStandardLinkPasses(Passes);
      StandardLinkOpts = false;
    }

    if (OptLevelO0 && OptLevelO0.getPosition() < PassList.getPosition(i)) {
      AddOptimizationPasses(Passes, *FPasses, TM.get(), 0, 0);
      OptLevelO0 = false;
    }

    if (OptLevelO1 && OptLevelO1.getPosition() < PassList.getPosition(i)) {
      AddOptimizationPasses(Passes, *FPasses, TM.get(), 1, 0);
      OptLevelO1 = false;
    }

    if (OptLevelO2 && OptLevelO2.getPosition() < PassList.getPosition(i)) {
      AddOptimizationPasses(Passes, *FPasses, TM.get(), 2, 0);
      OptLevelO2 = false;
    }

    if (OptLevelOs && OptLevelOs.getPosition() < PassList.getPosition(i)) {
      AddOptimizationPasses(Passes, *FPasses, TM.get(), 2, 1);
      OptLevelOs = false;
    }

    if (OptLevelOz && OptLevelOz.getPosition() < PassList.getPosition(i)) {
      AddOptimizationPasses(Passes, *FPasses, TM.get(), 2, 2);
      OptLevelOz = false;
    }

    if (OptLevelO3 && OptLevelO3.getPosition() < PassList.getPosition(i)) {
      AddOptimizationPasses(Passes, *FPasses, TM.get(), 3, 0);
      OptLevelO3 = false;
    }

    const PassInfo *PassInf = PassList[i];
    Pass *P = nullptr;
    if (PassInf->getNormalCtor())
      P = PassInf->getNormalCtor()();
    else
      errs() << argv[0] << ": cannot create pass: "
             << PassInf->getPassName() << "\n";
    if (P) {
      PassKind Kind = P->getPassKind();
      addPass(Passes, P);

      if (AnalyzeOnly) {
        switch (Kind) {
        case PT_BasicBlock:
          Passes.add(createBasicBlockPassPrinter(PassInf, Out->os(), Quiet));
          break;
        case PT_Region:
          Passes.add(createRegionPassPrinter(PassInf, Out->os(), Quiet));
          break;
        case PT_Loop:
          Passes.add(createLoopPassPrinter(PassInf, Out->os(), Quiet));
          break;
        case PT_Function:
          Passes.add(createFunctionPassPrinter(PassInf, Out->os(), Quiet));
          break;
        case PT_CallGraphSCC:
          Passes.add(createCallGraphPassPrinter(PassInf, Out->os(), Quiet));
          break;
        default:
          Passes.add(createModulePassPrinter(PassInf, Out->os(), Quiet));
          break;
        }
      }
    }

    if (PrintEachXForm)
      Passes.add(
          createPrintModulePass(errs(), "", PreserveAssemblyUseListOrder));
  }

  if (StandardLinkOpts) {
    AddStandardLinkPasses(Passes);
    StandardLinkOpts = false;
  }

  if (OptLevelO0)
    AddOptimizationPasses(Passes, *FPasses, TM.get(), 0, 0);

  if (OptLevelO1)
    AddOptimizationPasses(Passes, *FPasses, TM.get(), 1, 0);

  if (OptLevelO2)
    AddOptimizationPasses(Passes, *FPasses, TM.get(), 2, 0);

  if (OptLevelOs)
    AddOptimizationPasses(Passes, *FPasses, TM.get(), 2, 1);

  if (OptLevelOz)
    AddOptimizationPasses(Passes, *FPasses, TM.get(), 2, 2);

  if (OptLevelO3)
    AddOptimizationPasses(Passes, *FPasses, TM.get(), 3, 0);

  if (FPasses) {
    FPasses->doInitialization();
    for (Function &F : *M)
      FPasses->run(F);
    FPasses->doFinalization();
  }

  // Check that the module is well formed on completion of optimization
  if (!NoVerify && !VerifyEach)
    Passes.add(createVerifierPass());

  // Write bitcode or assembly to the output as the last step...
  if (!NoOutput && !AnalyzeOnly) {
    assert(Out);
    if (OutputAssembly) {
      if (EmitSummaryIndex)
        report_fatal_error("Text output is incompatible with -module-summary");
      if (EmitModuleHash)
        report_fatal_error("Text output is incompatible with -module-hash");
      Passes.add(createPrintModulePass(Out->os(), "", PreserveAssemblyUseListOrder));
    } else if (OutputThinLTOBC)
      Passes.add(createWriteThinLTOBitcodePass(
          Out->os(), ThinLinkOut ? &ThinLinkOut->os() : nullptr));
    else
      Passes.add(createBitcodeWriterPass(Out->os(), PreserveBitcodeUseListOrder,
                                         EmitSummaryIndex, EmitModuleHash));
  }

  // Before executing passes, print the final values of the LLVM options.
  cl::PrintOptionValues();

  // Now that we have all of the passes ready, run them.
  Passes.run(*M);

  llc_main(argc_llc, argv_llc, M, Out, OptRemarkFile);

  // Declare success.
  if (!NoOutput || PrintBreakpoints)
    Out->keep();

  if (OptRemarkFile)
    OptRemarkFile->keep();

  if (ThinLinkOut)
    ThinLinkOut->keep();

  return 0;
}

// main - Entry point for the llc compiler.
//
static int llc_main(int argc, char **argv, std::unique_ptr<Module> &M,
             std::unique_ptr<tool_output_file> &Out, std::unique_ptr<tool_output_file> &YamlFile) {
  sys::PrintStackTraceOnErrorSignal(argv[0]);
  PrettyStackTraceProgram X(argc, argv);

  // Enable debug stream buffering.
  EnableDebugBuffering = true;

  LLVMContext Context;
  llvm_shutdown_obj Y;  // Call llvm_shutdown() on exit.

  // Initialize targets first, so that --version shows registered targets.
  InitializeAllTargets();
  InitializeAllTargetMCs();
  InitializeAllAsmPrinters();
  InitializeAllAsmParsers();

  // Initialize codegen and IR passes used by llc so that the -print-after,
  // -print-before, and -stop-after options work.
  PassRegistry *Registry = PassRegistry::getPassRegistry();
  initializeCore(*Registry);
  initializeCodeGen(*Registry);
  initializeLoopStrengthReducePass(*Registry);
  initializeLowerIntrinsicsPass(*Registry);
  initializeCountingFunctionInserterPass(*Registry);
  initializeUnreachableBlockElimLegacyPassPass(*Registry);
  initializeConstantHoistingLegacyPassPass(*Registry);
  initializeScalarOpts(*Registry);
  initializeVectorization(*Registry);
  initializeScalarizeMaskedMemIntrinPass(*Registry);
  initializeExpandReductionsPass(*Registry);

  // Initialize debugging passes.
  initializeScavengerTestPass(*Registry);

  // Register the target printer for --version.
  cl::AddExtraVersionPrinter(TargetRegistry::printRegisteredTargetsForVersion);

  cl::ParseCommandLineOptions(argc, argv, "llvm system compiler\n");

  Context.setDiscardValueNames(DiscardValueNames);

  // Set a diagnostic handler that doesn't exit on the first error
  bool HasError = false;
  Context.setDiagnosticHandler(
      llvm::make_unique<LLCDiagnosticHandler>(&HasError));
  Context.setInlineAsmDiagnosticHandler(InlineAsmDiagHandler, &HasError);

  if (PassRemarksWithHotness)
    Context.setDiagnosticsHotnessRequested(true);

  if (PassRemarksHotnessThreshold)
    Context.setDiagnosticsHotnessThreshold(PassRemarksHotnessThreshold);

  /*std::unique_ptr<tool_output_file> YamlFile;
  if (RemarksFilename != "") {
    std::error_code EC;
    YamlFile =
        llvm::make_unique<tool_output_file>(RemarksFilename, EC, sys::fs::F_None);
    if (EC) {
      errs() << EC.message() << '\n';
      return 1;
    }
    Context.setDiagnosticsOutputFile(
        llvm::make_unique<yaml::Output>(YamlFile->os()));
  }*/

  if (InputLanguage != "" && InputLanguage != "ir" &&
      InputLanguage != "mir") {
    errs() << argv[0] << "Input language must be '', 'IR' or 'MIR'\n";
    return 1;
  }

  // Compile the module TimeCompilations times to give better compile time
  // metrics.
  for (unsigned I = TimeCompilations; I; --I)
    if (int RetVal = compileModule(argv, Context, M, Out))
      return RetVal;

  //if (YamlFile)
  //  YamlFile->keep();
  return 0;
}

static int compileModule(char **argv, LLVMContext &Context,
           std::unique_ptr<Module> &M, std::unique_ptr<tool_output_file> &Out) {
  // Load the module to be compiled...
  SMDiagnostic Err;
  //std::unique_ptr<Module> M;
  std::unique_ptr<MIRParser> MIR;
  Triple TheTriple;

  bool SkipModule = MCPU == "help" ||
                    (!MAttrs.empty() && MAttrs.front() == "help");

  // If user just wants to list available options, skip module loading
  if (!SkipModule) {
    if (InputLanguage == "mir" ||
        (InputLanguage == "" && StringRef(InputFilename).endswith(".mir"))) {
      MIR = createMIRParserFromFile(InputFilename, Err, Context);
      if (MIR)
        M = MIR->parseIRModule();
    } //else
      //M = parseIRFile(InputFilename, Err, Context);
    if (!M) {
      Err.print(argv[0], errs());
      return 1;
    }

    // Verify module immediately to catch problems before doInitialization() is
    // called on any passes.
    if (!NoVerify && verifyModule(*M, &errs())) {
      errs() << argv[0] << ": " << InputFilename
             << ": error: input module is broken!\n";
      return 1;
    }

    // If we are supposed to override the target triple, do so now.
    if (!TargetTriple.empty())
      M->setTargetTriple(Triple::normalize(TargetTriple));
    TheTriple = Triple(M->getTargetTriple());
  } else {
    TheTriple = Triple(Triple::normalize(TargetTriple));
  }

  if (TheTriple.getTriple().empty())
    TheTriple.setTriple(sys::getDefaultTargetTriple());

  // Get the target specific parser.
  std::string Error;
  const Target *TheTarget = TargetRegistry::lookupTarget(MArch, TheTriple,
                                                         Error);
  if (!TheTarget) {
    errs() << argv[0] << ": " << Error;
    return 1;
  }

  std::string CPUStr = getCPUStr(), FeaturesStr = getFeaturesStr();

  CodeGenOpt::Level OLvl = CodeGenOpt::Default;
  switch (OptLevel) {
  default:
    errs() << argv[0] << ": invalid optimization level.\n";
    return 1;
  case ' ': break;
  case '0': OLvl = CodeGenOpt::None; break;
  case '1': OLvl = CodeGenOpt::Less; break;
  case '2': OLvl = CodeGenOpt::Default; break;
  case '3': OLvl = CodeGenOpt::Aggressive; break;
  }

  TargetOptions Options = InitTargetOptionsFromCodeGenFlags();
  Options.DisableIntegratedAS = NoIntegratedAssembler;
  Options.MCOptions.ShowMCEncoding = ShowMCEncoding;
  Options.MCOptions.MCUseDwarfDirectory = EnableDwarfDirectory;
  Options.MCOptions.AsmVerbose = AsmVerbose;
  Options.MCOptions.PreserveAsmComments = PreserveComments;
  Options.MCOptions.IASSearchPaths = IncludeDirs;
  Options.MCOptions.SplitDwarfFile = SplitDwarfFile;

  std::unique_ptr<TargetMachine> Target(TheTarget->createTargetMachine(
      TheTriple.getTriple(), CPUStr, FeaturesStr, Options, getRelocModel(),
      getCodeModel(), OLvl));

  assert(Target && "Could not allocate target machine!");

  // If we don't have a module then just exit now. We do this down
  // here since the CPU/Feature help is underneath the target machine
  // creation.
  if (SkipModule)
    return 0;

  assert(M && "Should have exited if we didn't have a module!");
  if (FloatABIForCalls != FloatABI::Default)
    Options.FloatABIType = FloatABIForCalls;

  // Figure out where we are going to send the output.
  //std::unique_ptr<tool_output_file> Out =
  //    GetOutputStream(TheTarget->getName(), TheTriple.getOS(), argv[0]);
  if (!Out) return 1;

  // Build up all of the passes that we want to do to the module.
  legacy::PassManager PM;

  // Add an appropriate TargetLibraryInfo pass for the module's triple.
  TargetLibraryInfoImpl TLII(Triple(M->getTargetTriple()));

  // The -disable-simplify-libcalls flag actually disables all builtin optzns.
  if (DisableSimplifyLibCalls)
    TLII.disableAllFunctions();
  PM.add(new TargetLibraryInfoWrapperPass(TLII));

  // Add the target data from the target machine, if it exists, or the module.
  M->setDataLayout(Target->createDataLayout());

  // Override function attributes based on CPUStr, FeaturesStr, and command line
  // flags.
  setFunctionAttributes(CPUStr, FeaturesStr, *M);

  if (RelaxAll.getNumOccurrences() > 0 &&
      FileType != TargetMachine::CGFT_ObjectFile)
    errs() << argv[0]
             << ": warning: ignoring -mc-relax-all because filetype != obj";

  {
    raw_pwrite_stream *OS = &Out->os();

    SmallVector<char, 0> Buffer;
    std::unique_ptr<raw_svector_ostream> BOS;
    if (FileType != TargetMachine::CGFT_AssemblyFile &&
         !Out->os().supportsSeeking()) {
      BOS = make_unique<raw_svector_ostream>(Buffer);
      OS = BOS.get();
    }

    const char *argv0 = argv[0];
    LLVMTargetMachine &LLVMTM = static_cast<LLVMTargetMachine&>(*Target);
    MachineModuleInfo *MMI = new MachineModuleInfo(&LLVMTM);

    // Construct a custom pass pipeline that starts after instruction
    // selection.
    if (!RunPassNames->empty()) {
      if (!MIR) {
        errs() << argv0 << ": run-pass is for .mir file only.\n";
        return 1;
      }
      TargetPassConfig &TPC = *LLVMTM.createPassConfig(PM);
      if (TPC.hasLimitedCodeGenPipeline()) {
        errs() << argv0 << ": run-pass cannot be used with "
               << TPC.getLimitedCodeGenPipelineReason(" and ") << ".\n";
        return 1;
      }

      TPC.setDisableVerify(NoVerify);
      PM.add(&TPC);
      PM.add(MMI);
      TPC.printAndVerify("");
      for (const std::string &RunPassName : *RunPassNames) {
        if (addPass(PM, argv0, RunPassName, TPC))
          return 1;
      }
      TPC.setInitialized();
      PM.add(createPrintMIRPass(*OS));
      PM.add(createFreeMachineFunctionPass());
    } else if (Target->addPassesToEmitFile(PM, *OS, FileType, NoVerify, MMI)) {
      errs() << argv0 << ": target does not support generation of this"
             << " file type!\n";
      return 1;
    }

    if (MIR) {
      assert(MMI && "Forgot to create MMI?");
      if (MIR->parseMachineFunctions(*M, *MMI))
        return 1;
    }

    // Before executing passes, print the final values of the LLVM options.
    cl::PrintOptionValues();

    PM.run(*M);

    auto HasError =
        ((const LLCDiagnosticHandler *)(Context.getDiagHandlerPtr()))->HasError;
    if (*HasError)
      return 1;

  }

  // Declare success.
  //Out->keep();

  return 0;
}
