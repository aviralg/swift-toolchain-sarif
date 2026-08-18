internal final class KeyEncoder<K: CodingKey>: Encoder,
  SingleValueEncodingContainer
{
  private let container: KeyedEncodingContainer<K>
  let userInfo: [CodingUserInfoKey: Any]
  var codingPath: [any CodingKey] { container.codingPath }
  var key: K?

  init(
    in container: KeyedEncodingContainer<K>, userInfo: [CodingUserInfoKey: Any]
  ) {
    self.container = container
    self.userInfo = userInfo
  }

  func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key>
  where Key: CodingKey {
    preconditionFailure(
      "Attempted to encode key as a dictionary, but only '\(String.self)' is supported."
    )
  }

  func unkeyedContainer() -> any UnkeyedEncodingContainer {
    preconditionFailure(
      "Attempted to encode key as an array, but only '\(String.self)' is supported."
    )
  }

  func singleValueContainer() -> any SingleValueEncodingContainer {
    self
  }

  func encode<T>(_ value: T) throws where T: Encodable {
    badKeyEncoding()
  }

  func encode(_ value: UInt64) throws {
    badKeyEncoding()
  }

  func encode(_ value: UInt32) throws {
    badKeyEncoding()
  }

  func encode(_ value: UInt16) throws {
    badKeyEncoding()
  }

  func encode(_ value: UInt8) throws {
    badKeyEncoding()
  }

  func encode(_ value: UInt) throws {
    badKeyEncoding()
  }

  func encode(_ value: Int64) throws {
    badKeyEncoding()
  }

  func encode(_ value: Int32) throws {
    badKeyEncoding()
  }

  func encode(_ value: Int16) throws {
    badKeyEncoding()
  }

  func encode(_ value: Int8) throws {
    badKeyEncoding()
  }

  func encode(_ value: Int) throws {
    badKeyEncoding()
  }

  func encode(_ value: Float) throws {
    badKeyEncoding()
  }

  func encode(_ value: Double) throws {
    badKeyEncoding()
  }

  func encode(_ value: String) throws {
    self.key = K(stringValue: value)
  }

  func encode(_ value: Bool) throws {
    badKeyEncoding()
  }

  func encodeNil() throws {
    badKeyEncoding()
  }

  private func badKeyEncoding() -> Never {
    preconditionFailure("A key can only be encoded as a string.")
  }
}

internal struct KeyDecoder<K: CodingKey>: Decoder, SingleValueDecodingContainer
{
  private let key: K
  private let container: KeyedDecodingContainer<K>
  public let userInfo: [CodingUserInfoKey: Any]
  var codingPath: [any CodingKey] {
    var path = container.codingPath
    path.append(key)
    return path
  }

  internal init(
    forKey key: K, in container: KeyedDecodingContainer<K>,
    userInfo: [CodingUserInfoKey: Any]
  ) {
    self.key = key
    self.container = container
    self.userInfo = userInfo
  }

  func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<
    Key
  >
  where Key: CodingKey {
    try typeMismatch(type: type)  // REVIEW: Which type?
  }

  func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
    try typeMismatch(type: [Any].self)  // REVIEW: Which type?
  }

  func singleValueContainer() throws -> any SingleValueDecodingContainer {
    self
  }

  func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
    try T(from: self)
  }

  func decode(_ type: UInt64.Type) throws -> UInt64 {
    try typeMismatch(type: type)
  }

  func decode(_ type: UInt32.Type) throws -> UInt32 {
    try typeMismatch(type: type)
  }

  func decode(_ type: UInt16.Type) throws -> UInt16 {
    try typeMismatch(type: type)
  }

  func decode(_ type: UInt8.Type) throws -> UInt8 {
    try typeMismatch(type: type)
  }

  func decode(_ type: UInt.Type) throws -> UInt {
    try typeMismatch(type: type)
  }

  func decode(_ type: Int64.Type) throws -> Int64 {
    try typeMismatch(type: type)
  }

  func decode(_ type: Int32.Type) throws -> Int32 {
    try typeMismatch(type: type)
  }

  func decode(_ type: Int16.Type) throws -> Int16 {
    try typeMismatch(type: type)
  }

  func decode(_ type: Int8.Type) throws -> Int8 {
    try typeMismatch(type: type)
  }

  func decode(_ type: Int.Type) throws -> Int {
    try typeMismatch(type: type)
  }

  func decode(_ type: Float.Type) throws -> Float {
    try typeMismatch(type: type)
  }

  func decode(_ type: Double.Type) throws -> Double {
    try typeMismatch(type: type)
  }

  func decode(_ type: String.Type) throws -> String {
    self.key.stringValue
  }

  func decode(_ type: Bool.Type) throws -> Bool {
    try typeMismatch(type: type)
  }

  func decodeNil() -> Bool {
    false
  }

  private func typeMismatch(type: Any.Type) throws -> Never {
    throw DecodingError.typeMismatch(
      Bool.self,
      DecodingError.Context(
        codingPath: codingPath,
        debugDescription:
          "Attempt to decode key of type '\(type)', but only '\(String.self)' is supported."
      ))
  }
}
