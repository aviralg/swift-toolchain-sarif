public import OrderedCollections

public protocol DefaultValueProvider<Value> {
  associatedtype Value

  static var defaultValue: Value { get }

  static func isDefault(_ value: Value) -> Bool
}

extension DefaultValueProvider where Value: Equatable {
  public static func isDefault(_ value: Value) -> Bool {
    value == Self.defaultValue
  }
}

public struct DefaultTrue: DefaultValueProvider {
  public static let defaultValue = true
}

public struct DefaultFalse: DefaultValueProvider {
  public static let defaultValue = false
}

public struct DefaultEmptyOrderedDictionary<Key: Hashable, Value>:
  DefaultValueProvider
{
  public static var defaultValue: OrderedDictionary<Key, Value> { .init() }

  public static func isDefault(_ value: OrderedDictionary<Key, Value>) -> Bool {
    value.isEmpty
  }
}

public struct DefaultEmptyOrderedSet<Element: Hashable>: DefaultValueProvider {
  public static var defaultValue: OrderedSet<Element> { .init() }

  public static func isDefault(_ value: Value) -> Bool {
    value.isEmpty
  }
}

@propertyWrapper
public struct WithDefaultValue<Default: DefaultValueProvider> {
  public typealias Value = Default.Value

  private var specifiedValue: Value? = nil

  public init(_ value: Value? = nil) {
    self.specifiedValue = value
  }

  public var wrappedValue: Value {
    get { specifiedValue ?? Default.defaultValue }
    set { self.specifiedValue = Default.isDefault(newValue) ? nil : newValue }
  }

  public var projectedValue: Value? {
    get { specifiedValue }
    set { specifiedValue = newValue }
  }
}
