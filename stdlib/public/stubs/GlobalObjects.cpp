//===--- GlobalObjects.cpp - Statically-initialized objects ---------------===//
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
//
//  Objects that are allocated at global scope instead of on the heap,
//  and statically initialized to avoid synchronization costs, are
//  defined here.
//
//===----------------------------------------------------------------------===//
#include "../SwiftShims/GlobalObjects.h"
#include "swift/Runtime/Metadata.h"

namespace swift {

// _direct type metadata for Swift._EmptyArrayStorage
SWIFT_RUNTIME_STDLIB_INTERFACE
extern "C" ClassMetadata _TMCs18_EmptyArrayStorage;

SWIFT_RUNTIME_STDLIB_INTERFACE
extern "C" _SwiftEmptyArrayStorage _swiftEmptyArrayStorage = {
  // HeapObject header;
  {
    &_TMCs18_EmptyArrayStorage, // isa pointer
  },
  
  // _SwiftArrayBodyStorage body;
  {
    0, // int count;                                    
    1  // unsigned int _capacityAndFlags; 1 means elementTypeIsBridgedVerbatim
  }
};

SWIFT_RUNTIME_STDLIB_INTERFACE
extern "C"
__swift_uint64_t _swift_stdlib_HashingDetail_fixedSeedOverride = 0;

/// Backing storage for Swift.Process.arguments.
SWIFT_RUNTIME_STDLIB_INTERFACE
extern "C"
void *_swift_stdlib_ProcessArguments = nullptr;

}

namespace llvm { namespace hashing { namespace detail {
  // An extern variable expected by LLVM's hashing templates. We don't link any
  // LLVM libs into the runtime, so define this here.
  size_t fixed_seed_override = 0;
} } }

