// This is an overlay Swift module.
@_exported import Foundation

@_exported import ObjectiveC

// String/NSString bridging functions.
@_silgen_name("swift_StringToNSString") internal
func _convertStringToNSString(string: String) -> NSString

@_silgen_name("swift_NSStringToString") internal
func _convertNSStringToString(nsstring: NSString?) -> String

@_silgen_name("swift_ArrayToNSArray") internal
func _convertArrayToNSArray<T>(array: Array<T>) -> NSArray

@_silgen_name("swift_NSArrayToArray") internal
func _convertNSArrayToArray<T>(nsstring: NSArray?) -> Array<T>

@_silgen_name("swift_DictionaryToNSDictionary") internal
func _convertDictionaryToNSDictionary<K: Hashable, V>(array: Dictionary<K, V>) -> NSDictionary

@_silgen_name("swift_NSDictionaryToDictionary") internal
func _convertNSDictionaryToDictionary<K: Hashable, V>(nsstring: NSDictionary?) -> Dictionary<K, V>

// NSSet bridging entry points
func _convertSetToNSSet<T: Hashable>(s: Set<T>) -> NSSet {
  return NSSet()
}

func _convertNSSetToSet<T: NSObject>(s: NSSet?) -> Set<T> {
  return Set<T>()
}

extension String : _ObjectiveCBridgeable {
  public static func _isBridgedToObjectiveC() -> Bool {
    return true
  }

  public func _bridgeToObjectiveC() -> NSString {
    return NSString()
  }
  public static func _forceBridgeFromObjectiveC(
    x: NSString,
    result: inout String?
  ) {
  }
  public static func _conditionallyBridgeFromObjectiveC(
    x: NSString,
    result: inout String?
  ) -> Bool {
    return true
  }
  public static func _unconditionallyBridgeFromObjectiveC(
    x: NSString?
  ) -> String {
    return String()
  }
}

extension Array : _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSArray {
    return NSArray()
  }
  public static func _forceBridgeFromObjectiveC(
    x: NSArray,
    result: inout Array?
  ) {
  }
  public static func _conditionallyBridgeFromObjectiveC(
    x: NSArray,
    result: inout Array?
  ) -> Bool {
    return true
  }
  public static func _unconditionallyBridgeFromObjectiveC(
    x: NSArray?
  ) -> Array {
    return Array()
  }
  public static func _isBridgedToObjectiveC() -> Bool {
    return Swift._isBridgedToObjectiveC(Element.self)
  }
}

extension Dictionary : _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSDictionary {
    return NSDictionary()
  }
  public static func _forceBridgeFromObjectiveC(
    x: NSDictionary,
  result: inout Dictionary?
  ) {
  }
  public static func _conditionallyBridgeFromObjectiveC(
    x: NSDictionary,
    result: inout Dictionary?
  ) -> Bool {
    return true
  }
  public static func _unconditionallyBridgeFromObjectiveC(
    x: NSDictionary?
  ) -> Dictionary {
    return Dictionary()
  }
  public static func _isBridgedToObjectiveC() -> Bool {
    return Swift._isBridgedToObjectiveC(Key.self) && Swift._isBridgedToObjectiveC(Value.self)
  }
}

extension Set : _ObjectiveCBridgeable {
  public func _bridgeToObjectiveC() -> NSSet {
    return NSSet()
  }
  public static func _forceBridgeFromObjectiveC(
    x: NSSet,
    result: inout Set?
  ) {
  }
  public static func _conditionallyBridgeFromObjectiveC(
    x: NSSet,
    result: inout Set?
  ) -> Bool {
    return true
  }
  public static func _unconditionallyBridgeFromObjectiveC(
    x: NSSet?
  ) -> Set {
    return Set()
  }
  public static func _isBridgedToObjectiveC() -> Bool {
    return Swift._isBridgedToObjectiveC(Element.self)
  }
}

extension NSError: ErrorProtocol {
  public var _domain: String { return domain }
  public var _code: Int { return code }
}

public func _convertErrorProtocolToNSError(x: ErrorProtocol) -> NSError {
  return x as NSError
}
