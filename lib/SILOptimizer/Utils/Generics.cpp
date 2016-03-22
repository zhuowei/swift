//===--- Generics.cpp ---- Utilities for transforming generics ------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "generic-specializer"

#include "swift/Strings.h"
#include "swift/SILOptimizer/Utils/Generics.h"
#include "swift/SILOptimizer/Utils/GenericCloner.h"
#include "swift/SIL/DebugUtils.h"

using namespace swift;

// =============================================================================
// ReabstractionInfo
// =============================================================================

// Initialize SpecializedType iff the specialization is allowed.
ReabstractionInfo::ReabstractionInfo(SILFunction *OrigF,
                                     ArrayRef<Substitution> ParamSubs) {
  if (!OrigF->shouldOptimize()) {
    DEBUG(llvm::dbgs() << "    Cannot specialize function " << OrigF->getName()
                       << " marked to be excluded from optimizations.\n");
    return;
  }

  TypeSubstitutionMap InterfaceSubs;
  if (OrigF->getLoweredFunctionType()->getGenericSignature())
    InterfaceSubs = OrigF->getLoweredFunctionType()->getGenericSignature()
      ->getSubstitutionMap(ParamSubs);

  // We do not support partial specialization.
  if (hasUnboundGenericTypes(InterfaceSubs)) {
    DEBUG(llvm::dbgs() <<
          "    Cannot specialize with unbound interface substitutions.\n");
    return;
  }
  if (hasDynamicSelfTypes(InterfaceSubs)) {
    DEBUG(llvm::dbgs() << "    Cannot specialize with dynamic self.\n");
    return;
  }
  SILModule &M = OrigF->getModule();
  Module *SM = M.getSwiftModule();

  SubstitutedType = SILType::substFuncType(M, SM, InterfaceSubs,
                                           OrigF->getLoweredFunctionType(),
                                           /*dropGenerics = */ true);

  NumResults = SubstitutedType->getNumIndirectResults();
  Conversions.resize(NumResults + SubstitutedType->getParameters().size());
  if (SubstitutedType->getNumDirectResults() == 0) {
    // The original function has no direct result yet. Try to convert the first
    // indirect result to a direct result.
    // TODO: We could also convert multiple indirect results by returning a
    // tuple type and created tuple_extract instructions at the call site.
    unsigned IdxForResult = 0;
    for (SILResultInfo RI : SubstitutedType->getIndirectResults()) {
      assert(RI.isIndirect());
      if (RI.getSILType().isLoadable(M) && !RI.getType()->isVoid()) {
        Conversions.set(IdxForResult);
        break;
      }
      ++IdxForResult;
    }
  }
  // Try to convert indirect incoming parameters to direct parameters.
  unsigned IdxForParam = NumResults;
  for (SILParameterInfo PI : SubstitutedType->getParameters()) {
    if (PI.getSILType().isLoadable(M) &&
        PI.getConvention() == ParameterConvention::Indirect_In) {
      Conversions.set(IdxForParam);
    }
    ++IdxForParam;
  }
  SpecializedType = createSpecializedType(SubstitutedType, M);
}

// Convert the substituted function type into a specialized function type based
// on the ReabstractionInfo.
CanSILFunctionType ReabstractionInfo::
createSpecializedType(CanSILFunctionType SubstFTy, SILModule &M) const {
  llvm::SmallVector<SILResultInfo, 8> SpecializedResults;
  llvm::SmallVector<SILParameterInfo, 8> SpecializedParams;

  unsigned ResultIdx = 0;
  for (SILResultInfo RI : SubstFTy->getAllResults()) {
    if (RI.isDirect()) {
      SpecializedResults.push_back(RI);
    } else {
      if (isResultConverted(ResultIdx++)) {
        // Convert the indirect result to a direct result.
        SILType SILResTy = SILType::getPrimitiveObjectType(RI.getType());
        // Indirect results are passed as owned, so we also need to pass the
        // direct result as owned (except it's a trivial type).
        auto C = (SILResTy.isTrivial(M) ? ResultConvention::Unowned :
                  ResultConvention::Owned);
        SpecializedResults.push_back(SILResultInfo(RI.getType(), C));
      } else {
        // No conversion: re-use the original result info.
        SpecializedResults.push_back(RI);
      }
    }
  }
  unsigned ParamIdx = 0;
  for (SILParameterInfo PI : SubstFTy->getParameters()) {
    if (isParamConverted(ParamIdx++)) {
      // Convert the indirect parameter to a direct parameter.
      SILType SILParamTy = SILType::getPrimitiveObjectType(PI.getType());
      // Indirect parameters are passed as owned, so we also need to pass the
      // direct parameter as owned (except it's a trivial type).
      auto C = (SILParamTy.isTrivial(M) ? ParameterConvention::Direct_Unowned :
                ParameterConvention::Direct_Owned);
      SpecializedParams.push_back(SILParameterInfo(PI.getType(), C));
    } else {
      // No conversion: re-use the original parameter info.
      SpecializedParams.push_back(PI);
    }
  }
  return
    SILFunctionType::get(SubstFTy->getGenericSignature(),
                         SubstFTy->getExtInfo(),
                         SubstFTy->getCalleeConvention(), SpecializedParams,
                         SpecializedResults, SubstFTy->getOptionalErrorResult(),
                         M.getASTContext());
}

// =============================================================================
// GenericFuncSpecializer
// =============================================================================

GenericFuncSpecializer::GenericFuncSpecializer(SILFunction *GenericFunc,
                                               ArrayRef<Substitution> ParamSubs,
                                               const ReabstractionInfo &ReInfo)
    : M(GenericFunc->getModule()),
      GenericFunc(GenericFunc),
      ParamSubs(ParamSubs),
      ReInfo(ReInfo) {

  assert(GenericFunc->isDefinition() && "Expected definition to specialize!");

  if (GenericFunc->getContextGenericParams())
    ContextSubs = GenericFunc->getContextGenericParams()
      ->getSubstitutionMap(ParamSubs);

  Mangle::Mangler Mangler;
  GenericSpecializationMangler GenericMangler(Mangler, GenericFunc,
                                                ParamSubs);
  GenericMangler.mangle();
  ClonedName = Mangler.finalize();

  DEBUG(llvm::dbgs() << "    Specialized function " << ClonedName << '\n');
}

// Return an existing specialization if one exists.
SILFunction *GenericFuncSpecializer::lookupSpecialization() {
  if (SILFunction *SpecializedF = M.lookUpFunction(ClonedName)) {
    assert(ReInfo.getSpecializedType()
           == SpecializedF->getLoweredFunctionType() &&
           "Previously specialized function does not match expected type.");
    return SpecializedF;
  }
  return nullptr;
}

// Forward decl for prespecialization support.
static bool linkSpecialization(SILModule &M, SILFunction *F);

// Create a new specialized function if possible, and cache it.
SILFunction *GenericFuncSpecializer::tryCreateSpecialization() {
  // Do not create any new specializations at Onone.
  if (M.getOptions().Optimization <= SILOptions::SILOptMode::None)
    return nullptr;

  DEBUG(
    if (M.getOptions().Optimization <= SILOptions::SILOptMode::Debug) {
      llvm::dbgs() << "Creating a specialization: " << ClonedName << "\n"; });

  // Create a new function.
  SILFunction * SpecializedF =
    GenericCloner::cloneFunction(GenericFunc, ReInfo, ContextSubs, ParamSubs,
                                 ClonedName);

  // Check if this specialization should be linked for prespecialization.
  linkSpecialization(M, SpecializedF);
  return SpecializedF;
}

// =============================================================================
// Apply substitution
// =============================================================================

/// Fix the case where a void function returns the result of an apply, which is
/// also a call of a void-returning function.
/// We always want a void function returning a tuple _instruction_.
static void fixUsedVoidType(SILValue VoidVal, SILLocation Loc,
                            SILBuilder &Builder) {
  assert(VoidVal->getType().isVoid());
  if (VoidVal->use_empty())
    return;
  auto *NewVoidVal = Builder.createTuple(Loc, VoidVal->getType(), { });
  VoidVal->replaceAllUsesWith(NewVoidVal);
}

// Create a new apply based on an old one, but with a different
// function being applied.
static ApplySite replaceWithSpecializedCallee(ApplySite AI,
                                              SILValue Callee,
                                              SILBuilder &Builder,
                                              const ReabstractionInfo &ReInfo) {
  SILLocation Loc = AI.getLoc();
  SmallVector<SILValue, 4> Arguments;
  SILValue StoreResultTo;
  unsigned Idx = ReInfo.getIndexOfFirstArg(AI);
  for (auto &Op : AI.getArgumentOperands()) {
    if (ReInfo.isArgConverted(Idx)) {
      if (ReInfo.isResultIndex(Idx)) {
        // The result is converted from indirect to direct. We need to insert
        // a store later.
        assert(!StoreResultTo);
        StoreResultTo = Op.get();
      } else {
        // An argument is converted from indirect to direct. Instead of the
        // address we pass the loaded value.
        SILValue Val = Builder.createLoad(Loc, Op.get());
        Arguments.push_back(Val);
      }
    } else {
      Arguments.push_back(Op.get());
    }
    ++Idx;
  }

  if (auto *TAI = dyn_cast<TryApplyInst>(AI)) {
    SILBasicBlock *ResultBB = TAI->getNormalBB();
    assert(ResultBB->getSinglePredecessor() == TAI->getParent());
    auto *NewTAI =
      Builder.createTryApply(Loc, Callee, Callee->getType(), {},
                             Arguments, ResultBB, TAI->getErrorBB());
    if (StoreResultTo) {
      // The original normal result of the try_apply is an empty tuple.
      assert(ResultBB->getNumBBArg() == 1);
      Builder.setInsertionPoint(ResultBB->begin());
      fixUsedVoidType(ResultBB->getBBArg(0), Loc, Builder);


      SILArgument *Arg =
        ResultBB->replaceBBArg(0, StoreResultTo->getType().getObjectType());
      // Store the direct result to the original result address.
      Builder.createStore(Loc, Arg, StoreResultTo);
    }
    return NewTAI;
  }
  if (auto *A = dyn_cast<ApplyInst>(AI)) {
    auto *NewAI = Builder.createApply(Loc, Callee, Arguments, A->isNonThrowing());
    if (StoreResultTo) {
      // Store the direct result to the original result address.
      fixUsedVoidType(A, Loc, Builder);
      Builder.createStore(Loc, NewAI, StoreResultTo);
    }
    A->replaceAllUsesWith(NewAI);
    return NewAI;
  }
  if (auto *PAI = dyn_cast<PartialApplyInst>(AI)) {
    CanSILFunctionType NewPAType =
      ReInfo.createSpecializedType(PAI->getFunctionType(), Builder.getModule());
    SILType PTy = SILType::getPrimitiveObjectType(ReInfo.getSpecializedType());
    auto *NewPAI =
      Builder.createPartialApply(Loc, Callee, PTy, {}, Arguments,
                                 SILType::getPrimitiveObjectType(NewPAType));
    PAI->replaceAllUsesWith(NewPAI);
    return NewPAI;
  }
  llvm_unreachable("unhandled kind of apply");
}

// Create a new apply based on an old one, but with a different
// function being applied.
ApplySite swift::
replaceWithSpecializedFunction(ApplySite AI, SILFunction *NewF,
                               const ReabstractionInfo &ReInfo) {
  SILBuilderWithScope Builder(AI.getInstruction());
  FunctionRefInst *FRI = Builder.createFunctionRef(AI.getLoc(), NewF);
  return replaceWithSpecializedCallee(AI, FRI, Builder, ReInfo);
}

/// Create a re-abstraction thunk for a partial_apply.
/// This is needed in case we converted some parameters/results of the
/// specialized function from indirect to direct but the result function of the
/// partial_apply still needs them as indirect.
/// We create a thunk which converts the direct parameters/results back to
/// indirect ones.
static SILFunction *createReabstractionThunk(const ReabstractionInfo &ReInfo,
                                     PartialApplyInst *OrigPAI,
                                     SILFunction *SpecializedFunc) {
  SILFunction *OrigF = OrigPAI->getCalleeFunction();
  SILModule &M = OrigF->getModule();

  std::string ThunkName;
  {
    Mangle::Mangler M;
    GenericSpecializationMangler Mangler(M, OrigF, OrigPAI->getSubstitutions(),
                              GenericSpecializationMangler::NotReabstracted);
    Mangler.mangle();
    ThunkName = M.finalize();
  }

  auto Loc = RegularLocation::getAutoGeneratedLocation();
  SILFunction *Thunk =
    M.getOrCreateSharedFunction(Loc, ThunkName, ReInfo.getSubstitutedType(),
                              IsBare, IsTransparent, OrigF->isFragile(),
                              IsThunk);

  // Re-use an existing thunk.
  if (!Thunk->empty())
    return Thunk;

  SILBasicBlock *EntryBB = new (M) SILBasicBlock(Thunk);
  SILBuilder Builder(EntryBB);
  SILBasicBlock *SpecEntryBB = &*SpecializedFunc->begin();
  CanSILFunctionType SpecType = SpecializedFunc->getLoweredFunctionType();
  SILArgument *ReturnValueAddr = nullptr;

  // Convert indirect to direct parameters/results.
  SmallVector<SILValue, 4> Arguments;
  auto SpecArgIter = SpecEntryBB->bbarg_begin();
  for (unsigned Idx = 0; Idx < ReInfo.getNumArguments(); Idx++) {
    if (ReInfo.isArgConverted(Idx)) {
      if (ReInfo.isResultIndex(Idx)) {
        // Store the result later.
        SILType Ty = SpecType->getSILResult().getAddressType();
        ReturnValueAddr = new (M) SILArgument(EntryBB, Ty);
      } else {
        // Instead of passing the address, pass the loaded value.
        SILArgument *SpecArg = *SpecArgIter++;
        SILType Ty = SpecArg->getType().getAddressType();
        SILArgument *NewArg = new (M) SILArgument(EntryBB, Ty,
                                                  SpecArg->getDecl());
        auto *ArgVal = Builder.createLoad(Loc, NewArg);
        Arguments.push_back(ArgVal);
      }
    } else {
      // No change to the argument.
      SILArgument *SpecArg = *SpecArgIter++;
      SILArgument *NewArg = new (M) SILArgument(EntryBB, SpecArg->getType(),
                                                SpecArg->getDecl());
      Arguments.push_back(NewArg);
    }
  }

  auto *FRI = Builder.createFunctionRef(Loc, SpecializedFunc);
  SILValue ReturnValue;
  if (SpecType->hasErrorResult()) {
    // Create the logic for calling a throwing function.
    SILBasicBlock *NormalBB = new (M) SILBasicBlock(Thunk);
    SILBasicBlock *ErrorBB = new (M) SILBasicBlock(Thunk);
    Builder.createTryApply(Loc, FRI, SpecializedFunc->getLoweredType(),
                           {}, Arguments, NormalBB, ErrorBB);
    auto *ErrorVal = new (M) SILArgument(ErrorBB,
                                         SpecType->getErrorResult().getSILType());
    Builder.setInsertionPoint(ErrorBB);
    Builder.createThrow(Loc, ErrorVal);
    ReturnValue = new (M) SILArgument(NormalBB, SpecType->getSILResult());
    Builder.setInsertionPoint(NormalBB);
  } else {
    ReturnValue = Builder.createApply(Loc, FRI, SpecializedFunc->getLoweredType(),
                                SpecType->getSILResult(), {}, Arguments, false);
  }
  if (ReturnValueAddr) {
    // Need to store the direct results to the original indirect address.
    Builder.createStore(Loc, ReturnValue, ReturnValueAddr);
    SILType VoidTy = OrigPAI->getSubstCalleeType()->getSILResult();
    assert(VoidTy.isVoid());
    ReturnValue = Builder.createTuple(Loc, VoidTy, { });
  }
  Builder.createReturn(Loc, ReturnValue);

  return Thunk;
}

void swift::trySpecializeApplyOfGeneric(ApplySite Apply,
                        llvm::SmallVectorImpl<SILInstruction *> &DeadApplies,
                        llvm::SmallVectorImpl<SILFunction *> &NewFunctions) {
  assert(Apply.hasSubstitutions() && "Expected an apply with substitutions!");

  auto *F = cast<FunctionRefInst>(Apply.getCallee())->getReferencedFunction();

  DEBUG(llvm::dbgs() << "  ApplyInst: " << *Apply.getInstruction());

  ReabstractionInfo ReInfo(F, Apply.getSubstitutions());
  if (!ReInfo.getSpecializedType())
    return;

  SILModule &M = Apply.getInstruction()->getModule();

  bool needAdaptUsers = false;
  bool replacePartialApplyWithoutReabstraction = false;
  auto *PAI = dyn_cast<PartialApplyInst>(Apply);
  if (PAI && ReInfo.hasConversions()) {
    // If we have a partial_apply and we converted some results/parameters from
    // indirect to direct there are 3 cases:
    // 1) All uses of the partial_apply are apply sites again. In this case
    //    we can just adapt all the apply sites which use the partial_apply.
    // 2) The result of the partial_apply is re-abstracted anyway (and the
    //    re-abstracted function type matches with our specialized type). In
    //    this case we can just skip the existing re-abstraction.
    // 3) For all other cases we need to create a new re-abstraction thunk.
    needAdaptUsers = true;
    for (Operand *Use : PAI->getUses()) {
      SILInstruction *User = Use->getUser();
      if (isa<RefCountingInst>(User))
        continue;
      if (isDebugInst(User))
        continue;

      auto FAS = FullApplySite::isa(User);
      if (FAS && FAS.getCallee() == Apply.getInstruction())
        continue;

      auto *PAIUser = dyn_cast<PartialApplyInst>(User);
      if (PAIUser && isPartialApplyOfReabstractionThunk(PAIUser)) {
        CanSILFunctionType NewPAType =
          ReInfo.createSpecializedType(PAI->getFunctionType(), M);
        if (PAIUser->getFunctionType() == NewPAType)
          continue;
      }
      replacePartialApplyWithoutReabstraction = true;
      break;
    }
  }

  GenericFuncSpecializer FuncSpecializer(F, Apply.getSubstitutions(), ReInfo);
  SILFunction *SpecializedF = FuncSpecializer.lookupSpecialization();
  if (SpecializedF) {
    assert(ReInfo.getSpecializedType()
           == SpecializedF->getLoweredFunctionType() &&
           "Previously specialized function does not match expected type.");
  } else {
    SpecializedF = FuncSpecializer.tryCreateSpecialization();
    if (!SpecializedF)
      return;

    NewFunctions.push_back(SpecializedF);
  }

  DeadApplies.push_back(Apply.getInstruction());

  if (replacePartialApplyWithoutReabstraction) {
    // There are some unknown users of the partial_apply. Therefore we need a
    // thunk which converts from the re-abstracted function back to the
    // original function with indirect parameters/results.
    auto *PAI = cast<PartialApplyInst>(Apply.getInstruction());
    SILBuilderWithScope Builder(PAI);
    SILFunction *Thunk = createReabstractionThunk(ReInfo, PAI, SpecializedF);
    NewFunctions.push_back(Thunk);
    auto *FRI = Builder.createFunctionRef(PAI->getLoc(), Thunk);
    SmallVector<SILValue, 4> Arguments;
    for (auto &Op : PAI->getArgumentOperands()) {
      Arguments.push_back(Op.get());
    }
    auto *NewPAI = Builder.createPartialApply(PAI->getLoc(), FRI,
                                      PAI->getSubstCalleeSILType(),
                                      {},
                                      Arguments,
                                      PAI->getType());
    PAI->replaceAllUsesWith(NewPAI);
    return;
  }
  // Make the required changes to the call site.
  ApplySite newApply = replaceWithSpecializedFunction(Apply, SpecializedF,
                                                      ReInfo);
  if (needAdaptUsers) {
    // Adapt all known users of the partial_apply. This is needed in case we
    // converted some indirect parameters/results to direct ones.
    auto *NewPAI = cast<PartialApplyInst>(newApply);
    ReInfo.prunePartialApplyArgs(NewPAI->getNumArguments());
    for (Operand *Use : NewPAI->getUses()) {
      SILInstruction *User = Use->getUser();
      if (auto FAS = FullApplySite::isa(User)) {
        SILBuilder Builder(User);
        replaceWithSpecializedCallee(FAS, NewPAI, Builder, ReInfo);
        DeadApplies.push_back(User);
        continue;
      }
      if (auto *PAI = dyn_cast<PartialApplyInst>(User)) {
        // This is a partial_apply of a re-abstraction thunk. Just skip this.
        assert(PAI->getType() == NewPAI->getType());
        PAI->replaceAllUsesWith(NewPAI);
        DeadApplies.push_back(PAI);
      }
    }
  }
}

// =============================================================================
// Prespecialized symbol lookup.
//
// This uses the SIL linker to checks for the does not load the body of the pres
// =============================================================================

/// Link a specialization for generating prespecialized code.
/// 
/// For now, it is performed only for specializations in the
/// standard library. But in the future, one could think of
/// maintaining a cache of optimized specializations.
///
/// Mark specializations as public, so that they can be used by user
/// applications. These specializations are generated during -O compilation of
/// the library, but only used only by client code compiled at -Onone. They
/// should be never inlined.
static bool linkSpecialization(SILModule &M, SILFunction *F) {
  // Do not remove functions from the white-list. Keep them around.
  // Change their linkage to public, so that other applications can refer to it.

  if (M.getOptions().Optimization >= SILOptions::SILOptMode::Optimize &&
      F->getLinkage() != SILLinkage::Public &&
      F->getModule().getSwiftModule()->getName().str() == SWIFT_ONONE_SUPPORT) {
    if (F->getLinkage() != SILLinkage::Public &&
        isWhitelistedSpecialization(F->getName())) {

      DEBUG(
        auto DemangledNameString =
          swift::Demangle::demangleSymbolAsString(F->getName());
        StringRef DemangledName = DemangledNameString;
        llvm::dbgs() << "Keep specialization: " << DemangledName << " : "
                     << F->getName() << "\n");
      // Make it public, so that others can refer to it.
      //
      // NOTE: This function may refer to non-public symbols, which may lead to
      // problems, if you ever try to inline this function. Therefore, these
      // specializations should only be used to refer to them, but should never
      // be inlined!  The general rule could be: Never inline specializations
      // from stdlib!
      //
      // NOTE: Making these specializations public at this point breaks
      // some optimizations. Therefore, just mark the function.
      // DeadFunctionElimination pass will check if the function is marked
      // and preserve it if required.
      F->setKeepAsPublic(true);
      return true;
    }
  }
  return false;
}

/// Check of a given name could be a name of a white-listed
/// specialization.
bool swift::isWhitelistedSpecialization(StringRef SpecName) {
  // The whitelist of classes and functions from the stdlib,
  // whose specializations we want to preserve.
  ArrayRef<StringRef> Whitelist = {
      "Array",
      "_ArrayBuffer",
      "_ContiguousArrayBuffer",
      "Range",
      "RangeIterator",
      "_allocateUninitializedArray",
      "UTF8",
      "UTF16",
      "String",
      "_StringBuffer",
      "_toStringReadOnlyPrintable",
  };

  // TODO: Once there is an efficient API to check if
  // a given symbol is a specialization of a specific type,
  // use it instead. Doing demangling just for this check
  // is just wasteful.
  auto DemangledNameString =
     swift::Demangle::demangleSymbolAsString(SpecName);

  StringRef DemangledName = DemangledNameString;

  auto pos = DemangledName.find("generic ", 0);
  if (pos == StringRef::npos)
    return false;

  // Create "of Swift"
  llvm::SmallString<64> OfString;
  llvm::raw_svector_ostream buffer(OfString);
  buffer << "of ";
  buffer << STDLIB_NAME <<'.';

  StringRef OfStr = buffer.str();

  pos = DemangledName.find(OfStr, pos);

  if (pos == StringRef::npos)
    return false;

  pos += OfStr.size();

  for(auto Name: Whitelist) {
    auto pos1 = DemangledName.find(Name, pos);
    if (pos1 == pos && !isalpha(DemangledName[pos1+Name.size()])) {
      return true;
    }
  }

  return false;
}

/// Try to look up an existing specialization in the specialization cache.
/// If it is found, it tries to link this specialization.
///
/// For now, it performs a lookup only in the standard library.
/// But in the future, one could think of maintaining a cache
/// of optimized specializations.
static SILFunction *lookupExistingSpecialization(SILModule &M,
                                                 StringRef FunctionName) {
  // Try to link existing specialization only in -Onone mode.
  // All other compilation modes perform specialization themselves.
  // TODO: Cache optimized specializations and perform lookup here?
  // Only check that this function exists, but don't read
  // its body. It can save some compile-time.
  if (isWhitelistedSpecialization(FunctionName))
    return M.hasFunction(FunctionName, SILLinkage::PublicExternal);

  return nullptr;
}

SILFunction *swift::lookupPrespecializedSymbol(SILModule &M,
                                               StringRef FunctionName) {
  // First check if the module contains a required specialization already.
  auto *Specialization = M.lookUpFunction(FunctionName);
  if (Specialization)
    return Specialization;

  // Then check if the required specialization can be found elsewhere.
  Specialization = lookupExistingSpecialization(M, FunctionName);
  if (!Specialization)
    return nullptr;

  assert(hasPublicVisibility(Specialization->getLinkage()) &&
         "Pre-specializations should have public visibility");

  Specialization->setLinkage(SILLinkage::PublicExternal);

  assert(Specialization->isExternalDeclaration()  &&
         "Specialization should be a public external declaration");

  DEBUG(llvm::dbgs() << "Found existing specialization for: " << FunctionName
                     << '\n';
        llvm::dbgs() << swift::Demangle::demangleSymbolAsString(
                            Specialization->getName())
                     << "\n\n");

  return Specialization;
}

