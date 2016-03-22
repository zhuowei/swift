@_exported import Appliances

public struct Refrigerator {
  public var temperature: Double
}

extension Refrigerator : _ObjectiveCBridgeable {
  public typealias _ObjectiveCType = APPRefrigerator

  public static func _isBridgedToObjectiveC() -> Bool { return true }

  public func _bridgeToObjectiveC() -> _ObjectiveCType {
    return APPRefrigerator(temperature: temperature)
  }

  public static func _forceBridgeFromObjectiveC(
    source: _ObjectiveCType,
    result: inout Refrigerator?
  ) {
    result = Refrigerator(temperature: source.temperature)
  }

  public static func _conditionallyBridgeFromObjectiveC(
    source: _ObjectiveCType,
    result: inout Refrigerator?
  ) -> Bool {
    result = Refrigerator(temperature: source.temperature)
    return true
  }

  public static func _unconditionallyBridgeFromObjectiveC(source: _ObjectiveCType?)
      -> Refrigerator {
    return Refrigerator(temperature: source!.temperature)
  }
}
