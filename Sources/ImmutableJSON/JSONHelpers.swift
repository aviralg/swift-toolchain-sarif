public import Foundation

extension JSONEncoder.OutputFormatting {
  public static let pretty: JSONEncoder.OutputFormatting = [
    .sortedKeys, .prettyPrinted, .withoutEscapingSlashes,
  ]
  public static let compact: JSONEncoder.OutputFormatting = [
    .sortedKeys, .withoutEscapingSlashes,
  ]
}

private struct EncodingWrapper<Value>: EncodableWithConfiguration {
  let value: Value

  func encode(
    to encoder: any Encoder,
    configuration encode: (_ value: Value, _ encoder: any Encoder) throws ->
      Void
  ) throws {
    try encode(self.value, encoder)
  }
}

private struct DecodingWrapper<Value>: DecodableWithConfiguration {
  let value: Value

  init(
    from decoder: any Decoder,
    configuration decode: (_ decoder: any Decoder) throws -> Value
  )
    throws
  {
    self.value = try decode(decoder)
  }
}

private struct ConfiguredEncodingWrapper<Value: EncodableWithConfiguration>:
  Encodable
{
  let value: Value
  let configuration: Value.EncodingConfiguration

  func encode(to encoder: any Encoder) throws {
    try self.value.encode(to: encoder, configuration: self.configuration)
  }
}

private let decodingConfigurationKey = CodingUserInfoKey(
  rawValue:
    "org.swift.swift-toolchain-sarif.ImmutableJSON.decodingConfiguration"
)!

private final class ConfigurationCarrier<Configuration>: @unchecked Sendable {
  let configuration: Configuration

  init(_ configuration: Configuration) {
    self.configuration = configuration
  }
}

private struct ConfiguredDecodingWrapper<Value: DecodableWithConfiguration>:
  Decodable
{
  let value: Value

  init(from decoder: any Decoder) throws {
    guard
      let carrier = decoder.userInfo[decodingConfigurationKey]
        as? ConfigurationCarrier<Value.DecodingConfiguration>
    else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription:
            "No decoding configuration was provided for \(Value.self)."))
    }

    self.value = try Value(from: decoder, configuration: carrier.configuration)
  }
}

public struct ImmutableJSONEncoder: Sendable {
  private let encoder: JSONEncoder

  public static let pretty = ImmutableJSONEncoder(formatting: .pretty)

  public static let compact = ImmutableJSONEncoder(formatting: .compact)

  public static let defaultDateEncodingStrategy = JSONEncoder
    .DateEncodingStrategy.iso8601

  public init(
    formatting: JSONEncoder.OutputFormatting? = nil,
    dateEncoding: JSONEncoder.DateEncodingStrategy? = nil
  ) {
    self.encoder = JSONEncoder()
    self.encoder.outputFormatting = formatting ?? .pretty
    self.encoder.dateEncodingStrategy =
      dateEncoding ?? Self.defaultDateEncodingStrategy
  }

  public func encode(_ value: some Encodable) throws -> Data {
    try self.encoder.encode(value)
  }

  public func encode<Value: EncodableWithConfiguration>(
    _ value: Value, configuration: Value.EncodingConfiguration
  ) throws -> Data {
    try self.encoder.encode(
      ConfiguredEncodingWrapper(value: value, configuration: configuration))
  }

  public func encode<Value>(
    _ value: Value,
    encode: @escaping (_ value: Value, _ encoder: any Encoder) throws -> Void
  ) throws -> Data {
    try self.encode(EncodingWrapper(value: value), configuration: encode)
  }
}

public struct ImmutableJSONDecoder: Sendable {
  private let decoder: JSONDecoder

  public static let shared = ImmutableJSONDecoder()

  public static let defaultDateDecodingStrategy = JSONDecoder
    .DateDecodingStrategy.iso8601

  public init(dateDecoding: JSONDecoder.DateDecodingStrategy? = nil) {
    self.decoder = Self.makeDecoder(dateDecoding: dateDecoding)
  }

  public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
  {
    try self.decoder.decode(type, from: data)
  }

  public func decode<T: DecodableWithConfiguration>(
    _ type: T.Type, from data: Data, configuration: T.DecodingConfiguration
  ) throws -> T {
    let decoder = self.makeDecoder()
    decoder.userInfo[decodingConfigurationKey] = ConfigurationCarrier(
      configuration)

    return try decoder.decode(ConfiguredDecodingWrapper<T>.self, from: data)
      .value
  }

  public func decode<Value>(
    _ type: Value.Type, from data: Data,
    decode: @escaping (_ decoder: any Decoder) throws -> Value
  ) throws -> Value {
    try self.decode(
      DecodingWrapper<Value>.self, from: data, configuration: decode
    ).value
  }

  public func makeDecoder() -> JSONDecoder {
    Self.makeDecoder(dateDecoding: self.decoder.dateDecodingStrategy)
  }

  private static func makeDecoder(
    dateDecoding: JSONDecoder.DateDecodingStrategy?
  ) -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy =
      dateDecoding ?? Self.defaultDateDecodingStrategy
    return decoder
  }
}

extension Encodable {
  public func toJSONData(formatting: JSONEncoder.OutputFormatting? = nil) throws
    -> Data
  {
    let encoder = ImmutableJSONEncoder(formatting: formatting)

    return try encoder.encode(self)
  }

  public func toJSONString(formatting: JSONEncoder.OutputFormatting? = nil)
    throws -> String
  {
    String(data: try toJSONData(formatting: formatting), encoding: .utf8)!
  }
}

extension Decodable {
  public static func fromJSONString(_ string: String) throws -> Self {
    try fromJSONData(string.data(using: .utf8)!)
  }

  public static func fromJSONData(_ data: Data) throws -> Self {
    try ImmutableJSONDecoder.shared.decode(Self.self, from: data)
  }
}

extension DecodableWithConfiguration {
  public static func fromJSONData(
    _ data: Data, configuration: DecodingConfiguration
  ) throws -> Self {
    try ImmutableJSONDecoder.shared.decode(
      Self.self, from: data, configuration: configuration)
  }
}
