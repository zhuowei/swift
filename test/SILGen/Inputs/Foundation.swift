// Fake Foundation module for testing bridging.

@_exported import ObjectiveC
@_exported import Foundation // clang module

@_silgen_name("swift_StringToNSString")
func _convertStringToNSString(string: String) -> NSString

@_silgen_name("swift_NSStringToString")
func _convertNSStringToString(nsstring: NSString?) -> String

// NSArray bridging entry points
func _convertNSArrayToArray<T>(nsarr: NSArray?) -> [T] {
  return [T]()
}

func _convertArrayToNSArray<T>(arr: [T]) -> NSArray {
  return NSArray()
}

// NSDictionary bridging entry points
func _convertDictionaryToNSDictionary<Key, Value>(
    d: Dictionary<Key, Value>
) -> NSDictionary {
  return NSDictionary()
}

func _convertNSDictionaryToDictionary<K: NSObject, V: AnyObject>(
       d: NSDictionary?
     ) -> Dictionary<K, V> {
  return Dictionary<K, V>()
}

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

extension Int : _ObjectiveCBridgeable {
  public static func _isBridgedToObjectiveC() -> Bool {
    return true
  }
  
  public func _bridgeToObjectiveC() -> NSNumber {
    return NSNumber()
  }
  public static func _forceBridgeFromObjectiveC(
    x: NSNumber,
    result: inout Int?
  ) {
  }
  public static func _conditionallyBridgeFromObjectiveC(
    x: NSNumber,
    result: inout Int?
  ) -> Bool {
    return true
  }
  public static func _unconditionallyBridgeFromObjectiveC(
    x: NSNumber?
  ) -> Int {
    return 0
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

extension NSObject : Hashable {
  public var hashValue: Int { return 0 }
}

public func == (x: NSObject, y: NSObject) -> Bool { return true }

extension NSError : ErrorProtocol {
  public var _domain: String { return domain }
  public var _code: Int { return code }
}

