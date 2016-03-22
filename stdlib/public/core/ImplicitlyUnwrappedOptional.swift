//===----------------------------------------------------------------------===//
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

/// An optional type that allows implicit member access.
public enum ImplicitlyUnwrappedOptional<Wrapped> : NilLiteralConvertible {
  // The compiler has special knowledge of the existence of
  // `ImplicitlyUnwrappedOptional<Wrapped>`, but always interacts with it using
  // the library intrinsics below.
  
  case none
  case some(Wrapped)

  /// Construct a non-`nil` instance that stores `some`.
  public init(_ some: Wrapped) { self = .some(some) }

  /// Create an instance initialized with `nil`.
  @_transparent
  public init(nilLiteral: ()) {
    self = .none
  }
}

extension ImplicitlyUnwrappedOptional : CustomStringConvertible {
  /// A textual representation of `self`.
  public var description: String {
    switch self {
    case .some(let value):
      return String(value)
    case .none:
      return "nil"
    }
  }
}

/// Directly conform to CustomDebugStringConvertible to support
/// optional printing. Implementation of that feature relies on
/// _isOptional thus cannot distinguish ImplicitlyUnwrappedOptional
/// from Optional. When conditional conformance is available, this
/// outright conformance can be removed.
extension ImplicitlyUnwrappedOptional : CustomDebugStringConvertible {
  public var debugDescription: String {
    return description
  }
}

@_transparent
@warn_unused_result
public // COMPILER_INTRINSIC
func _stdlib_ImplicitlyUnwrappedOptional_isSome<Wrapped>
  (`self`: Wrapped!) -> Bool {

  return `self` != nil
}

@_transparent
@warn_unused_result
public // COMPILER_INTRINSIC
func _stdlib_ImplicitlyUnwrappedOptional_unwrapped<Wrapped>
  (`self`: Wrapped!) -> Wrapped {

  switch `self` {
  case .some(let wrapped):
    return wrapped
  case .none:
    _preconditionFailure(
      "unexpectedly found nil while unwrapping an Optional value")
  }
}

#if _runtime(_ObjC)
extension ImplicitlyUnwrappedOptional : _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> AnyObject {
    switch self {
    case .none:
      _preconditionFailure("attempt to bridge an implicitly unwrapped optional containing nil")

    case .some(let x):
      return Swift._bridgeToObjectiveC(x)!
    }
  }

  public static func _forceBridgeFromObjectiveC(
    x: AnyObject,
    result: inout Wrapped!?
  ) {
    result = Swift._forceBridgeFromObjectiveC(x, Wrapped.self)
  }

  public static func _conditionallyBridgeFromObjectiveC(
    x: AnyObject,
    result: inout Wrapped!?
  ) -> Bool {
    let bridged: Wrapped? =
      Swift._conditionallyBridgeFromObjectiveC(x, Wrapped.self)
    if let value = bridged {
      result = value
    }

    return false
  }

  public static func _isBridgedToObjectiveC() -> Bool {
    return Swift._isBridgedToObjectiveC(Wrapped.self)
  }
}
#endif

extension ImplicitlyUnwrappedOptional {
  @available(*, unavailable, message: "Please use nil literal instead.")
  public init() {
    fatalError("unavailable function can't be called")
  }

  @available(*, unavailable, message: "Has been removed in Swift 3.")
  public func map<U>(
    @noescape f: (Wrapped) throws -> U
  ) rethrows -> ImplicitlyUnwrappedOptional<U> {
    fatalError("unavailable function can't be called")
  }

  @available(*, unavailable, message: "Has been removed in Swift 3.")
  public func flatMap<U>(
      @noescape f: (Wrapped) throws -> ImplicitlyUnwrappedOptional<U>
  ) rethrows -> ImplicitlyUnwrappedOptional<U> {
    fatalError("unavailable function can't be called")
  }
}
