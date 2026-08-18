/// An ID used to match references of a specific record type to their corresponding definition.
/// Wraps an underlying value (usually an integer or a string), but ensures that different types
/// of IDs aren't mixed.
///
/// The `TypedID` is encoded and decoded as the underlying value in JSON.
public protocol TypedID: Hashable, Comparable, SARIFRecordConstraints {
  associatedtype Value: Hashable, Comparable, Codable

  init(value: Value)

  var value: Value { get }
}

extension TypedID {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.init(value: try container.decode(Value.self))
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.value)
  }

  public func hash(into hasher: inout Hasher) {
    self.value.hash(into: &hasher)
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.value < rhs.value
  }
}
